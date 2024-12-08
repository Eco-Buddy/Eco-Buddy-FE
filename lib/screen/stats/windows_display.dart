import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'other_devices_digital_carbon.dart';
import 'windows_digital_carbon_chart.dart';

class DisplayUsagePage extends StatefulWidget {
  final Future<void> Function() updateDailyUsage;
  final Future<void> Function() updateHourlyUsage;

  const DisplayUsagePage({
    Key? key,
    required this.updateDailyUsage,
    required this.updateHourlyUsage,
  }) : super(key: key);

  @override
  DisplayUsagePageState createState() => DisplayUsagePageState();
}

class DisplayUsagePageState extends State<DisplayUsagePage> with SingleTickerProviderStateMixin{
  double todayWifi = 0.0;
  double todayEthernet = 0.0;

  Map<String, Map<String, double>> dailyUsageData = {};
  Map<String, Map<String, double>> weeklyUsageData = {};
  List<dynamic> hourlyUsageData = [];

  late AnimationController _animationController;
  late Animation<double> _animation;

  bool _isChartVisible = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500), // 애니메이션 주기
    );
    _animation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);

    // _animation.addListener(() {
    //   setState(() {});
    // });

    fetchData(); // Fetch today's data on initialization
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> fetchData() async {
    // Fetch the updated data and populate shared state
    final prefs = await SharedPreferences.getInstance();

    // Fetch daily usage
    final weeklyDataJson = prefs.getString('weeklyDataUsage') ?? '{}';
    final Map<String, dynamic> rawData = json.decode(weeklyDataJson);
    final Map<String, Map<String, double>> newDailyUsageData = {};

    rawData.forEach((key, value) {
      final Map<String, dynamic> dailyData = value as Map<String, dynamic>;
      newDailyUsageData[key] = {
        'ethernet': (dailyData['ethernet'] ?? 0) / (1024 * 1024),
        'wifi': (dailyData['wifi'] ?? 0) / (1024 * 1024),
      };
    });

    setState(() {
      dailyUsageData = newDailyUsageData;
      weeklyUsageData = newDailyUsageData;
    });

    // Update today's usage
    final todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (dailyUsageData.containsKey(todayDate)) {
      setState(() {
        todayEthernet = (dailyUsageData[todayDate]?['ethernet'] ?? 0.0) * 11;
        todayWifi = (dailyUsageData[todayDate]?['wifi'] ?? 0.0) * 8.6;
      });
    }

    // Fetch hourly usage
    final hourlyDataJson = prefs.getString('hourlyDataUsage') ?? '{}';
    final Map<String, dynamic> rawHourlyData = json.decode(hourlyDataJson);
    final List<Map<String, double>> parsedHourlyData = [];

    rawHourlyData.forEach((key, value) {
      final Map<String, dynamic> hourlyData = value as Map<String, dynamic>;
      parsedHourlyData.add({
        'hour': double.parse(key.split('-').last), // Extract hour from the key
        'ethernet': (hourlyData['ethernet'] ?? 0) / (1024 * 1024), // Convert to MB
        'wifi': (hourlyData['wifi'] ?? 0) / (1024 * 1024), // Convert to MB
      });
    });

    setState(() {
      hourlyUsageData = parsedHourlyData;
    });
  }

  Future<void> refreshData() async {
    await widget.updateDailyUsage(); // Daily usage 업데이트
    await widget.updateHourlyUsage(); // Hourly usage 업데이트
    await fetchData(); // 데이터 다시 가져오기
    print("Data refreshed successfully!");
  }

  Future<List<TableRow>> getWeeklyDataRows() async {
    // Generate rows for the table
    List<TableRow> rows = [
      TableRow(
        decoration: BoxDecoration(color: Colors.grey.shade200),
        children: const [
          Padding(
            padding: EdgeInsets.all(6),
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
    ];

    weeklyUsageData.forEach((date, usage) {
      final double ethernet = (usage['ethernet'] ?? 0.0) * 11;
      final double wifi = (usage['wifi'] ?? 0.0) * 8.6;

      rows.add(
        TableRow(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(6),
              child: Text(
                date.substring(5), // Show only MM-DD
                style: const TextStyle(fontSize: 12, color: Colors.black),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Text(
                formatCarbonFootprint(ethernet + wifi),
                style: const TextStyle(fontSize: 12, color: Colors.black),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Text(
                formatCarbonFootprint(ethernet),
                style: const TextStyle(fontSize: 12, color: Colors.green),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Text(
                formatCarbonFootprint(wifi),
                style: const TextStyle(fontSize: 12, color: Colors.blue),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    });

    return rows;
  }

  Future<void> resetPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    setState(() {
      todayWifi = 0.0;
      todayEthernet = 0.0;
    });
    print("SharedPreferences have been reset.");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                Text(
                  "${DateFormat('MM/dd').format(DateTime.now())} 탄소 발자국",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
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
                            formatCarbonFootprint(todayEthernet + todayWifi),
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
                    // Send Data
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
                              formatCarbonFootprint(todayEthernet),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              formatDataUsage(todayEthernet / 11),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.lightGreen,
                              ),
                            ),
                            const Text(
                              'Ethernet',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Receive Data
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
                              formatCarbonFootprint(todayWifi),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            Text(
                              formatDataUsage(todayWifi / 8.6),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.lightBlueAccent,
                              ),
                            ),
                            const Text(
                              'WiFi',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
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

                const Text(
                  '일일 탄소 발자국:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 10),

                //차트 부분
                FutureBuilder<List<TableRow>>(
                  future: getWeeklyDataRows(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else {
                      return Table(
                        border: TableBorder(
                          horizontalInside: BorderSide(
                            color: Colors.grey.shade300,
                            width: 0.5,
                          ),
                        ),
                        columnWidths: const {
                          0: FlexColumnWidth(1.2), // Date column width
                          1: FlexColumnWidth(1.2), // Total column width
                          2: FlexColumnWidth(1), // Sent column width
                          3: FlexColumnWidth(1), // Received column width
                        },
                        children: snapshot.data!,
                      );
                    }
                  },
                ),
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
                // Line Chart
                const Text(
                  '시간별 탄소 발자국:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
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
                  child: ValueListenableBuilder<double>(
                    valueListenable: _animation,
                    builder: (context, value, child) {
                      return SizedBox(
                        height: 200,
                        child: WindowsDigitalCarbonChart(
                          hourlyUsageData: hourlyUsageData,
                          animationValue: value,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: resetPreferences,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text(
                    "Reset Preferences",
                    style: TextStyle(color: Colors.white),
                  ),
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
                  onPressed: refreshData,
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