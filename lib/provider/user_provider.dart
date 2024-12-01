import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserProvider extends ChangeNotifier {
  Map<String, dynamic>? user;

  Future<void> fetchUserData() async {
    try {
      final response = await http.get(Uri.parse('http://223.130.162.100:4525/api/user'));
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
      final response = await http.patch(
        Uri.parse('http://223.130.162.100:4525/api/user/points'),
        body: jsonEncode({'points': points}),
        headers: {'Content-Type': 'application/json'},
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
      final response = await http.patch(
        Uri.parse('http://223.130.162.100:4525/api/user/name'),
        body: jsonEncode({'name': newName}),
        headers: {'Content-Type': 'application/json'},
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
}
