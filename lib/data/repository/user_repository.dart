import 'dart:convert';
import 'package:flutter/services.dart';
import '../model/user_model.dart';

class UserRepository {
  Future<UserModel> getUserData() async {
    try {
      final String jsonString = await rootBundle.loadString('lib/data/user/user_data.json');
      final Map<String, dynamic> json = jsonDecode(jsonString);
      return UserModel.fromJson(json);
    } catch (e) {
      throw Exception('사용자 데이터를 불러오는데 실패했습니다: $e');
    }
  }
}
