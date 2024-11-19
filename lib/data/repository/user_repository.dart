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
      // 초기 데이터를 반환 (JSON 파일 로드 대신 기본 데이터로 시작)
      final Map<String, dynamic> defaultData = {
        "nickname": "사용자123",
        "level": 10,
        "title": "환경지킴이",
        "profile_image": "assets/images/profile/default.png"
      };
      return UserModel.fromJson(defaultData);
    }
  }

  // 사용자 이름 업데이트
  Future<void> updateUserName(String newName) async {
    final userData = await getUserData();
    final updatedUserData = userData.toJson();
    updatedUserData['nickname'] = newName;

    // 보안 저장소에 저장
    await _secureStorage.write(key: _userKey, value: jsonEncode(updatedUserData));

    print('사용자 이름이 $newName(으)로 변경되었습니다.');
  }
}
