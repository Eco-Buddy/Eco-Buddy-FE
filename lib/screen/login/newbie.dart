import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NewbiePage extends StatefulWidget {
  @override
  _NewbiePageState createState() => _NewbiePageState();
}

class _NewbiePageState extends State<NewbiePage> {
  final _petNameController = TextEditingController();
  final _secureStorage = FlutterSecureStorage();
  final String serverUrl = 'http://223.130.162.100:4525/pet/create'; // 서버 URL

  Future<void> _savePetName() async {
    final petName = _petNameController.text;

    if (petName.isNotEmpty) {
      final accessToken = await _secureStorage.read(key: 'accessToken');
      final deviceId = await _secureStorage.read(key: 'deviceId');
      final userId = await _secureStorage.read(key: 'userId');

      if (accessToken == null || deviceId == null || userId == null) {
        print('❌ 인증 정보가 없습니다.');
        return;
      }

      final headers = {
        'authorization': accessToken,
        'deviceId': deviceId,
        'userId': userId,
      };

      final body = {
        'petName': petName,
      };

      print('📝 요청 헤더: $headers');
      print('📝 요청 본문: $body');

      try {
        final response = await http.post(
          Uri.parse('http://223.130.162.100:4525/pet/create'),
          headers: headers,
          body: body,
        );

        if (response.statusCode == 200) {
          print('✅ 서버에 펫 정보 저장 성공: $petName');
          await _secureStorage.write(key: 'petName', value: petName);
          Navigator.pushReplacementNamed(context, '/main');
        } else {
          print('❌ 서버에 펫 정보 저장 실패: ${response.statusCode}');
          print('❌ 응답 내용: ${response.body}');
        }
      } catch (e) {
        print('❌ 요청 중 오류 발생: $e');
      }
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
