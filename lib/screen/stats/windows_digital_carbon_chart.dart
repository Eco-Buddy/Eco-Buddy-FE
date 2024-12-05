import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class WindowsDigitalCarbonChart extends StatelessWidget {
  final List<dynamic> hourlyUsageData;
  final double animationValue;

  const WindowsDigitalCarbonChart({
    Key? key,
    required this.hourlyUsageData,
    required this.animationValue,
  }) : super(key: key);

  LineChartData _buildLineChart() {
    List<FlSpot> sendSpots = [];
    List<FlSpot> receiveSpots = [];

    double cumulativeWifi = 0.0;
    double cumulativeEthernet = 0.0;

    // Populate chart spots using hourly data
    for (final data in hourlyUsageData) {
      final hour = data['hour']!;
      final wifiData = data['wifi']!;
      final ethernetData = data['ethernet']!;

      cumulativeWifi = wifiData * 8.6;
      cumulativeEthernet = ethernetData * 11;

      sendSpots.add(FlSpot(hour, cumulativeWifi * animationValue));
      receiveSpots.add(FlSpot(hour, cumulativeEthernet * animationValue));
    }

    // Determine the max Y-axis value for scaling
    double maxYValue = (cumulativeWifi > cumulativeEthernet
        ? cumulativeWifi
        : cumulativeEthernet) * 1.5;

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
          spots: sendSpots,
          isCurved: false,
          gradient: const LinearGradient(
            colors: [Colors.cyan, Colors.lightBlueAccent],
            stops: [0.1, 0.9],
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                Colors.cyan.withOpacity(0.2),
                Colors.lightBlueAccent.withOpacity(0.1),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          dotData: const FlDotData(show: true),
          barWidth: 3,
        ),
        LineChartBarData(
          spots: receiveSpots,
          isCurved: false,
          gradient: const LinearGradient(
            colors: [Colors.green, Colors.lightGreen],
            stops: [0.1, 0.9],
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                Colors.green.withOpacity(0.2),
                Colors.lightGreen.withOpacity(0.1),
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
              final isSend = spot.bar.gradient?.colors.first == Colors.cyan;
              final label = isSend ? 'WiFi' : 'EtherNet';

              final formattedCarbonFootprint = formatCarbonFootprint(spot.y);

              return LineTooltipItem(
                '$label\nTime: ${spot.x.toInt()}h\nUsage: $formattedCarbonFootprint',
                TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: isSend ? Colors.lightBlueAccent : Colors.lightGreen,
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

String formatCarbonFootprint(double value) {
  if (value >= 1e6) {
    return '${(value / 1e6).toStringAsFixed(2)} t'; // Convert to tons
  } else if (value >= 1e3) {
    return '${(value / 1e3).toStringAsFixed(2)} kg'; // Convert to kilograms
  } else {
    return '${value.toStringAsFixed(2)} g'; // Keep in grams
  }
}
