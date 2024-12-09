import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenManager {
  static final _secureStorage = FlutterSecureStorage();

  /// Update userId, accessToken, and deviceId in SharedPreferences
  static Future<void> updateCredentials() async {
    if (!Platform.isAndroid) {
      print("TokenManager runs only on Android.");
      return;
    }
    try {
      final accessToken = await _secureStorage.read(key: 'accessToken');
      final userId = await _secureStorage.read(key: 'userId');
      final deviceId = await _secureStorage.read(key: 'deviceId');

      if (accessToken != null && userId != null && deviceId != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('accessToken', accessToken);
        await prefs.setString('userId', userId);
        await prefs.setString('deviceId', deviceId);
        print("새토큰 저장 성공");
      } else {
        print("Failed to retrieve some or all credentials from secure storage.");
      }
    } catch (e) {
      print("Error updating credentials in SharedPreferences: ${e.toString()}");
    }
  }

  static Future<String?> getAccessToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');

      return accessToken;
    } catch (e) {
      print("Error retrieving access token: ${e.toString()}");
      return null;
    }
  }
}
