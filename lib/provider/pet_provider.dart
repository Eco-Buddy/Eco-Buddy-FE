import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class PetProvider with ChangeNotifier {
  final FlutterSecureStorage secureStorage;
  Map<String, dynamic>? _pet;
  bool isInitialized = false;

  // 생성자
  PetProvider({required this.secureStorage});

  // 펫 데이터 접근자
  Map<String, dynamic>? get pet => _pet;

  // 로컬 데이터를 SecureStorage에서 로드
  Future<void> loadLocalData() async {
    final petData = await secureStorage.read(key: 'petData');
    if (petData != null) {
      _pet = jsonDecode(petData);
      print('✅ 로컬 펫 데이터 로드 성공: $_pet');
    } else {
      print('⚠️ 로컬 펫 데이터가 없습니다.');
    }
    isInitialized = true;
    notifyListeners();
  }

  // 서버에서 펫 데이터를 가져와 SecureStorage에 저장
  Future<void> fetchPetData() async {
    final accessToken = await secureStorage.read(key: 'accessToken');
    final deviceId = await secureStorage.read(key: 'deviceId');
    final userId = await secureStorage.read(key: 'userId');

    if (accessToken == null || deviceId == null || userId == null) {
      print('❌ PetProvider: 인증 정보가 없습니다.');
      isInitialized = true;
      notifyListeners();
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://ecobuddy.kro.kr:4525/pet/load'),
        headers: {
          'authorization': accessToken,
          'deviceId': deviceId,
          'userId': userId,
        },
      );

      if (response.statusCode == 200) {
        _pet = jsonDecode(response.body);

        // 데이터를 SecureStorage에 저장
        await secureStorage.write(
          key: 'petData',
          value: jsonEncode(_pet),
        );

        print('✅ 펫 데이터 로드 성공 및 저장 완료: $_pet');
      } else {
        print('❌ 펫 데이터 로드 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 펫 데이터 로드 중 오류 발생: $e');
    }

    isInitialized = true;
    notifyListeners();
  }

  // 포인트 업데이트
  Future<void> updatePoints(int points) async {
    if (_pet == null) return;

    final accessToken = await secureStorage.read(key: 'accessToken');
    final userId = await secureStorage.read(key: 'userId');

    if (accessToken == null || userId == null) {
      print('❌ PetProvider: 인증 정보가 부족합니다.');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://ecobuddy.kro.kr:4525/pet/update-points'),
        headers: {
          'Content-Type': 'application/json',
          'authorization': accessToken,
          'userId': userId,
        },
        body: jsonEncode({'points': points}),
      );

      if (response.statusCode == 200) {
        _pet?['points'] = (_pet?['points'] ?? 0) + points;

        // 업데이트된 데이터도 SecureStorage에 저장
        await secureStorage.write(
          key: 'petData',
          value: jsonEncode(_pet),
        );

        notifyListeners();
        print('✅ 포인트 업데이트 성공 및 저장 완료: 현재 포인트 = ${_pet?['points']}');
      } else {
        print('❌ 포인트 업데이트 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 포인트 업데이트 중 오류 발생: $e');
    }
  }
}
