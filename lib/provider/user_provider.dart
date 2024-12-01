import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserProvider extends ChangeNotifier {
  Map<String, dynamic>? user;
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  Future<Map<String, String>> _buildHeaders() async {
    final authorization = await _secureStorage.read(key: 'accessToken');
    final deviceId = await _secureStorage.read(key: 'deviceId');
    final userId = await _secureStorage.read(key: 'userId');

    if (authorization == null || deviceId == null || userId == null) {
      throw Exception("Missing required headers");
    }

    return {
      'authorization': authorization,
      'deviceId': deviceId,
      'userId': userId,
      'Content-Type': 'application/json',
    };
  }

  Future<void> fetchUserData() async {
    try {
      final headers = await _buildHeaders();

      final response = await http.get(
        Uri.parse('http://223.130.162.100:4525/api/user'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        user = jsonDecode(response.body);
        notifyListeners();
      } else {
        throw Exception('Failed to load user data');
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> updateUserPoints(int points) async {
    if (user == null) return;

    try {
      final headers = await _buildHeaders();

      final response = await http.patch(
        Uri.parse('http://223.130.162.100:4525/api/user/points'),
        headers: headers,
        body: jsonEncode({'points': points}),
      );

      if (response.statusCode == 200) {
        user!['points'] = jsonDecode(response.body)['points'];
        notifyListeners();
      } else {
        throw Exception('Failed to update points');
      }
    } catch (e) {
      print('Error updating points: $e');
    }
  }

  Future<void> updateUserName(String newName) async {
    if (user == null) return;

    try {
      final headers = await _buildHeaders();

      final response = await http.patch(
        Uri.parse('http://223.130.162.100:4525/api/user/name'),
        headers: headers,
        body: jsonEncode({'name': newName}),
      );

      if (response.statusCode == 200) {
        user!['nickname'] = jsonDecode(response.body)['nickname'];
        notifyListeners();
      } else {
        throw Exception('Failed to update name');
      }
    } catch (e) {
      print('Error updating name: $e');
    }
  }

  Future<void> loadPetData() async {
    try {
      final headers = await _buildHeaders();

      final response = await http.post(
        Uri.parse('http://223.130.162.100:4525/pet/load'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Pet Name: ${data['petName']}");
        print("New Access Token: ${data['new_accessToken']}");

        // Update secure storage with new access token if provided
        if (data.containsKey('new_accessToken')) {
          await _secureStorage.write(key: 'accessToken', value: data['new_accessToken']);
        }

        notifyListeners();
      } else if (response.statusCode == 400) {
        print("Bad Request: Missing userId or token.");
      } else if (response.statusCode == 401) {
        print("Unauthorized: Invalid access token.");
      } else if (response.statusCode == 500) {
        print("Internal Server Error.");
      } else {
        throw Exception('Failed to load pet data');
      }
    } catch (e) {
      print('Error loading pet data: $e');
    }
  }
}
