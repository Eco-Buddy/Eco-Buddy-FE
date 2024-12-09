import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'kotlin_tokenmanager.dart';
import 'other_devices_digital_carbon_chart.dart';

class BackendDataDisplay extends StatefulWidget {
  const BackendDataDisplay({Key? key}) : super(key: key);

  @override
  _BackendDataDisplayState createState() => _BackendDataDisplayState();
}

class _BackendDataDisplayState extends State<BackendDataDisplay>
    with SingleTickerProviderStateMixin {
  String? selectedDeviceId;
  List<String> availableDeviceIds = [];
  List<Map<String, dynamic>> filteredDailyUsageData = [];
  List<Map<String, dynamic>> filteredHourlyUsageData = [];
  bool isLoading = false;
  String? errorMessage;

  // 기기 ID와 이름 매핑
  Map<String, String> deviceIdToName = {};

  final _secureStorage = const FlutterSecureStorage();

  late AnimationController _animationController;
  late Animation<double> _animation;

  bool _isChartVisible = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);

    _animation.addListener(() {
      setState(() {});
    });

    fetchDeviceIds(); // Load available device IDs on init
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Fetch device IDs for the given user
  Future<void> fetchDeviceIds() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      availableDeviceIds.clear();
      deviceIdToName.clear();
    });

    String userId = (await _secureStorage.read(key: 'userId')) ?? '';
    String deviceId = (await _secureStorage.read(key: 'deviceId')) ?? '';

    final url = Uri.parse('http://ecobuddy.kro.kr:4525/devices');
    final headers = {
      "userId": userId,
    };

    try {
      final response = await http.post(url, headers: headers);

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final deviceIds = body['deviceIds'] as List<dynamic>;

        final filteredDeviceIds = List<String>.from(deviceIds)
            .where((id) => id != deviceId)
            .toList();

        setState(() {
          availableDeviceIds = filteredDeviceIds;

          for (int i = 0; i < availableDeviceIds.length; i++) {
            deviceIdToName[availableDeviceIds[i]] = "기기 ${i + 1}";
          }

          if (availableDeviceIds.isNotEmpty) {
            selectedDeviceId = availableDeviceIds.first;
            fetchDeviceData(); // Automatically load data for the first device
          }
        });
      } else {
        setState(() {
          errorMessage = 'No device IDs available.';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching device IDs: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchDeviceData() async {
    if (selectedDeviceId == null) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    String accessToken = (await _secureStorage.read(key: 'accessToken')) ?? '';
    String userId = (await _secureStorage.read(key: 'userId')) ?? '';
    String devieId = (await _secureStorage.read(key: 'deviceId')) ?? '';

    final dailyUrl =
        Uri.parse('http://ecobuddy.kro.kr:4525/dataUsage/load/other/daily');
    final hourlyUrl =
        Uri.parse('http://ecobuddy.kro.kr:4525/dataUsage/load/other/hourly');
    final headers = {
      "authorization": accessToken,
      "userId": userId,
      "deviceId": devieId,
      "searchDeviceId": selectedDeviceId!,
    };

    try {
      // Fetch daily data
      final dailyResponse = await http.post(dailyUrl, headers: headers);
      if (dailyResponse.statusCode == 200) {
        final dailyBody = json.decode(dailyResponse.body);

        // Update access token if provided
        final newAccessToken = dailyBody['new_accessToken'];
        if (newAccessToken != null) {
          await _secureStorage.write(key: 'accessToken', value: newAccessToken);
          await TokenManager.updateCredentials();
        }

        final dailyUsage = dailyBody['usage'] as List<dynamic>;
        setState(() {
          filteredDailyUsageData = dailyUsage
              .map((entry) => {
                    'usageTime': entry['usageTime'],
                    'dataUsed': double.parse(entry['dataUsed'].toString()),
                    'wifiUsed': double.parse(entry['wifiUsed'].toString()),
                  })
              .toList();
        });
      } else {
        setState(() {
          errorMessage = 'Failed to fetch daily data: ${dailyResponse.body}';
        });
      }

      // Fetch hourly data
      final hourlyResponse = await http.post(hourlyUrl, headers: headers);
      if (hourlyResponse.statusCode == 200) {
        final hourlyBody = json.decode(hourlyResponse.body);

        // Update access token if provided
        final newAccessToken = hourlyBody['new_accessToken'];
        print(newAccessToken);
        if (newAccessToken != null) {
          await _secureStorage.write(key: 'accessToken', value: newAccessToken);
          await TokenManager.updateCredentials();
        }

        final hourlyUsage = hourlyBody['usage'] as List<dynamic>;

        final currentDate = DateTime.now().toIso8601String().split('T')[0];
        setState(() {
          filteredHourlyUsageData = hourlyUsage
              .map((entry) => {
                    'usageTime': entry['usageTime'],
                    'dataUsed': double.parse(entry['dataUsed'].toString()),
                    'wifiUsed': double.parse(entry['wifiUsed'].toString()),
                  })
              .where((entry) =>
                  entry['usageTime'].toString().split('T')[0] == currentDate)
              .toList();
        });
      } else {
        setState(() {
          errorMessage = 'Failed to fetch hourly data: ${hourlyResponse.body}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching data: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildDailySummary() {
    if (filteredHourlyUsageData.isNotEmpty) {
      final lastHourlyEntry = filteredHourlyUsageData.last;
      final todayMobileCarbonFootprint =
          (lastHourlyEntry['dataUsed'] ?? 0) * 11;
      final todayWifiCarbonFootprint = (lastHourlyEntry['wifiUsed'] ?? 0) * 8.6;
      final todayTotalCarbonFootprint =
          todayMobileCarbonFootprint + todayWifiCarbonFootprint;

      return Column(
        children: [
          // Total Carbon Footprint
          Container(
            margin: const EdgeInsets.symmetric(vertical: 20),
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'assets/design1.png',
                  width: 259,
                  height: 259,
                  fit: BoxFit.contain,
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Image.asset(
                      'assets/digital_CO2.png',
                      width: 60,
                      height: 60,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Total",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      formatCarbonFootprint(todayTotalCarbonFootprint),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Mobile and Wi-Fi Breakdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Mobile Data
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.green,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.signal_cellular_alt,
                          color: Colors.green, size: 36),
                      const SizedBox(height: 10),
                      Text(
                        formatCarbonFootprint(todayMobileCarbonFootprint),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        formatDataUsage(todayMobileCarbonFootprint / 11),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.lightGreen,
                        ),
                      ),
                      const Text(
                        'Mobile Data',
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),
              // Wi-Fi
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.blue,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.wifi, color: Colors.blue, size: 36),
                      const SizedBox(height: 10),
                      Text(
                        formatCarbonFootprint(todayWifiCarbonFootprint),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      Text(
                        formatDataUsage(todayWifiCarbonFootprint / 8.6),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.lightBlueAccent,
                        ),
                      ),
                      const Text(
                        'Wi-Fi',
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }
    // Show a loading indicator if hourly data is not available
    return const Center(child: CircularProgressIndicator());
  }

  Widget buildDataTable() {
    return Table(
      border: TableBorder(
        horizontalInside: BorderSide(color: Colors.grey.shade300, width: 0.5),
      ),
      columnWidths: const {
        0: FlexColumnWidth(1.2),
        1: FlexColumnWidth(1.2),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
      },
      children: [
        // Header
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade200),
          children: const [
            Padding(
              padding: EdgeInsets.all(6),
              child: Text(
                'Date',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(6),
              child: Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.signal_cellular_alt,
                  size: 16, color: Colors.green),
            ),
            Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.wifi, size: 16, color: Colors.blue),
            ),
          ],
        ),
        // Data Rows
        if (filteredHourlyUsageData.isNotEmpty)
          for (var entry in filteredDailyUsageData) ...[
            TableRow(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text(
                    entry['usageTime'].split('T')[0],
                    style: const TextStyle(fontSize: 12, color: Colors.black),
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text(
                    formatCarbonFootprint(
                      (entry['dataUsed'] ?? 0) * 11 +
                          ((entry['wifiUsed'] ?? 0) * 8.6),
                    ),
                    style: const TextStyle(fontSize: 12, color: Colors.black),
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text(
                    formatCarbonFootprint((entry['dataUsed'] ?? 0) * 11),
                    style: const TextStyle(fontSize: 12, color: Colors.green),
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text(
                    formatCarbonFootprint((entry['wifiUsed'] ?? 0) * 8.6),
                    style: const TextStyle(fontSize: 12, color: Colors.blue),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ],
        if (filteredHourlyUsageData.isNotEmpty) ...[
          TableRow(
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.2)),
            children: [
              const Padding(
                padding: EdgeInsets.all(6),
                child: Text(
                  'Today',
                  style: TextStyle(fontSize: 12, color: Colors.black),
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(6),
                child: Text(
                  formatCarbonFootprint(
                    (filteredHourlyUsageData.last['dataUsed'] ?? 0) * 11 +
                        ((filteredHourlyUsageData.last['wifiUsed'] ?? 0) * 8.6),
                  ),
                  style: const TextStyle(fontSize: 12, color: Colors.black),
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(6),
                child: Text(
                  formatCarbonFootprint(
                      (filteredHourlyUsageData.last['dataUsed'] ?? 0) * 11),
                  style: const TextStyle(fontSize: 12, color: Colors.green),
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(6),
                child: Text(
                  formatCarbonFootprint(
                      (filteredHourlyUsageData.last['wifiUsed'] ?? 0) * 8.6),
                  style: const TextStyle(fontSize: 12, color: Colors.blue),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          )
        ]
      ],
    );
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('다른 플랫폼 현황',
            style: TextStyle(
            fontWeight: FontWeight.bold),
      ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Devices',
            onPressed: fetchDeviceIds,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
                ? Center(child: Text(errorMessage!))
                : ListView(
                    children: [
                      // Dropdown for device selection
                      if (availableDeviceIds.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Row(
                            children: [
                              const Text(
                                'Device:',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  // Ensures the dropdown takes the full available width
                                  value: selectedDeviceId,
                                  onChanged: (newDeviceId) {
                                    if (newDeviceId != null) {
                                      setState(() {
                                        selectedDeviceId = newDeviceId;
                                        fetchDeviceData(); // Fetch data for the selected device
                                      });
                                    }
                                  },
                                  items: availableDeviceIds.map((deviceId) {
                                    return DropdownMenuItem<String>(
                                      value: deviceId,
                                      child: Text(
                                        deviceIdToName[deviceId] ?? deviceId,
                                        overflow: TextOverflow.ellipsis,
                                        // Truncate long device names
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (filteredHourlyUsageData.isEmpty)
                        const Center(
                          child: Text(
                            "데이터 측정 중 입니다.",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      else ...[
                        Text(
                          "${DateFormat('MM/dd').format(DateTime.now())} 탄소 발자국",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        // 제일 위 컴포넌트
                        buildDailySummary(),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Divider(
                            color: Colors.green,
                            thickness: 2,
                            indent: 16,
                            endIndent: 16,
                          ),
                        ),

                        const Text(
                          '일일 탄소 발자국:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 10),
                        //테이블
                        buildDataTable(),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Divider(
                            color: Colors.green,
                            thickness: 2,
                            indent: 16,
                            endIndent: 16,
                          ),
                        ),

                        const Text(
                          '시간별 탄소 발자국:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),

                        VisibilityDetector(
                          key: const Key('LineChartVisibilityDetector'),
                          onVisibilityChanged: (info) {
                            if (info.visibleFraction > 0.5 && !_isChartVisible) {
                              setState(() {
                                _isChartVisible = true;
                              });
                              _animationController.reset();
                              _animationController.forward();
                            } else if (info.visibleFraction <= 0.5 && _isChartVisible) {
                              setState(() {
                                _isChartVisible = false;
                              });
                              _animationController.reverse();
                            }
                          },
                          child: ValueListenableBuilder<double>(
                            valueListenable: _animation,
                            builder: (context, value, child) {
                              return SizedBox(
                                height: 200,
                                child: OtherDevicesDigitalCarbonChart(
                                  hourlyUsageData: filteredHourlyUsageData,
                                  animationValue: value,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
      ),
    );
  }
}

String formatCarbonFootprint(double value) {
  if (value >= 1e6) {
    return '${(value / 1e6).toStringAsFixed(2)} t'; // Convert to tons
  } else if (value >= 1e3) {
    return '${(value / 1e3).toStringAsFixed(2)} kg'; // Convert to kilograms
  } else {
    return '${value.toStringAsFixed(2)} g'; // Keep in grams
  }
}

// 유틸리티 2
String formatDataUsage(double valueInMB) {
  if (valueInMB >= 1024) {
    // Convert to GB
    return '${(valueInMB / 1024).toStringAsFixed(2)} GB';
  } else {
    // Keep in MB
    return '${valueInMB.toStringAsFixed(2)} MB';
  }
}