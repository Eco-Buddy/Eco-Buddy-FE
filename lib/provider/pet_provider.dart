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
  List<Map<String, dynamic>> items = []; // 아이템 데이터 관리 변수
  PetProvider({required this.secureStorage});

  Future<int> getCurrentBackgroundId() async {
    final petDataString = await secureStorage.read(key: 'petData');
    if (petDataString != null) {
      final petData = jsonDecode(petDataString);
      return petData['background'];
    }
    return 1001; // 기본값
  }

  Future<int> getCurrentFloorId() async {
    final petDataString = await secureStorage.read(key: 'petData');
    if (petDataString != null) {
      final petData = jsonDecode(petDataString);
      return petData['floor'];
    }
    return 2001; // 기본값
  }

  /// **Load Pet Data from Server**
  Future<void> loadPetDataFromServer() async {
    final accessToken = await secureStorage.read(key: 'accessToken') ?? '';
    final deviceId = await secureStorage.read(key: 'deviceId') ?? '';
    final userId = await secureStorage.read(key: 'userId') ?? '';

    if (accessToken.isEmpty || deviceId.isEmpty || userId.isEmpty) {
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
        print('❌ 응답 내용: ${response.body}'); // 실패 원인 출력
      }
    } catch (e) {
      print('❌ 펫 데이터 로드 중 오류 발생: $e');
    }
    isInitialized = true;
    notifyListeners();
  }

  Future<void> updatePetPoints(int newPoints) async {
    final accessToken = await secureStorage.read(key: 'accessToken') ?? '';
    final deviceId = await secureStorage.read(key: 'deviceId') ?? '';
    final userId = await secureStorage.read(key: 'userId') ?? '';
    final petDataString = await secureStorage.read(key: 'petData');

    if (accessToken.isEmpty || deviceId.isEmpty || userId.isEmpty || petDataString == null) {
      print('❌ 인증 정보가 부족합니다.');
      return;
    }

    final petData = jsonDecode(petDataString);
    petData['points'] = newPoints;

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
        print('✅ 포인트 서버 동기화 및 업데이트 성공');
      } else {
        print('❌ 포인트 서버 업데이트 실패: ${response.statusCode}');
        print('❌ 응답 내용: ${response.body}');
      }
    } catch (e) {
      print('❌ 포인트 업데이트 중 오류 발생: $e');
    }
  }

  Future<Map<String, dynamic>> fetchItemsByRange(int range) async {
    final accessToken = await secureStorage.read(key: 'accessToken') ?? '';
    final deviceId = await secureStorage.read(key: 'deviceId') ?? '';
    final userId = await secureStorage.read(key: 'userId') ?? '';

    if (accessToken.isEmpty || deviceId.isEmpty || userId.isEmpty) {
      throw Exception('❌ 인증 정보가 부족합니다.');
    }

    try {
      final response = await http.post(
        Uri.parse('http://ecobuddy.kro.kr:4525/item/load?range=$range'),
        headers: {
          'authorization': accessToken,
          'deviceId': deviceId,
          'userId': userId,
        },
      );

      print('Status Code: ${response.statusCode}');
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // 새로운 액세스 토큰 저장
        if (responseData['new_accessToken'] != null) {
          await secureStorage.write(
            key: 'newAccessToken',
            value: responseData['new_accessToken'],
          );
        }

        // 반환값 반환
        return responseData; // 아이템 데이터 반환
      } else {
        print('Response Body: ${response.body}'); // 오류 발생 시 응답 내용 출력
        throw Exception('Failed to fetch items. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching items: $e');
      throw Exception('Error fetching items: $e');
    }
  }

  Future<bool> purchaseItem(int itemId) async {
    final accessToken = await secureStorage.read(key: 'accessToken') ?? '';
    final deviceId = await secureStorage.read(key: 'deviceId') ?? '';
    final userId = await secureStorage.read(key: 'userId') ?? '';

    if (accessToken.isEmpty || deviceId.isEmpty || userId.isEmpty) {
      print('❌ 인증 정보가 부족합니다.');
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('http://ecobuddy.kro.kr:4525/item/save?item_id=$itemId'),
        headers: {
          'authorization': accessToken,
          'deviceId': deviceId,
          'userId': userId,
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // 새로운 액세스 토큰 저장
        if (responseData['new_accessToken'] != null) {
          await secureStorage.write(
            key: 'newAccessToken',
            value: responseData['new_accessToken'],
          );
        }

        print('✅ 아이템 구매 성공: 아이템 ID $itemId');
        return true;
      } else {
        print('❌ 아이템 구매 실패: ${response.statusCode}');
        print('❌ 응답 내용: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ 아이템 구매 중 오류 발생: $e');
      return false;
    }
  }

  Future<void> updateBackgroundAndFloor(int backgroundId, int floorId) async {
    final accessToken = await secureStorage.read(key: 'accessToken') ?? '';
    final deviceId = await secureStorage.read(key: 'deviceId') ?? '';
    final userId = await secureStorage.read(key: 'userId') ?? '';
    final petDataString = await secureStorage.read(key: 'petData');

    if (accessToken.isEmpty || deviceId.isEmpty || userId.isEmpty || petDataString == null) {
      print('❌ 인증 정보가 부족합니다.');
      return;
    }

    final petData = jsonDecode(petDataString);
    petData['background'] = backgroundId;
    petData['floor'] = floorId;

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
        print('✅ 배경 및 바닥 서버 동기화 및 업데이트 성공');
      } else {
        print('❌ 배경 및 바닥 업데이트 실패: ${response.statusCode}');
        print('❌ 응답 내용: ${response.body}');
      }
    } catch (e) {
      print('❌ 배경 및 바닥 업데이트 중 오류 발생: $e');
    }
  }

  Future<void> updatePetName(String newPetName) async {
    final accessToken = await secureStorage.read(key: 'accessToken') ?? '';
    final deviceId = await secureStorage.read(key: 'deviceId') ?? '';
    final userId = await secureStorage.read(key: 'userId') ?? '';
    final petDataString = await secureStorage.read(key: 'petData');

    if (accessToken.isEmpty || deviceId.isEmpty || userId.isEmpty || petDataString == null) {
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
