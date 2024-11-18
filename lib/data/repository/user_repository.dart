import 'dart:convert';
import 'package:flutter/services.dart';
import '../model/user_model.dart';

class UserRepository {
  // 사용자 정보를 JSON에서 읽어오는 메서드
  Future<UserModel> getUserData() async {
    final String jsonString = await rootBundle.loadString('assets/data/user/user_data.json');
    final Map<String, dynamic> json = jsonDecode(jsonString);
    return UserModel.fromJson(json);
  }
}
