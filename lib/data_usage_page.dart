import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:visibility_detector/visibility_detector.dart';

class DataUsagePage extends StatefulWidget {
  @override
  _DataUsagePageState createState() => _DataUsagePageState();
}

class _DataUsagePageState extends State<DataUsagePage> with SingleTickerProviderStateMixin {
  static const platform = MethodChannel('com.example.datausage/data');
  Map<String, dynamic> dailyUsageData = {};
  List<dynamic> hourlyUsageData = [];
  String message = '';

  late AnimationController _animationController;
  late Animation<double> _animation;
  // 차트가 사용자에게 보였을 때 애니메이션 적용
  bool _isChartVisible = false;


  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500), // Animation duration
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);

    _animation.addListener(() {
      setState(() {});
    });

    getDailyDataUsage();
    getHourlyDataUsage();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

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

  LineChartData _buildLineChart() {
    List<FlSpot> mobileSpots = [];
    List<FlSpot> wifiSpots = [];

    // 차트에 데이터 준비하는 부분
    for (int i = 0; i < hourlyUsageData.length; i++) {
      final entry = hourlyUsageData[i];
      final timestamp = entry['Timestamp'] as String;
      final hour = double.parse(timestamp.split(" ")[1].split(":")[0]); // 시간만 필요
      final mobileData = entry['MobileReceivedMB'] ?? 0.0;
      final wifiData = entry['WiFiReceivedMB'] ?? 0.0;

      mobileSpots.add(FlSpot(hour, mobileData * _animation.value));
      wifiSpots.add(FlSpot(hour, wifiData * _animation.value));
    }

    return LineChartData(
      gridData: const FlGridData(show: true),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 && value.toInt() <= 24) {
                return Padding(
                  padding: EdgeInsets.only(
                    left: value == 0 ? 12.0 : 0,
                    right: value == 24 ? 12.0 : 0,
                  ),
                  child: Text(
                    '${value.toInt()}',
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              }
              return Container();
            },
          ),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: mobileSpots,
          isCurved: false,
          gradient: const LinearGradient(
            colors: [Colors.blue, Colors.lightBlueAccent],
            stops: [0.1, 0.9],
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                Colors.blue.withOpacity(0.4),
                Colors.lightBlueAccent.withOpacity(0.1),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          // 값에 점
          dotData: const FlDotData(show: true),
          barWidth: 3,
        ),
        LineChartBarData(
          spots: wifiSpots,
          isCurved: false,
          gradient: const LinearGradient(
            colors: [Colors.green, Colors.lightGreenAccent],
            stops: [0.1, 0.9],
          ),
          belowBarData: BarAreaData(
            show: false,
            gradient: LinearGradient(
              colors: [
                Colors.green.withOpacity(0.4),
                Colors.lightGreenAccent.withOpacity(0.1),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          // 값에 점
          dotData: const FlDotData(show: true),
          barWidth: 3,
        ),
      ],
      minX: 0,
      maxX: 24,
      minY: 0,
      maxY: hourlyUsageData.fold<double>(
        10,
            (max, e) => [
          max,
          e['MobileReceivedMB']?.toDouble() ?? 0.0,
          e['WiFiReceivedMB']?.toDouble() ?? 0.0
        ].reduce((a, b) => a > b ? a : b),
      ),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          tooltipPadding: const EdgeInsets.all(8.0), // 툴팁 패딩 조정
          tooltipMargin: 8, // 툴팁 마진 필요
          getTooltipColor: (LineBarSpot touchedSpot) => Colors.blue.withOpacity(0.8), // 배경 화면 설정
          tooltipBorder: const BorderSide(color: Colors.white, width: 1), // 툴팁 경계
          // 박스 안에 맞게 설정
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              return LineTooltipItem(
                'Time: ${spot.x.toInt()}h\nData: ${spot.y.toStringAsFixed(2)} MB',
                const TextStyle(color: Colors.white),
              );
            }).toList();
          },
        ),
        touchCallback: (event, touchResponse) {
          // Optional: Handle touch events if needed
        },
        handleBuiltInTouches: true, // Enable built-in touch gestures
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Network Usage')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: dailyUsageData.isEmpty && hourlyUsageData.isEmpty && message.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView(
          children: [
            if (dailyUsageData.isNotEmpty) ...[
              const Text('Daily Data Usage:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              for (var date in dailyUsageData.keys) ...[
                Text("Date: $date", style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("Mobile Data Received: ${dailyUsageData[date]['MobileReceivedMB']} MB"),
                Text("Mobile Data Transmitted: ${dailyUsageData[date]['MobileTransmittedMB']} MB"),
                Text("WiFi Data Received: ${dailyUsageData[date]['WiFiReceivedMB']} MB"),
                Text("WiFi Data Transmitted: ${dailyUsageData[date]['WiFiTransmittedMB']} MB"),
                const SizedBox(height: 10),
              ],
            ],
            const Divider(),
            if (hourlyUsageData.isNotEmpty) ...[
              const Text('Hourly Data Usage (Today):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              for (var entry in hourlyUsageData) ...[
                Text("Time: ${entry['Timestamp']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("Mobile Data Received: ${entry['MobileReceivedMB']} MB"),
                Text("Mobile Data Transmitted: ${entry['MobileTransmittedMB']} MB"),
                Text("WiFi Data Received: ${entry['WiFiReceivedMB']} MB"),
                Text("WiFi Data Transmitted: ${entry['WiFiTransmittedMB']} MB"),
                const SizedBox(height: 10),
              ],
              const Divider(),
              const Text('Hourly Data Usage Statistics :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                  height: 400,
                  child: LineChart(_buildLineChart()),
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
    );
  }
}
