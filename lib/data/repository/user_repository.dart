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
      print('Error loading user data: $e');
      throw Exception('Failed to load user data');
    }
  }
}
