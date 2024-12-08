import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DataFetchService {
  static const MethodChannel _methodChannel = MethodChannel('com.example.datausage/data');
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<void> fetchAndStoreCarbonFootprint() async {
    try {
      // 데이터 가져오기
      await _resetDiscountIfNewDay();

      final result = await _methodChannel.invokeMethod('getDailyDataUsage');
      final dailyUsageData = Map<String, dynamic>.from(result);

      if (dailyUsageData.isNotEmpty) {
        String latestDate = dailyUsageData.keys.last;
        String todayDate = DateTime.now().toIso8601String().split('T')[0];

        if (latestDate == todayDate) {
          double mobileReceived =
          (dailyUsageData[latestDate]['MobileReceivedMB'] ?? 0).toDouble();
          double mobileTransmitted =
          (dailyUsageData[latestDate]['MobileTransmittedMB'] ?? 0).toDouble();
          double wifiReceived =
          (dailyUsageData[latestDate]['WiFiReceivedMB'] ?? 0).toDouble();
          double wifiTransmitted =
          (dailyUsageData[latestDate]['WiFiTransmittedMB'] ?? 0).toDouble();

          double todayMobileCarbonFootprint =
              (mobileReceived + mobileTransmitted) * 11;
          double todayWifiCarbonFootprint =
              (wifiReceived + wifiTransmitted) * 8.6;
          double todayTotalCarbonFootprint =
              todayMobileCarbonFootprint + todayWifiCarbonFootprint;

          // SecureStorage에 저장
          await _secureStorage.write(
              key: 'carbonTotal',
              value: todayTotalCarbonFootprint.toString());
          print('✅ 오늘의 탄소 발자국 저장 완료: $todayTotalCarbonFootprint g');
        }
      }
    } on PlatformException catch (e) {
      print('❌ Data Fetch or Carbon Footprint Calculation Error: ${e.message}');
    }
  }

  Future<void> _resetDiscountIfNewDay() async {
    const String discountKey = 'discount';
    const String lastResetDateKey = 'lastResetDate';

    // 오늘 날짜
    String todayDate = DateTime.now().toIso8601String().split('T')[0];

    // 저장된 날짜 가져오기
    String? lastResetDate = await _secureStorage.read(key: lastResetDateKey);

    // 날짜가 다르면 discount 초기화 및 날짜 갱신
    if (lastResetDate == null || lastResetDate != todayDate) {
      await _secureStorage.write(key: discountKey, value: '0');
      await _secureStorage.write(key: lastResetDateKey, value: todayDate);
      print('✅ Discount 초기화 및 날짜 갱신 완료: $todayDate');
    } else {
      print('✅ Discount 초기화 불필요: 이미 초기화됨');
    }
  }
}
