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
  Pet? _pet;
  bool isInitialized = false;

  PetProvider({required this.secureStorage});

  Pet? get pet => _pet;

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
        final responseData = jsonDecode(response.body);

        _pet = Pet.fromJson(responseData);

        // SecureStorage에 저장
        await secureStorage.write(
          key: 'petData',
          value: jsonEncode(_pet!.toJson()),
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
  Future<void> updatePetName(String newPetName) async {
    if (_pet == null) {
      print('❌ PetProvider: 업데이트할 펫 데이터가 없습니다.');
      return;
    }
    final accessToken = await secureStorage.read(key: 'accessToken');
    final deviceId = await secureStorage.read(key: 'deviceId');
    final userId = await secureStorage.read(key: 'userId');

    if (accessToken == null || deviceId == null || userId == null) {
      print('❌ 인증 정보가 부족합니다.');
      return;
    }
    // 변경된 이름을 반영한 로컬 데이터 업데이트
    _pet = Pet(
      petName: newPetName,
      petLevel: _pet!.petLevel,
      experience: _pet!.experience,
      points: _pet!.points,
    );
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('http://ecobuddy.kro.kr:4525/pet/save'),
        headers: {
          'authorization': accessToken,
          'deviceId': deviceId,
          'userId': userId,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(_pet!.toJson()),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        // 서버에서 최신 데이터 동기화
        _pet = Pet.fromJson(responseData['pet']);
        await updateLocalPetData(_pet!); // 로컬 스토리지 업데이트
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

  /// **Save Modified Pet Data to Server**
  Future<void> savePetDataToServer() async {
    if (_pet == null) {
      print('❌ PetProvider: 저장할 펫 데이터가 없습니다.');
      return;
    }

    final accessToken = await secureStorage.read(key: 'accessToken');
    final deviceId = await secureStorage.read(key: 'deviceId');
    final userId = await secureStorage.read(key: 'userId');

    if (accessToken == null || deviceId == null || userId == null) {
      print('❌ PetProvider: 인증 정보가 부족합니다.');
      return;
    }

    try {
      // 헤더 생성
      final headers = {
        'authorization': accessToken,
        'deviceId': deviceId,
        'userId': userId,
        'Content-Type': 'application/json', // Content-Type 추가
      };

      // 바디 생성
      final body = jsonEncode({
        'pet': _pet!.toJson(), // 서버가 기대하는 구조에 맞게 수정
      });

      // 중간 점검: 헤더와 바디 출력
      print('📝 HTTP 요청 헤더: $headers');
      print('📝 HTTP 요청 바디: $body');

      // HTTP 요청 보내기
      final response = await http.post(
        Uri.parse('http://223.130.162.100:4525/pet/save'),
        headers: headers,
        body: body,
      );

      // 응답 데이터 처리
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData is Map<String, dynamic>) {
          // 새로운 AccessToken 저장
          if (responseData.containsKey('new_accessToken')) {
            await secureStorage.write(
              key: 'accessToken',
              value: responseData['new_accessToken'],
            );
          }

          await updateLocalPetData(_pet!);
          print('✅ 펫 데이터 서버 저장 성공: 새로운 AccessToken 저장 완료');
        } else {
          print('⚠️ 서버 응답 데이터가 예상된 형식이 아닙니다.');
        }
      } else {
        print('❌ 펫 데이터 서버 저장 실패: ${response.statusCode}');
        print('❌ 서버 응답 메시지: ${response.body}');
      }
    } catch (e) {
      print('❌ 펫 데이터 서버 저장 중 오류 발생: $e');
    }
  }

  /// **Update Local Pet Data**
  Future<void> updateLocalPetData(Pet updatedPet) async {
    _pet = updatedPet;

    // SecureStorage에 저장
    await secureStorage.write(
      key: 'petData',
      value: jsonEncode(updatedPet.toJson()),
    );

    notifyListeners();
    print('✅ 로컬 펫 데이터 업데이트 완료: $_pet');
  }

  /// **Load Local Pet Data from SecureStorage**
  Future<void> loadLocalPetData() async {
    final petData = await secureStorage.read(key: 'petData');

    if (petData != null) {
      _pet = Pet.fromJson(jsonDecode(petData));
      print('✅ 로컬 펫 데이터 로드 성공: $_pet');
    } else {
      print('⚠️ 로컬 펫 데이터가 없습니다.');
    }

    isInitialized = true;
    notifyListeners();
  }
}
