import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'digital_carbon_chart.dart';
import 'package:intl/intl.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'other_devices_digital_carbon.dart';

class DataUsagePage extends StatefulWidget {

  const DataUsagePage({Key? key}) : super(key: key);

  @override
  _DataUsagePageState createState() => _DataUsagePageState();
}

class _DataUsagePageState extends State<DataUsagePage>
    with SingleTickerProviderStateMixin {
  static const platform = MethodChannel('com.example.datausage/data');
  final _secureStorage = const FlutterSecureStorage();

  Map<String, dynamic> dailyUsageData = {};
  List<dynamic> hourlyUsageData = [];
  String message = '';

  late AnimationController _animationController;
  late Animation<double> _animation;

  // 차트가 사용자에게 보였을 때 애니메이션 적용
  bool _isChartVisible = false;

  String? accessToken;
  String? userId;
  String? deviceId;

  @override
  void initState() {
    super.initState();
    sendDataToKotlin();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500), // 애니메이션 주기
    );
    _animation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);

    _animation.addListener(() {
      setState(() {});
    });

    _fetchData();
  }

  // 코틀린으로 값 보내기
  Future<void> sendDataToKotlin() async {
    try {
      accessToken = await _secureStorage.read(key: 'accessToken');
      userId = await _secureStorage.read(key: 'userId');
      deviceId = await _secureStorage.read(key: 'deviceId');

      if (accessToken != null && userId != null && deviceId != null) {
        await platform.invokeMethod('sendData', {
          'access_token': accessToken,
          'device_id': deviceId,
          'user_id': userId,
        });
      } else {
        setState(() {
          message = "Failed to retrieve data from secure storage.";
        });
      }

    } on PlatformException catch (e) {
      print("Failed to send data: '${e.message}'.");
    }
  }

  Future<void> _fetchData() async {
    await getDailyDataUsage();
    await getHourlyDataUsage();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // 네이티브 api, 데이터 가져 와서 디코딩
  Future<void> getDailyDataUsage() async {
    try {
      final result = await platform.invokeMethod('getDailyDataUsage');
      setState(() {
        dailyUsageData = Map<String, dynamic>.from(result);
        message = '';
      });
    } on PlatformException catch (e) {
      setState(() {
        message = "Failed to get daily data usage: '${e.message}'.";
      });
    }
  }

  Future<void> getHourlyDataUsage() async {
    try {
      final result = await platform.invokeMethod('getHourlyDataUsage');
      setState(() {
        hourlyUsageData = List<dynamic>.from(result);
        message = '';
      });
    } on PlatformException catch (e) {
      setState(() {
        message = "Failed to get hourly data usage: '${e.message}'.";
      });
    }
  }

  Future<void> resetPreferences() async {
    try {
      await platform.invokeMethod('resetPreferences');
      setState(() {
        message = 'Preferences reset. Data will be recalculated.';
        dailyUsageData = {};
        hourlyUsageData = [];
      });
    } on PlatformException catch (e) {
      setState(() {
        message = "Failed to reset preferences: '${e.message}'.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double todayMobileCarbonFootprint = 0.0;
    double todayWifiCarbonFootprint = 0.0;
    double todayTotalCarbonFootprint = 0.0;

    // 오늘 배출한 디지털 탄소발자국 계산
    if (dailyUsageData.isNotEmpty) {
      String latestDate = dailyUsageData.keys.last;
      String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

      for (var date in dailyUsageData.keys) {
        if (latestDate == todayDate) {
          double mobileReceived =
              (dailyUsageData[date]['MobileReceivedMB'] ?? 0).toDouble();
          double mobileTransmitted =
              (dailyUsageData[date]['MobileTransmittedMB'] ?? 0).toDouble();
          double wifiReceived =
              (dailyUsageData[date]['WiFiReceivedMB'] ?? 0).toDouble();
          double wifiTransmitted =
              (dailyUsageData[date]['WiFiTransmittedMB'] ?? 0).toDouble();

          todayMobileCarbonFootprint =
              (mobileReceived + mobileTransmitted) * 11;
          todayWifiCarbonFootprint = (wifiReceived + wifiTransmitted) * 8.6;
          todayTotalCarbonFootprint =
              todayMobileCarbonFootprint + todayWifiCarbonFootprint;
        } else {
          print("Today's data is not available.");
        }
      }
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: dailyUsageData.isEmpty &&
                    hourlyUsageData.isEmpty &&
                    message.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    children: [
                      Text(
                        "${DateFormat('MM/dd').format(DateTime.now())} 탄소 발자국",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      if (dailyUsageData.isNotEmpty) ...[
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
                                    formatCarbonFootprint(
                                        todayTotalCarbonFootprint),
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

                        // 가로 배치
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
                                      formatCarbonFootprint(
                                          todayMobileCarbonFootprint),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const Text(
                                      'Mobile Data',
                                      style: TextStyle(
                                          fontSize: 14, color: Colors.black87),
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
                                    const Icon(Icons.wifi,
                                        color: Colors.blue, size: 36),
                                    const SizedBox(height: 10),
                                    Text(
                                      formatCarbonFootprint(
                                          todayWifiCarbonFootprint),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    const Text(
                                      'Wi-Fi',
                                      style: TextStyle(
                                          fontSize: 14, color: Colors.black87),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (dailyUsageData.isNotEmpty) ...[
                        // 구분선
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Divider(
                            color: Colors.green,
                            thickness: 2,
                            indent: 16,
                            endIndent: 16,
                          ),
                        ),

                        const Text('일일 탄소 발자국 :',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 10),

                        // 차트 부분
                        Table(
                          border: TableBorder(
                            horizontalInside: BorderSide(
                                color: Colors.grey.shade300, width: 0.5),
                          ),
                          columnWidths: const {
                            0: FlexColumnWidth(1.2), // Reduced Date column width
                            1: FlexColumnWidth(1.2), // Reduced Total column width
                            2: FlexColumnWidth(1), // Mobile icon column
                            3: FlexColumnWidth(1), // Wi-Fi icon column
                          },
                          children: [
                            // 테이블 헤더
                            TableRow(
                              decoration:
                                  BoxDecoration(color: Colors.grey.shade200),
                              children: const [
                                Padding(
                                  padding: EdgeInsets.all(6),
                                  // Slightly smaller padding
                                  child: Text(
                                    'Date',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.black),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(6),
                                  child: Text(
                                    'Total',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.black),
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
                                  child: Icon(Icons.wifi,
                                      size: 16, color: Colors.blue),
                                ),
                              ],
                            ),
                            // 데이터
                            for (var date in dailyUsageData.keys) ...[
                              TableRow(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.5),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Text(
                                      date.substring(5),
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.black),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Text(
                                      formatCarbonFootprint(
                                        ((dailyUsageData[date]['MobileReceivedMB'] ??
                                                            0)
                                                        .toDouble() +
                                                    (dailyUsageData[date][
                                                                'MobileTransmittedMB'] ??
                                                            0)
                                                        .toDouble()) *
                                                11 +
                                            ((dailyUsageData[date][
                                                                'WiFiReceivedMB'] ??
                                                            0)
                                                        .toDouble() +
                                                    (dailyUsageData[date][
                                                                'WiFiTransmittedMB'] ??
                                                            0)
                                                        .toDouble()) *
                                                8.6,
                                      ),
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.black),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Text(
                                      formatCarbonFootprint(
                                        ((dailyUsageData[date][
                                                            'MobileReceivedMB'] ??
                                                        0)
                                                    .toDouble() +
                                                (dailyUsageData[date][
                                                            'MobileTransmittedMB'] ??
                                                        0)
                                                    .toDouble()) *
                                            11,
                                      ),
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.green),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Text(
                                      formatCarbonFootprint(
                                        ((dailyUsageData[date][
                                                            'WiFiReceivedMB'] ??
                                                        0)
                                                    .toDouble() +
                                                (dailyUsageData[date][
                                                            'WiFiTransmittedMB'] ??
                                                        0)
                                                    .toDouble()) *
                                            8.6,
                                      ),
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.blue),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ],
                      if (hourlyUsageData.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Divider(
                            color: Colors.green,
                            thickness: 2,
                            indent: 16,
                            endIndent: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text('시간별 탄소 발자국 :',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 10),
                        VisibilityDetector(
                          key: const Key('LineChartVisibilityDetector'),
                          onVisibilityChanged: (info) {
                            if (info.visibleFraction > 0.5 && !_isChartVisible && hourlyUsageData.isNotEmpty) {
                              setState(() {
                                _isChartVisible = true;
                              });
                              _animationController.reset();
                              _animationController.forward(from: 0.0);
                            } else if (info.visibleFraction <= 0.5 && _isChartVisible) {
                              setState(() {
                                _isChartVisible = false;
                              });
                              _animationController.reverse();
                            }
                          },
                          child: SizedBox(
                            height: 200,
                            child: DataUsageChart(
                              hourlyUsageData: hourlyUsageData,
                              animationValue: _animation.value,
                            ),
                          ),
                        ),
                      ],
                      if (message.isNotEmpty) Text(message),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: resetPreferences,
                        child: const Text("Reset Preferences"),
                      ),
                    ],
                  ),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton(
                  onPressed: () async {
                    await _fetchData();
                  },
                  backgroundColor: Colors.green,
                  mini: true,
                  tooltip: 'Refresh Data',
                  child: const Icon(Icons.refresh, color: Colors.white),
                ),
                const SizedBox(height: 16),
                FloatingActionButton(
                  heroTag: 'OtherDevice',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BackendDataDisplay()
                        ),
                      );
                  },
                  backgroundColor: Colors.blue,
                  mini: true,
                  tooltip: 'Other Devices',
                  child: const Icon(Icons.devices, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 유틸리티
String formatCarbonFootprint(double value) {
  if (value >= 1e6) {
    return '${(value / 1e6).toStringAsFixed(2)} t'; // Convert to tons
  } else if (value >= 1e3) {
    return '${(value / 1e3).toStringAsFixed(2)} kg'; // Convert to kilograms
  } else {
    return '${value.toStringAsFixed(2)} g'; // Keep in grams
  }
}
