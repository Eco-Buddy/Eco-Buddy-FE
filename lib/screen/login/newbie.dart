import 'dart:convert'; // For jsonEncode
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../stats/kotlin_tokenmanager.dart'; // For HTTP requests

class NewbiePage extends StatefulWidget {
  @override
  _NewbiePageState createState() => _NewbiePageState();
}

class _NewbiePageState extends State<NewbiePage> {
  final _petNameController = TextEditingController();
  final _secureStorage = FlutterSecureStorage();
  String? _errorMessage;
  bool _isNameEntered = false;

  @override
  void initState() {
    super.initState();
    _petNameController.addListener(() {
      setState(() {
        _isNameEntered = _petNameController.text.trim().isNotEmpty;
      });
    });
  }

  bool _containsSpecialCharacters(String input) {
    final RegExp specialCharRegex = RegExp(r'[!@#\$%^&*(),.?":{}|<>]');
    return specialCharRegex.hasMatch(input);
  }

  Future<void> _createPet() async {
    final petName = _petNameController.text.trim();

    // 유효성 검증
    if (petName.isEmpty) {
      setState(() {
        _errorMessage = '펫 이름을 입력해주세요!';
      });
      return; // 유효성 검증 실패 시 함수 종료
    } else if (_containsSpecialCharacters(petName)) {
      setState(() {
        _errorMessage = '특수 문자는 사용할 수 없습니다!';
      });
      return; // 유효성 검증 실패 시 함수 종료
    } else if (petName.length > 10) {
      setState(() {
        _errorMessage = '펫 이름은 최대 10자 이내여야 합니다!';
      });
      return; // 유효성 검증 실패 시 함수 종료
    } else {
      setState(() {
        _errorMessage = null; // 오류 없음
      });
    }

    // 유효성 검증 성공 시에만 다음 단계 진행
    final accessToken = await _secureStorage.read(key: 'accessToken');
    final deviceId = await _secureStorage.read(key: 'deviceId');
    final userId = await _secureStorage.read(key: 'userId');

    if (accessToken == null || deviceId == null || userId == null) {
      print('❌ 인증 정보가 부족합니다. 시작화면으로 돌아갈게요.');
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text('인증 오류'),
            content: const Text('❌ 인증 정보가 부족합니다. 시작화면으로 돌아갈게요.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushNamedAndRemoveUntil(context, '/start', (route) => false);
                },
                child: const Text('확인'),
              ),
            ],
          );
        },
      );
      return;
    }

    try {
      // 펫 생성 요청 전송
      final response = await http.post(
        Uri.parse('http://ecobuddy.kro.kr:4525/pet/create?petName=$petName'),
        headers: {
          'authorization': accessToken,
          'deviceId': deviceId,
          'userId': userId,
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['new_accessToken'] != null) {
          await _secureStorage.write(
            key: 'accessToken',
            value: responseData['new_accessToken'],
          );

          await TokenManager.updateCredentials();

          print('✅ 새로운 펫 생성 성공 및 액세스 토큰 업데이트 완료!');
          await _secureStorage.write(key:'Make', value: '1');
          Navigator.pushReplacementNamed(context, '/main');
        } else {
          print('⚠️ 새로운 액세스 토큰이 응답에 없습니다.');
        }
      } else {
        setState(() {
          _errorMessage = '펫 생성 중 오류가 발생했습니다. (${response.statusCode})';
        });
        print('❌ 펫 생성 실패: ${response.statusCode}');
        print('❌ 응답 내용: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = '펫 생성 중 오류가 발생했습니다.';
      });
      print('❌ 펫 생성 중 오류 발생: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 꽃 캐릭터 이미지
              Image.asset(
                'assets/images/character/happy.png', // 이미지 파일 경로
                height: 150,
              ),
              const SizedBox(height: 20),
              const Text(
                '환영합니다!\n당신과 함께할 펫의 이름을 정해주세요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  // 이름 입력 필드
                  Expanded(
                    child: TextField(
                      controller: _petNameController,
                      decoration: InputDecoration(
                        hintText: '이름',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFFFF5E1), // 배경색
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // 화살표 버튼
                  ElevatedButton(
                    onPressed: _createPet,
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(16),
                      backgroundColor: _isNameEntered
                          ? const Color(0xFF4CAF50) // 진한 초록색
                          : const Color(0xFFB6E3A8), // 연한 초록색
                    ),
                    child: const Icon(Icons.arrow_forward, color: Colors.white),
                  ),
                ],
              ),
              // 에러 메시지
              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
