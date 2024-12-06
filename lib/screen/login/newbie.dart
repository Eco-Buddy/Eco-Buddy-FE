import 'dart:convert'; // For jsonEncode
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http; // For HTTP requests

class NewbiePage extends StatefulWidget {
  @override
  _NewbiePageState createState() => _NewbiePageState();
}

class _NewbiePageState extends State<NewbiePage> {
  final _petNameController = TextEditingController();
  final _secureStorage = FlutterSecureStorage();

  Future<void> _createPet() async {
    final petName = _petNameController.text;

    if (petName.isEmpty) {
      print('❌ 펫 이름을 입력해주세요.');
      return;
    }

    // Retrieve access token and other required headers from secure storage
    final accessToken = await _secureStorage.read(key: 'accessToken');
    final deviceId = await _secureStorage.read(key: 'deviceId');
    final userId = await _secureStorage.read(key: 'userId');

    if (accessToken == null || deviceId == null || userId == null) {
      print('❌ 인증 정보가 부족합니다.');
      return;
    }

    try {
      // Send POST request to create the pet
      final response = await http.post(
        Uri.parse('http://ecobuddy.kro.kr:4525/pet/create?petName=$petName'),
        headers: {
          'authorization': accessToken,
          'deviceId': deviceId,
          'userId': userId,
        },
      );

      if (response.statusCode == 200) {
        // Parse response and save the new access token
        final responseData = jsonDecode(response.body);
        if (responseData['new_accessToken'] != null) {
          await _secureStorage.write(
            key: 'accessToken',
            value: responseData['new_accessToken'],
          );
          print('✅ 새로운 펫 생성 성공 및 액세스 토큰 업데이트 완료!');

          Navigator.pushReplacementNamed(context, '/main');
        } else {
          print('⚠️ 새로운 액세스 토큰이 응답에 없습니다.');
        }
      } else {
        print('❌ 펫 생성 실패: ${response.statusCode}');
        print('❌ 응답 내용: ${response.body}');
      }
    } catch (e) {
      print('❌ 펫 생성 중 오류 발생: $e');
    }
  }

  Future<void> _savePetName() async {
    final petName = _petNameController.text;
    if (petName.isNotEmpty) {
      await _secureStorage.write(key: 'petName', value: petName);

      print('✅ 펫 이름 저장 완료: $petName');
      Navigator.pushReplacementNamed(context, '/main');
    } else {
      print('❌ 펫 이름을 입력해주세요.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('신규 회원 설정')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '환영합니다! 먼저 펫의 이름을 설정해주세요.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _petNameController,
              decoration: const InputDecoration(
                labelText: '펫 이름',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _savePetName,
              child: const Text('저장하고 시작하기'),
            ),
          ],
        ),
      ),
    );
  }
}
