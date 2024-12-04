import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:win32/win32.dart';
import 'package:flutter/material.dart';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


@Packed(1) // Ensure correct memory alignment
base class MIB_IFROW extends Struct {
  @Array(256) // MAX_INTERFACE_NAME_LEN (assumed to be 256)
  external Array<Uint16> wszName; // Interface name (WCHAR)
  @Uint32()
  external int dwIndex; // Interface index (IF_INDEX)
  @Uint32()
  external int dwType; // Interface type (IFTYP)
  @Uint32()
  external int dwMtu; // Maximum Transmission Unit
  @Uint32()
  external int dwSpeed; // Interface speed
  @Uint32()
  external int dwPhysAddrLen; // Physical address length
  @Array(8) // MAXLEN_PHYSADDR (assumed to be 8)
  external Array<Uint8> bPhysAddr; // Physical address (MAC)
  @Uint32()
  external int dwAdminStatus; // Administrative status
  @Uint32()
  external int dwOperStatus; // Operational status
  @Uint32()
  external int dwLastChange; // Time since last change
  @Uint32()
  external int dwInOctets; // Bytes received
  @Uint32()
  external int dwInUcastPkts; // Unicast packets received
  @Uint32()
  external int dwInNUcastPkts; // Non-unicast packets received
  @Uint32()
  external int dwInDiscards; // Incoming packets discarded
  @Uint32()
  external int dwInErrors; // Incoming packets with errors
  @Uint32()
  external int dwInUnknownProtos; // Incoming packets with unknown protocols
  @Uint32()
  external int dwOutOctets; // Bytes sent
  @Uint32()
  external int dwOutUcastPkts; // Unicast packets sent
  @Uint32()
  external int dwOutNUcastPkts; // Non-unicast packets sent
  @Uint32()
  external int dwOutDiscards; // Outgoing packets discarded
  @Uint32()
  external int dwOutErrors; // Outgoing packets with errors
  @Uint32()
  external int dwOutQLen; // Output queue length
  @Uint32()
  external int dwDescrLen; // Length of the interface description
  @Array(256) // MAXLEN_IFDESCR (assumed to be 256)
  external Array<Uint8> bDescr; // Interface description
}


// Define the MIB_IFTABLE structure
base class MIB_IFTABLE extends Struct {
  @Uint32()
  external int dwNumEntries;
  @Array(1)
  external Array<MIB_IFROW> table; // Variable length array of MIB_IFROW
}

class WindowInitializer{
  String networkUsage = "Fetching network usage...";
  final Map<String, Map<String, int>> previousUsage = {}; // Store previous state for deltas

  final _secureStorage = const FlutterSecureStorage();

  // 파워쉘로 예약하기
  String getAppLocation() {
    final appPath = Platform.resolvedExecutable; // Full path to the executable
    final appDirectory = Directory(appPath).parent.path; // Directory of the executable
    // print('App executable path: $appPath');
    // print('App directory: $appDirectory');
    return appPath;
  }

  // 시간 등록
  Future<void> createHourlyTask() async {
    final exePath = getAppLocation(); // Dynamically get the app location
    const taskName = 'MyFlutterAppTask';

    // 디버깅 용 1분마다 알림이 울림
    //   final now = DateTime.now();
    //   final startTime = now.add(Duration(minutes: 1));
    //   final formattedTime = startTime.toLocal().toIso8601String().split('T')[1].substring(0, 5); // HH:mm format
    //   final script = '''
    // schtasks /create /tn "$taskName" /tr "$exePath" /sc once /st $formattedTime /f
    // ''';

    final script = '''
schtasks /create /tn "$taskName" /tr "$exePath" /sc hourly /st 00:00 /f
''';

    print(script);

    try {
      final result = await Process.run(
        'powershell',
        ['-Command', script],
      );

      if (result.exitCode == 0) {
        print('Task created successfully: $taskName');
      } else {
        print('Failed to create task: ${result.stderr}');
      }
    } catch (e) {
      print('Error creating task: $e');
    }
  }

  Future<void> initializeApp() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if this is the first launch
    final isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;

    // Get the last synced timestamp
    final lastSyncTimestamp = prefs.getString('lastSyncTimestamp');
    final now = DateTime.now();
    final currentDateTime = now.toIso8601String();

    await updateDailyUsage(); // Ensure daily usage is updated
    await updateHourlyUsage(); // Ensure hourly usage is updated

    // 나중에 바꾸자
    bool needsSync = false;

    if (isFirstLaunch) {
      print("첫 실행");
      needsSync = true;
    } else if (lastSyncTimestamp != null) {
      final lastSyncTime = DateTime.parse(lastSyncTimestamp);
      final durationSinceLastSync = now.difference(lastSyncTime);

      if (durationSinceLastSync.inHours >= 1 || now.day != lastSyncTime.day) {
        print("날이 바뀌었을 때");
        needsSync = true;
      }
    } else {
      // No previous sync information, assume sync is needed
      print("lastSynctimestap 값이 없을 때");
      needsSync = true;
    }

    if (needsSync) {
      final weeklyData = await getWeeklyUsage();
      final hourlyData = await getHourlyUsage();

      String accessToken = (await _secureStorage.read(key: 'accessToken')) ?? '';
      String userId = (await _secureStorage.read(key: 'userId')) ?? '';
      String deviceId = (await _secureStorage.read(key: 'deviceId')) ?? '';

      await handleBackendSync(
        dailyUsageData: weeklyData,
        hourlyUsageData: hourlyData,
        deviceId: deviceId,
        userId: userId,
        accessToken: accessToken,
      );

      // Update the last sync timestamp
      prefs.setString('lastSyncTimestamp', currentDateTime);
    }

    // Mark first launch as completed
    prefs.setBool('isFirstLaunch', false);

    scheduleMidnightUpdate(); // Schedule the next midnight update
    scheduleHourlyUpdate(); // Schedule hourly updates

    createHourlyTask(); // Create the task for future executions
  }

  // Helper function to handle counter resets
  int calculateDailyDelta({required int currentValue, required int previousValue}) {
    if (currentValue >= previousValue) {
      return currentValue - previousValue;
    } else {
      return currentValue;
    }
  }

  Future<void> saveDebugOutput(Map<String, int> currentTotals) async {
    try {
      // Retrieve SharedPreferences instance
      final prefs = await SharedPreferences.getInstance();

      // Gather all preference keys and values
      final Map<String, dynamic> allPreferences = {
        "weeklyDataUsage": prefs.getString('weeklyDataUsage') ?? '{}',
        "hourlyDataUsage": prefs.getString('hourlyDataUsage') ?? '{}',
        "lastSavedTotals": prefs.getString('lastSavedTotals') ?? '{}',
      };

      // Prepare file to save debug output
      final directory = Directory.current; // Use app-specific directory in production
      final filePath = '${directory.path}/debug_output.txt';

      // Format data to save
      final timestamp = DateTime.now().toIso8601String();
      final debugData = {
        "timestamp": timestamp,
        "preferences": allPreferences,
        "currentTotals": currentTotals
      };

      // Append data to the file
      final file = File(filePath);
      await file.writeAsString('${jsonEncode(debugData)}\n', mode: FileMode.append);

      print('Debug output saved to $filePath');
    } catch (e) {
      print('Error saving debug output: $e');
    }
  }

  Future<void> updateDailyUsage() async {
    final prefs = await SharedPreferences.getInstance();

    // Load saved data
    final lastSavedJson = prefs.getString('lastSavedTotals') ?? '{}';
    final weeklyDataJson = prefs.getString('weeklyDataUsage') ?? '{}';
    final lastSavedData = Map<String, dynamic>.from(json.decode(lastSavedJson));
    final weeklyData = Map<String, Map<String, int>>.from(
        json.decode(weeklyDataJson).map((k, v) => MapEntry(k, Map<String, int>.from(v))));

    final today = DateTime.now().toIso8601String().split('T')[0];
    final currentTotals = await fetchCurrentUsage();
    await saveDebugOutput(currentTotals);

    // Case 1: First launch or no saved totals
    if (lastSavedData.isEmpty) {
      prefs.setString('lastSavedTotals', json.encode({'date': today, 'totals': currentTotals}));
      await saveDailyUsage(today, {'inOctets': 0, 'outOctets': 0});
      return;
    }

    // Load previous totals and date
    final lastSavedDate = lastSavedData['date'] ?? '';
    final lastTotals = Map<String, int>.from(lastSavedData['totals'] ?? {});

    // Case 2: If the date has changed, calculate usage for the previous day(s)
    if (lastSavedDate != today) {
      DateTime lastDate = DateTime.parse(lastSavedDate);
      while (lastDate.isBefore(DateTime.now())) {
        final missedDate = lastDate.toIso8601String().split('T')[0];

        if (missedDate == lastSavedDate) {
          // Calculate usage for the last active day
          final dailyUsage = {
            'inOctets': calculateDailyDelta(
              currentValue: currentTotals['ethernetInOctets'] ?? 0,
              previousValue: lastTotals['ethernetInOctets'] ?? 0,
            ) + calculateDailyDelta(
              currentValue: currentTotals['wifiInOctets'] ?? 0,
              previousValue: lastTotals['wifiInOctets'] ?? 0,
            ),
            'outOctets': calculateDailyDelta(
              currentValue: currentTotals['ethernetOutOctets'] ?? 0,
              previousValue: lastTotals['ethernetOutOctets'] ?? 0,
            ) + calculateDailyDelta(
              currentValue: currentTotals['wifiOutOctets'] ?? 0,
              previousValue: lastTotals['wifiOutOctets'] ?? 0,
            ),
          };

          weeklyData[missedDate] = dailyUsage;
        } else {
          // Fill missing days with 0 usage
          weeklyData[missedDate] = {'inOctets': 0, 'outOctets': 0};
        }

        lastDate = lastDate.add(const Duration(days: 1));
      }

      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      weeklyData.removeWhere((key, _) => DateTime.parse(key).isBefore(sevenDaysAgo));

      prefs.setString('lastSavedTotals', json.encode({'date': today, 'totals': currentTotals}));
      // Save updated weekly data
      prefs.setString('weeklyDataUsage', json.encode(weeklyData));
      return;
    }

    // Case 3: Calculate real-time usage for today
    final realTimeUsage = {
      'inOctets': calculateDailyDelta(
        currentValue: currentTotals['ethernetInOctets'] ?? 0,
        previousValue: lastTotals['ethernetInOctets'] ?? 0,
      ) + calculateDailyDelta(
        currentValue: currentTotals['wifiInOctets'] ?? 0,
        previousValue: lastTotals['wifiInOctets'] ?? 0,
      ),
      'outOctets': calculateDailyDelta(
        currentValue: currentTotals['ethernetOutOctets'] ?? 0,
        previousValue: lastTotals['ethernetOutOctets'] ?? 0,
      ) + calculateDailyDelta(
        currentValue: currentTotals['wifiOutOctets'] ?? 0,
        previousValue: lastTotals['wifiOutOctets'] ?? 0,
      ),
    };
    await saveDailyUsage(today, realTimeUsage);
  }


  Future<void> saveDailyUsage(String date, Map<String, int> usage) async {
    final prefs = await SharedPreferences.getInstance();
    final weeklyDataJson = prefs.getString('weeklyDataUsage') ?? '{}';

    final weeklyData = Map<String, Map<String, int>>.from(
        json.decode(weeklyDataJson).map((k, v) => MapEntry(k, Map<String, int>.from(v))));

    weeklyData[date] = usage;

    // Keep only the last 7 days
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    weeklyData.removeWhere((key, _) => DateTime.parse(key).isBefore(sevenDaysAgo));

    prefs.setString('weeklyDataUsage', json.encode(weeklyData));
  }

  Future<void> updateHourlyUsage() async {
    final prefs = await SharedPreferences.getInstance();

    // Load weekly data and hourly data
    final weeklyDataJson = prefs.getString('weeklyDataUsage') ?? '{}';
    final hourlyDataJson = prefs.getString('hourlyDataUsage') ?? '{}';

    // Parse the data
    final weeklyData = Map<String, Map<String, int>>.from(
        json.decode(weeklyDataJson).map((k, v) => MapEntry(k, Map<String, int>.from(v))));
    final hourlyData = Map<String, Map<String, int>>.from(
        json.decode(hourlyDataJson).map((k, v) => MapEntry(k, Map<String, int>.from(v))));

    final now = DateTime.now();
    final currentDate = now.toIso8601String().split('T')[0];
    final currentHour = now.hour;
    final hourKey = '$currentDate-${currentHour.toString().padLeft(2, '0')}';

    // Fetch current totals from weekly data
    final currentTotals = weeklyData[currentDate] ?? {'inOctets': 0, 'outOctets': 0};

    hourlyData.removeWhere((key, _) {
      final keyDate = key.split('-').sublist(0, 3).join('-'); // Extract YYYY-MM-DD
      return DateTime.parse(keyDate).isBefore(DateTime.parse(currentDate));
    });

    // Update hourly data for the current hour
    hourlyData[hourKey] = {
      'inOctets': currentTotals['inOctets'] ?? 0,
      'outOctets': currentTotals['outOctets'] ?? 0,
    };

    // Save the updated hourly data
    prefs.setString('hourlyDataUsage', json.encode(hourlyData));

    print("Updated hourly usage for $hourKey: ${hourlyData[hourKey]}");
  }


  // weeklyUsage 값 가져오기
  Future<Map<String, Map<String, double>>> getWeeklyUsage() async {
    final prefs = await SharedPreferences.getInstance();
    final weeklyDataJson = prefs.getString('weeklyDataUsage') ?? '{}';

    // Deserialize JSON and safely cast types
    final Map<String, dynamic> rawData = json.decode(weeklyDataJson);
    final Map<String, Map<String, double>> weeklyData = {};

    rawData.forEach((key, value) {
      final usage = Map<String, int>.from(value as Map);
      weeklyData[key] = usage.map((innerKey, innerValue) => MapEntry(innerKey, innerValue.toDouble()));
    });

    return weeklyData;
  }

  Future<List<Map<String, Object>>> getHourlyUsage() async {
    final prefs = await SharedPreferences.getInstance();
    final hourlyDataJson = prefs.getString('hourlyDataUsage') ?? '{}';

    // Decode the stored data, assuming it's a map
    final Map<String, dynamic> rawData = json.decode(hourlyDataJson);

    // Process the data into a List<Map<String, Object>>
    return rawData.entries.map((entry) {
      final hourData = entry.value as Map<String, dynamic>;

      return {
        'hourKey': entry.key, // Keep hourKey as a String
        'inOctets': (hourData['inOctets'] as num?)?.toDouble() ?? 0.0, // Safely convert to double
        'outOctets': (hourData['outOctets'] as num?)?.toDouble() ?? 0.0, // Safely convert to double
      };
    }).toList();
  }


  Future<Map<String, int>> fetchCurrentUsage() async {
    final dwSize = calloc<Uint32>();
    final GetIfTable = DynamicLibrary.open('iphlpapi.dll').lookupFunction<
        Int32 Function(Pointer<MIB_IFTABLE>, Pointer<Uint32>, Int32),
        int Function(Pointer<MIB_IFTABLE>, Pointer<Uint32>, int)>('GetIfTable');
    int result = GetIfTable(nullptr, dwSize, 0);

    if (result == ERROR_INSUFFICIENT_BUFFER) {
      final pIfTable = calloc<Uint8>(dwSize.value);

      try {
        result = GetIfTable(pIfTable.cast(), dwSize, 0);
        if (result == NO_ERROR) {
          final pIfTableStruct = pIfTable.cast<MIB_IFTABLE>();
          final numEntries = pIfTableStruct.ref.dwNumEntries;

          // Track data usage per MAC address
          final Map<String, Map<String, int>> ethernetUsage = {};
          final Map<String, Map<String, int>> wifiUsage = {};

          for (var i = 0; i < numEntries; i++) {
            final ifacePtr = Pointer<MIB_IFROW>.fromAddress(
                pIfTableStruct.address +
                    sizeOf<MIB_IFTABLE>() +
                    i * sizeOf<MIB_IFROW>());
            final iface = ifacePtr.ref;

            // Extract MAC address as a unique identifier
            final macAddress = List.generate(iface.dwPhysAddrLen, (j) {
              return iface.bPhysAddr[j].toRadixString(16).padLeft(2, '0');
            }).join(':');

            // Filter and aggregate data by type
            if (iface.dwType == 6) { // Ethernet
              ethernetUsage[macAddress] = {
                'inOctets': iface.dwInOctets,
                'outOctets': iface.dwOutOctets,
              };
            } else if (iface.dwType == 71) { // Wi-Fi
              wifiUsage[macAddress] = {
                'inOctets': iface.dwInOctets,
                'outOctets': iface.dwOutOctets,
              };
            }
          }

          // Aggregate totals for Ethernet and Wi-Fi
          int totalEthernetIn = 0, totalEthernetOut = 0;
          int totalWifiIn = 0, totalWifiOut = 0;

          ethernetUsage.forEach((_, usage) {
            totalEthernetIn += usage['inOctets'] ?? 0;
            totalEthernetOut += usage['outOctets'] ?? 0;
          });

          wifiUsage.forEach((_, usage) {
            totalWifiIn += usage['inOctets'] ?? 0;
            totalWifiOut += usage['outOctets'] ?? 0;
          });

          // Return summarized totals
          return {
            'ethernetInOctets': totalEthernetIn,
            'ethernetOutOctets': totalEthernetOut,
            'wifiInOctets': totalWifiIn,
            'wifiOutOctets': totalWifiOut,
          };
        }
      } finally {
        calloc.free(pIfTable);
      }
    }

    // Return zeros in case of failure
    return {
      'ethernetInOctets': 0,
      'ethernetOutOctets': 0,
      'wifiInOctets': 0,
      'wifiOutOctets': 0,
    };
  }


  void scheduleMidnightUpdate() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final durationUntilMidnight = midnight.difference(now);

    Timer(durationUntilMidnight, () async {
      print("success Midnight");
      await updateDailyUsage(); // Ensure daily usage is updated
      await updateHourlyUsage(); // Ensure hourly usage is updated
      scheduleMidnightUpdate(); // Reschedule for the next midnight
    });
  }

  void scheduleHourlyUpdate() {
    final now = DateTime.now();
    final nextHour = DateTime(now.year, now.month, now.day, now.hour + 1);
    final durationUntilNextHour = nextHour.difference(now);

    Timer(durationUntilNextHour, () async {
      print("success Hourly");
      await updateDailyUsage(); // Ensure daily usage is updated
      await updateHourlyUsage(); // Ensure hourly usage is updated

      // Get updated daily and hourly usage
      final dailyUsage = await getWeeklyUsage();
      final hourlyUsage = await getHourlyUsage();

      String accessToken = (await _secureStorage.read(key: 'accessToken')) ?? '';
      String userId = (await _secureStorage.read(key: 'userId')) ?? '';
      String deviceId = (await _secureStorage.read(key: 'deviceId')) ?? '';

      // 나중에 추가
      await handleBackendSync(
        dailyUsageData: dailyUsage,
        hourlyUsageData: hourlyUsage,
        deviceId: deviceId,
        userId: userId,
        accessToken: accessToken,
      );

      final prefs = await SharedPreferences.getInstance();
      final currentTimestamp = DateTime.now().toIso8601String();
      prefs.setString('lastSyncTimestamp', currentTimestamp);

      print("Last sync timestamp updated to $currentTimestamp");

      scheduleHourlyUpdate(); // Reschedule for the next hour
    });
  }

  // 백엔드 값 보내는 로직
  Future<void> handleBackendSync({
    required Map<String, Map<String, double>> dailyUsageData,
    required List<Map<String, Object>> hourlyUsageData,
    required String deviceId,
    required String userId,
    required String accessToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final lastSavedJson = prefs.getString('lastSavedTotals') ?? '{}';
    final lastSavedData = Map<String, dynamic>.from(json.decode(lastSavedJson));

    final now = DateTime.now();
    final currentDate = now.toIso8601String().split('T')[0];
    final currentHour = now.hour;

    // Retrieve last saved date and hour
    final lastSavedDate = lastSavedData['date'] ?? '';
    final lastSavedHour = lastSavedData['hour'] ?? -1;

    // Condition: Send data if date or hour changes
    if (lastSavedDate != currentDate || lastSavedHour < currentHour) {
      print("Date or hour changed. Sending data to backend...");

      // Send data to backend
      await sendDataToBackend(
        dailyUsageData: dailyUsageData,
        hourlyUsageData: hourlyUsageData,
        deviceId: deviceId,
        userId: userId,
        accessToken: accessToken,
      );
    }
  }

  // 값 보내기
  Future<void> sendDataToBackend({
    required Map<String, Map<String, double>> dailyUsageData,
    required List<Map<String, Object>> hourlyUsageData,
    required String deviceId,
    required String userId,
    required String accessToken,
  }) async {
    final dailyUrl = Uri.parse('http://ecobuddy.kro.kr:4525/dataUsage/save/daily');
    final hourlyUrl = Uri.parse('http://ecobuddy.kro.kr:4525/dataUsage/save/hourly');

    // Headers
    final headers = {
      "authorization": accessToken,
      "deviceId": deviceId,
      "userId": userId,
      "Content-Type": "application/json",
    };

    print('헤더 : ${headers}');

    final today = DateTime.now().toIso8601String().split('T')[0];

    // Prepare Daily Data as an Array
    final List<Map<String, dynamic>> dailyBody = dailyUsageData.entries
        .where((entry) => entry.key != today) // Exclude today's data
        .map((entry) {
      final date = entry.key;
      final dataUsed = (entry.value['inOctets'] ?? 0) + (entry.value['outOctets'] ?? 0);

      return {
        "usageTime": "${date}T00:00:00", // ISO format for daily data
        "dataUsed": (dataUsed / (1024 * 1024)).toInt(),
        "wifiUsed": 0.0, // Always 0 as specified
      };
    }).toList();

    final now = DateTime.now();
    final currentHourKey = '${now.toIso8601String().split('T')[0]}-${now.hour.toString().padLeft(2, '0')}';

    // Prepare Hourly Data as an Array
    final List<Map<String, dynamic>> hourlyBody = hourlyUsageData
        .where((entry) => entry['hourKey'] != currentHourKey) // Exclude current hour
        .map((entry) {
      final hourKey = entry['hourKey'] as String;
      final splitKey = hourKey.split('-');
      final date = "${splitKey[0]}-${splitKey[1]}-${splitKey[2]}"; // YYYY-MM-DD
      final hour = splitKey[3]; // HH
      final usageTime = "${date}T$hour:00:00";

      final dataUsed = ((entry['inOctets'] as num?)?.toDouble() ?? 0.0) +
          ((entry['outOctets'] as num?)?.toDouble() ?? 0.0);

      return {
        "usageTime": usageTime, // Corrected format
        "dataUsed": (dataUsed / (1024 * 1024)).toInt(),
        "wifiUsed": 0.0, // Always 0 as specified
      };
    }).toList();

    try {
      // Send Daily Data only if not empty
      if (dailyBody.isNotEmpty) {
        final dailyResponse = await http.post(
          dailyUrl,
          headers: headers,
          body: jsonEncode(dailyBody),
        );

        if (dailyResponse.statusCode == 200) {
          print('Daily data sent successfully!');
          final responseBody = jsonDecode(dailyResponse.body);
          if (responseBody.containsKey('new_accessToken')) {
            final newAccessToken = responseBody['new_accessToken'];
            await _secureStorage.write(key: 'accessToken', value: newAccessToken);
            print('Updated accessToken stored in secureStorage');
          }
        } else {
          print('Failed to send daily data: ${dailyResponse.body}');
        }
        print('백엔드 결과 ${dailyResponse.body}');
      } else {
        print('Daily body is empty. Skipping daily data upload.');
      }

      // Send Hourly Data only if not empty
      if (hourlyBody.isNotEmpty) {
        final hourlyResponse = await http.post(
          hourlyUrl,
          headers: headers,
          body: jsonEncode(hourlyBody),
        );

        if (hourlyResponse.statusCode == 200) {
          print('Hourly data sent successfully!');
          final responseBody = jsonDecode(hourlyResponse.body);
          if (responseBody.containsKey('new_accessToken')) {
            final newAccessToken = responseBody['new_accessToken'];
            await _secureStorage.write(key: 'accessToken', value: newAccessToken);
            print('Updated accessToken stored in secureStorage');
          }
        } else {
          print('Failed to send hourly data: ${hourlyResponse.body}');
        }
        print('백엔드 결과 ${hourlyResponse.body}');
      } else {
        print('Hourly body is empty. Skipping hourly data upload.');
      }
    } catch (e) {
      print('Error sending data: $e');
    }
  }
}

