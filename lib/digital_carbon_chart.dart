import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class DataUsageChart extends StatelessWidget {
  final List<dynamic> hourlyUsageData;
  final double animationValue;

  const DataUsageChart({
    Key? key,
    required this.hourlyUsageData,
    required this.animationValue,
  }) : super(key: key);

  LineChartData _buildLineChart() {
    List<FlSpot> mobileSpots = [];
    List<FlSpot> wifiSpots = [];

    double cumulativeMobile = 0.0;
    double cumulativeWifi = 0.0;

    // 디지털 탄소 발자국 계산 Mobile 1MB 11g, WiFi 1MB 8.6g
    for (int i = 0; i < hourlyUsageData.length; i++) {
      final entry = hourlyUsageData[i];
      final timestamp = entry['Timestamp'] as String;
      final hour = double.parse(timestamp.split(" ")[1].split(":")[0]); // 시간만 가져오기

      final mobileData = (entry['MobileReceivedMB'] ?? 0.0) +
          (entry['MobileTransmittedMB'] ?? 0.0);
      final wifiData = (entry['WiFiReceivedMB'] ?? 0.0) +
          (entry['WiFiTransmittedMB'] ?? 0.0);

      cumulativeMobile += mobileData * 11;
      cumulativeWifi += wifiData * 8.6;

      // 그래프 애니메이션
      mobileSpots.add(FlSpot(hour, cumulativeMobile * animationValue));
      wifiSpots.add(FlSpot(hour, cumulativeWifi * animationValue));
    }

    // 최대 Y축 조정
    double maxYValue = (cumulativeMobile > cumulativeWifi
        ? cumulativeMobile
        : cumulativeWifi) *
        1.5;

    return LineChartData(
      // backgroundColor: Colors.white,
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(
        border: Border.all(color: Colors.grey),
      ),// 그리드 라인 제거
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
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey),
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
                Colors.blue.withOpacity(0.2), // Adjust transparency
                Colors.lightBlueAccent.withOpacity(0.1),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          dotData: const FlDotData(show: true), // 점 만들기
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
            show: true,
            gradient: LinearGradient(
              colors: [
                Colors.green.withOpacity(0.2),
                Colors.lightGreenAccent.withOpacity(0.1),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          dotData: const FlDotData(show: true),
          barWidth: 3,
        ),
      ],
      minX: 0,
      maxX: 24,
      minY: 0,
      maxY: maxYValue,
      // 툴팁 부분
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          tooltipPadding: const EdgeInsets.all(8.0),
          tooltipMargin: 8,
          getTooltipColor: (LineBarSpot touchedSpot) => Colors.white10.withOpacity(0.6),
          tooltipBorder: const BorderSide(color: Colors.white, width: 1),
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {

              final isMobile = spot.bar.gradient?.colors.first == Colors.blue;
              final label = isMobile ? 'Mobile Data' : 'Wi-Fi';

              final formattedCarbonFootprint = formatCarbonFootprint(spot.y);

              return LineTooltipItem(
                '$label\nTime: ${spot.x.toInt()}h\nCO₂: $formattedCarbonFootprint',
                TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: isMobile ? Colors.lightBlue : Colors.lightGreen, // Text color matches line
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LineChart(_buildLineChart());
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
