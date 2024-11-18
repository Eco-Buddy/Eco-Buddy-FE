import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({Key? key}) : super(key: key);

  Future<Map<String, dynamic>> _loadStatsData() async {
    try {
      final String jsonString =
      await rootBundle.loadString('assets/data/stats_data.json');
      return json.decode(jsonString);
    } catch (e) {
      return {
        "wifi_data": 0,
        "mobile_data": 0,
        "time_usage": [],
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadStatsData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Text('통계 데이터를 불러오는데 실패했습니다.'));
        }

        final stats = snapshot.data!;
        final timeUsage = (stats['time_usage'] as List<dynamic>).map((item) {
          return {
            "time": item['time'] ?? "00:00",
            "data_used": item['data_used'] ?? 0.0,
          };
        }).toList() as List<Map<String, dynamic>>;

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildDataOverview(stats),
            const SizedBox(height: 16.0),
            const Text(
              '시간대별 데이터 사용량',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16.0),
            _buildUsageGraph(timeUsage),
            const SizedBox(height: 16.0),
            const Text(
              '시간대별 세부 정보',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ...timeUsage.map<Widget>((item) {
              return ListTile(
                leading: const Icon(Icons.access_time),
                title: Text('시간: ${item['time']}'),
                subtitle: Text('사용량: ${item['data_used']} GB'),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildDataOverview(Map<String, dynamic> stats) {
    return Card(
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '총 데이터 사용량',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            Text('Wi-Fi 데이터: ${stats['wifi_data']} GB'),
            Text('모바일 데이터: ${stats['mobile_data']} GB'),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageGraph(List<Map<String, dynamic>> timeUsage) {
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text('${value.toInt()} GB');
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text('${value.toInt()}시');
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            border: const Border(
              top: BorderSide.none,
              right: BorderSide.none,
              bottom: BorderSide(width: 1),
              left: BorderSide(width: 1),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              spots: timeUsage
                  .map<FlSpot>((item) => FlSpot(
                double.parse(item['time'].split(':')[0]),
                item['data_used'] as double,
              ))
                  .toList(),
              color: Colors.green,
              barWidth: 4,
              isStrokeCapRound: true,
            ),
          ],
        ),
      ),
    );
  }
}
