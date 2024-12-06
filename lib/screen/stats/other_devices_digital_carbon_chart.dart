import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class OtherDevicesDigitalCarbonChart extends StatelessWidget {
  final List<dynamic> hourlyUsageData;
  final double animationValue;

  const OtherDevicesDigitalCarbonChart({
    Key? key,
    required this.hourlyUsageData,
    required this.animationValue,
  }) : super(key: key);

  LineChartData _buildLineChartData() {
    List<FlSpot> mobileSpots = [];
    List<FlSpot> wifiSpots = [];

    double mobileCarbon = 0.0;
    double wifiCarbon = 0.0;

    for (int i = 0; i < hourlyUsageData.length; i++) {
      final entry = hourlyUsageData[i];
      final timestamp = entry['usageTime'] as String;
      final hour = double.parse(timestamp.split("T")[1].split(":")[0]);

      mobileCarbon = (entry['dataUsed'] ?? 0.0) * 11;
      wifiCarbon = (entry['wifiUsed'] ?? 0.0) * 8.6;

      mobileSpots.add(FlSpot(hour, mobileCarbon * animationValue));
      wifiSpots.add(FlSpot(hour, wifiCarbon * animationValue));
    }

    double maxYValue = (mobileCarbon > wifiCarbon
        ? mobileCarbon
        : wifiCarbon) *
        1.5;

    return LineChartData(
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(
        border: Border.all(color: Colors.grey),
      ),
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
          dotData: const FlDotData(show: true), // 점 만들기
          barWidth: 3,
        ),
        LineChartBarData(
          spots: wifiSpots,
          isCurved: false,
          gradient: const LinearGradient(
            colors: [Colors.blue, Colors.lightBlueAccent],
            stops: [0.1, 0.9],
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                Colors.blue.withOpacity(0.2),
                Colors.lightBlueAccent.withOpacity(0.1),
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

              final isMobile = spot.bar.gradient?.colors.first == Colors.green;
              final label = isMobile ? 'Mobile Data' : 'Wi-Fi';

              final formattedCarbonFootprint = formatCarbonFootprint(spot.y);

              return LineTooltipItem(
                '$label\nTime: ${spot.x.toInt()}h\nCO₂: $formattedCarbonFootprint',
                TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: isMobile ? Colors.lightGreen : Colors.lightBlue, // Text color matches line
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
    return LineChart(_buildLineChartData());
  }
}

// 유틸리티
String formatCarbonFootprint(double value) {
  if (value >= 1e6) {
    return '${(value / 1e6).toStringAsFixed(2)} t'; // Tons
  } else if (value >= 1e3) {
    return '${(value / 1e3).toStringAsFixed(2)} kg'; // Kilograms
  } else {
    return '${value.toStringAsFixed(2)} g'; // Grams
  }
}
