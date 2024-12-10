import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../screen/stats/kotlin_tokenmanager.dart';

class Pet {
  String petName;
  int petLevel;
  int experience;
  int points;
  int background;
  int floor;
  int mission;

  Pet({
    required this.petName,
    required this.petLevel,
    required this.experience,
    required this.points,
    required this.background,
    required this.floor,
    required this.mission,
  });

  // JSON에서 Pet 객체로 변환
  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      petName: json['petName'],
      petLevel: json['petLevel'],
      experience: json['experience'],
      points: json['points'],
      background: json['background'],
      floor: json['floor'],
      mission: json['mission'],
    );
  }

  // Pet 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'petName': petName,
      'petLevel': petLevel,
      'experience': experience,
      'points': points,
      'background': background,
      'floor': floor,
      'mission': mission,
    };
  }

  // toString() 메서드 오버라이드
  @override
  String toString() {
    return 'Pet(petName: $petName, petLevel: $petLevel, experience: $experience, points: $points, background: $background, floor: $floor, mission: $mission)';
  }
}

class PetProvider with ChangeNotifier {
  final FlutterSecureStorage secureStorage;
  final BuildContext context;
  bool isInitialized = false;
  Pet _pet = Pet(
    petName: 'Default Pet',
    petLevel: 1,
    experience: 0,
    points: 0,
    background: 1001,
    floor: 2001,
    mission: 0,
  );
  Pet get pet => _pet;


  PetProvider({required this.secureStorage, required this.context}) {
    // 기본값 설정
    _pet = Pet(
      petName: 'Default Pet',
      petLevel: 1,
      experience: 0,
      points: 0,
      background: 1001,
      floor: 2001,
      mission: 0,
    );
  }

  String get petName => _pet.petName;
  int get petPoints => _pet.points;
  int get petLevel => _pet.petLevel;

  void setPet(Pet pet) {
    _pet = pet;
    notifyListeners();
  }



  Future<void> handleUnauthorizedError() async {
    // 알림 창 띄우기
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('로그인 세션 만료'),
          content: const Text('로그인 세션이 만료되어 시작 화면으로 돌아갑니다.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 알림 창 닫기
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );

    // Secure Storage 초기화
    await deleteExceptSpecificKeys();
    print('✅ Secure Storage 초기화 완료');

    // StartPage로 이동
    Navigator.pushNamedAndRemoveUntil(context, '/start', (route) => false);
  }

  Future<void> deleteExceptSpecificKeys() async {
    final FlutterSecureStorage secureStorage = FlutterSecureStorage();
    try {
      // 모든 키-값 쌍을 가져옵니다.
      Map<String, String> allData = await secureStorage.readAll();
      // 제외할 키 목록
      List<String> keysToKeep = ['carbonTotal', 'discount', 'lastMissionTime'];
      // 제외할 키 목록에 포함되지 않는 항목들을 삭제
      for (var key in allData.keys) {
        if (!keysToKeep.contains(key)) {
          await secureStorage.delete(key: key);
          print('삭제된 키: $key');
        }
      }
      print("특정 키를 제외한 모든 데이터를 삭제했습니다.");
    } catch (e) {
      print("데이터 삭제 중 오류 발생: $e");
    }
  }

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
      _pet = Pet(
        petName: 'Default Pet',
        petLevel: 1,
        experience: 0,
        points: 0,
        background: 1001,
        floor: 2001,
        mission: 0,
      ); // 기본값 설정
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
        print(responseData);
        // SecureStorage에 저장
        await secureStorage.write(
          key: 'accessToken',
          value: responseData['new_accessToken'],
        );
        await secureStorage.write(
          key: 'petData',
          value: jsonEncode(responseData['pet']),
        );

        // 코틀린 문제 해결
        await TokenManager.updateCredentials();

        _pet = Pet.fromJson(responseData['pet']);
        print("✅ 펫 데이터 로드 성공 및 저장 완료");
        print('🐾 Loaded pet data: $_pet');

      }
      else if (response.statusCode == 401) {
        // 인증 오류 발생 시 처리
        if(Platform.isAndroid){
          print('🔑 401 Android 재시도');
          // 코틀린 동기화 문제 해결
          await _retryWithUpdatedToken();
        }
        else if(Platform.isWindows){
          await handleUnauthorizedError();
        }
      } else {
        print('❌ 펫 데이터 로드 실패: ${response.statusCode}');
        // 알림창 띄우기
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('펫 데이터 로드 실패'),
              content: Text('펫 데이터가 존재하지 않아 로그인 화면으로 이동합니다.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // 알림창 닫기
                    Navigator.pushReplacementNamed(context, '/login'); // 로그인 화면으로 이동
                  },
                  child: Text('확인'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print('❌ 펫 데이터 로드 중 오류 발생: $e');
      _pet = Pet(
        petName: 'Default Pet',
        petLevel: 1,
        experience: 0,
        points: 0,
        background: 1001,
        floor: 2001,
        mission: 0,
      ); // 기본값 설정
    }
    isInitialized = true;
    print('notify 호출');
    print('펫 데이터: $_pet');
    print('펫 이름: ${_pet.petName}, 포인트: ${_pet.points}');
    notifyListeners();
  }

  Future<void> _retryWithUpdatedToken() async {
    try {
      final newAccessToken = await TokenManager.getAccessToken();
      if (newAccessToken != null) {
        await secureStorage.write(key: 'accessToken', value: newAccessToken);
        final retryResponse = await http.post(
          Uri.parse('http://ecobuddy.kro.kr:4525/pet/load'),
          headers: {
            'authorization': newAccessToken,
            'deviceId': await secureStorage.read(key: 'deviceId') ?? '',
            'userId': await secureStorage.read(key: 'userId') ?? '',
          },
        );

        if (retryResponse.statusCode == 200) {
          final responseData = jsonDecode(retryResponse.body);
          print(responseData);
          // SecureStorage에 저장
          await secureStorage.write(
            key: 'accessToken',
            value: responseData['new_accessToken'],
          );
          await secureStorage.write(
            key: 'petData',
            value: jsonEncode(responseData['pet']),
          );

          // 코틀린 문제 해결
          await TokenManager.updateCredentials();

          _pet = Pet.fromJson(responseData['pet']);
          print("✅ 펫 데이터 로드 성공 및 저장 완료");
          print('🐾 Loaded pet data: $_pet');
        } else {
          print('❌ 재시도 실패 : ${retryResponse.statusCode}');
          await handleUnauthorizedError();
        }
      } else {
        print('❌ 재시도 실패');
        await handleUnauthorizedError();
      }
    } catch (e) {
      print('❌ 펫 데이터 로드 중 오류 발생 : $e');
      _pet = Pet(
        petName: 'Default Pet',
        petLevel: 1,
        experience: 0,
        points: 0,
        background: 1001,
        floor: 2001,
        mission: 0,
      );
    }
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
          key: 'accessToken',
          value: responseData['new_accessToken'],
        );
        await secureStorage.write(
          key: 'petData',
          value: jsonEncode(petData),
        );

        // 코틀린 문제 해결
        await TokenManager.updateCredentials();

        _pet.points = newPoints;
        print('✅ 포인트 서버 동기화 및 업데이트 성공 $newPoints');
        notifyListeners(); // UI 업데이트

      }
      else if (response.statusCode == 401) {
        // 인증 오류 발생 시 처리
        await handleUnauthorizedError();
      } else {
        print('❌ 포인트 서버 업데이트 실패: ${response.statusCode}');
        print('❌ 응답 내용: ${response.body}');
      }
    } catch (e) {
      print('❌ 포인트 업데이트 중 오류 발생: $e');
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
          key: 'accessToken',
          value: responseData['new_accessToken'],
        );
        await secureStorage.write(
          key: 'petData',
          value: jsonEncode(petData),
        );

        // 코틀린 문제 해결
        await TokenManager.updateCredentials();

        _pet.petName = newPetName;
        notifyListeners(); // UI 업데이트
        print('✅ 펫 이름 서버 동기화 및 업데이트 성공');
      }
      else if (response.statusCode == 401) {
        // 인증 오류 발생 시 처리
        await handleUnauthorizedError();
      }  else {
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
      //await handleUnauthorizedError();
    } catch (e) {
      print('❌ Secure Storage 데이터를 출력하는 중 오류 발생: $e');
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

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        // SecureStorage에 저장
        await secureStorage.write(
          key: 'accessToken',
          value: responseData['new_accessToken'],
        );

        // 코틀린 문제 해결
        await TokenManager.updateCredentials();

        return responseData;
      } else if (response.statusCode == 401) {
        // 인증 오류 발생 시 처리
        await handleUnauthorizedError(); // 비동기 함수 처리
        return {}; // 인증 오류가 발생했을 때 빈 맵 반환
      } else {
        throw Exception('Failed to fetch items. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching items: $e');
    }
  }


  Future<bool> purchaseItem(int itemId) async {
    final accessToken = await secureStorage.read(key: 'accessToken') ?? '';
    final deviceId = await secureStorage.read(key: 'deviceId') ?? '';
    final userId = await secureStorage.read(key: 'userId') ?? '';

    if (accessToken.isEmpty || deviceId.isEmpty || userId.isEmpty) {
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

    if (response.statusCode == 401) {
    // 인증 오류 발생 시 처리
      await handleUnauthorizedError();
    }

    final responseData = jsonDecode(response.body);

    // SecureStorage에 저장
    await secureStorage.write(
      key: 'accessToken',
      value: responseData['new_accessToken'],
    );

    // 코틀린 문제 해결
    await TokenManager.updateCredentials();

    return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<void> updateBackgroundAndFloor(int backgroundId, int floorId) async {
    final petDataString = await secureStorage.read(key: 'petData');
    if (petDataString == null) return;

    final petData = jsonDecode(petDataString);
    petData['background'] = backgroundId;
    petData['floor'] = floorId;
    print('결정:$petData');
    await secureStorage.write(key: 'petData', value: jsonEncode(petData));
    final accessToken = await secureStorage.read(key: 'accessToken') ?? '';
    final deviceId = await secureStorage.read(key: 'deviceId') ?? '';
    final userId = await secureStorage.read(key: 'userId') ?? '';
    try {
      await http.post(
        Uri.parse('http://ecobuddy.kro.kr:4525/pet/save'),
        headers: {
          'authorization': accessToken,
          'deviceId': deviceId,
          'userId': userId,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(petData),
      );
      notifyListeners();
    } catch (e) {
      print('Error updating background and floor: $e');
    }
  }
}