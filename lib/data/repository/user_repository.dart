import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../model/user_model.dart';

class UserRepository {
  final String _userKey = 'user_data';
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // 사용자 데이터를 로드
  Future<UserModel> getUserData() async {
    final storedUserData = await _secureStorage.read(key: _userKey);

    if (storedUserData != null) {
      // 저장된 데이터를 로드
      final Map<String, dynamic> json = jsonDecode(storedUserData);
      return UserModel.fromJson(json);
    } else {
      // 초기 데이터를 반환
      final Map<String, dynamic> defaultData = {
        "nickname": "사용자123",
        "level": 10,
        "title": "환경지킴이",
        "profile_image": "assets/images/profile/default.png",
        "points": 0, // 초기 포인트 값
      };
      return UserModel.fromJson(defaultData);
    }
  }

  // 사용자 포인트 업데이트
  Future<void> updateUserPoints(int points) async {
    final user = await getUserData();
    user.points += points; // 포인트 증가

    // 업데이트된 데이터를 JSON으로 저장
    final updatedUserData = user.toJson();
    await _secureStorage.write(key: _userKey, value: jsonEncode(updatedUserData));

    print('포인트가 $points만큼 증가했습니다. 현재 포인트: ${user.points}');
  }

  // 사용자 이름 업데이트
  Future<void> updateUserName(String newName) async {
    final user = await getUserData();
    user.nickname = newName; // 이름 변경

    // 업데이트된 데이터를 JSON으로 저장
    final updatedUserData = user.toJson();
    await _secureStorage.write(key: _userKey, value: jsonEncode(updatedUserData));

    print('사용자 이름이 $newName(으)로 변경되었습니다.');
  }
}
