import 'package:flutter/material.dart';
import '../../data/repository/user_repository.dart';
import '../../data/model/user_model.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user; // 사용자 데이터
  final UserRepository _userRepository = UserRepository();

  UserModel? get user => _user; // 사용자 데이터를 외부에서 읽기

  // 사용자 데이터 로드
  Future<void> loadUser() async {
    try {
      _user = await _userRepository.getUserData();
      notifyListeners(); // 데이터 로드 후 상태 변경 알림
    } catch (e) {
      print('Failed to load user data: $e');
    }
  }

  // 사용자 이름 업데이트
  Future<void> updateUserName(String newName) async {
    if (_user == null) return;
    await _userRepository.updateUserName(newName); // Repository를 통해 이름 변경
    _user!.nickname = newName; // 사용자 데이터 업데이트
    notifyListeners(); // 상태 변경 알림
  }

  // 포인트 업데이트
  Future<void> updateUserPoints(int points) async {
    if (_user == null) return;
    _user!.points += points; // 로컬 상태 업데이트
    await _userRepository.updateUserPoints(points); // Repository 업데이트
    notifyListeners(); // 상태 변경 알림
  }
}
