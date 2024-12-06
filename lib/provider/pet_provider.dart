import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class Pet {
  String petName;
  final int petLevel;
  final int experience;
  final int points;

  Pet({
    required this.petName,
    required this.petLevel,
    required this.experience,
    required this.points,
  });

  // JSON에서 Pet 객체로 변환
  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      petName: json['petName'],
      petLevel: json['petLevel'],
      experience: json['experience'],
      points: json['points'],
    );
  }

  // Pet 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'petName': petName,
      'petLevel': petLevel,
      'experience': experience,
      'points': points,
    };
  }
}

class PetProvider with ChangeNotifier {
  final FlutterSecureStorage secureStorage;
  bool isInitialized = false;

  PetProvider({required this.secureStorage});

  /// **Load Pet Data from Server**
  Future<void> loadPetDataFromServer() async {
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
      final response = await http.post(
        Uri.parse('http://ecobuddy.kro.kr:4525/pet/load'),
        headers: {
          'authorization': accessToken,
          'deviceId': deviceId,
          'userId': userId,
        },
      );

      if (response.statusCode == 200) {
        print(response.statusCode);
        final responseData = jsonDecode(response.body);
        print('📄 응답 데이터: $responseData');
        // SecureStorage에 저장
        await secureStorage.write(
          key: 'newAccessToken',
          value: responseData['new_accessToken'],
        );
        await secureStorage.write(
          key: 'petData',
          value: jsonEncode(responseData['pet']),
        );

        print("✅ 펫 데이터 로드 성공 및 저장 완료");
      } else {
        print('❌ 펫 데이터 로드 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 펫 데이터 로드 중 오류 발생: $e');
    }
    isInitialized = true;
    notifyListeners();
  }

  Future<void> updatePetName(String newPetName) async {
    final accessToken = await secureStorage.read(key: 'accessToken');
    final deviceId = await secureStorage.read(key: 'deviceId');
    final userId = await secureStorage.read(key: 'userId');
    final petDataString = await secureStorage.read(key: 'petData');

    if (accessToken == null || deviceId == null || userId == null || petDataString == null) {
      print('❌ 인증 정보가 부족합니다.');
      return;
    }

    final petData = jsonDecode(petDataString);
    petData['petName'] = newPetName;

    try {
      final response = await http.post(
        Uri.parse('http://ecobuddy.kro.kr:4525/pet/save'),
        headers: {
          'authorization': accessToken,
          'deviceId': deviceId,
          'userId': userId,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(petData),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        // SecureStorage에 저장
        await secureStorage.write(
          key: 'newAccessToken',
          value: responseData['new_accessToken'],
        );
        await secureStorage.write(
          key: 'petData',
          value: jsonEncode(petData),
        );

        notifyListeners(); // UI 업데이트
        print('✅ 펫 이름 서버 동기화 및 업데이트 성공');
      } else {
        print('❌ 펫 이름 서버 업데이트 실패: ${response.statusCode}');
        print('❌ 응답 내용: ${response.body}');
      }
    } catch (e) {
      print('❌ 펫 이름 업데이트 중 오류 발생: $e');
    }
  }

  /// **Print All Secure Storage Data**
  Future<void> printAllSecureStorage() async {
    try {
      Map<String, String> allData = await secureStorage.readAll();
      print('🔍 Secure Storage 내용 출력:');
      allData.forEach((key, value) {
        print('Key: $key, Value: $value');
      });
    } catch (e) {
      print('❌ Secure Storage 데이터를 출력하는 중 오류 발생: $e');
    }
  }
}
