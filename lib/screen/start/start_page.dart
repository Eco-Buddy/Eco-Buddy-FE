import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// 서버 기본 주소
const String baseUrl = 'http://ecobuddy.kro.kr:4525';

// 엔드포인트 정의
class ApiEndpoints {
  static const String start = '/start'; // /start 엔드포인트
  static const String logout = '/logout'; // /logout 엔드포인트
}

class StartPage extends StatefulWidget {
  const StartPage({Key? key}) : super(key: key);

  @override
  _StartPageState createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  String? deviceId; // 기기 ID 저장
  bool isLoading = true; // 로딩 상태 관리
  String? errorMessage; // 에러 메시지 관리

  @override
  void initState() {
    super.initState();
    _fetchDeviceId(); // 초기화 시 기기 ID 가져오기
  }

  // 기기 ID 가져오기
  Future<void> _fetchDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    String id = 'unknown';

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        id = androidInfo.id ?? 'unknown'; // Android ID 가져오기
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        id = iosInfo.identifierForVendor ?? 'unknown'; // iOS ID 가져오기
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        id = windowsInfo.deviceId ?? 'unknown'; // Windows ID 가져오기
      }
    } catch (e) {
      print('Error fetching device ID: $e');
      setState(() {
        errorMessage = 'Failed to fetch device ID';
      });
    }

    setState(() {
      deviceId = id;
      isLoading = false; // 로딩 완료
    });
    print('Device ID: $deviceId');
    print('Device ID Type: ${deviceId.runtimeType}');
  }

  // /start API 호출
  Future<void> _sendDeviceId() async {
    if (deviceId == null || deviceId == 'unknown') {
      print('Invalid Device ID. Cannot send request.');
      setState(() {
        errorMessage = 'Invalid Device ID';
      });
      return;
    }

    final url = Uri.parse('$baseUrl${ApiEndpoints.start}'); // /start 엔드포인트 URL

    try {
      print('Sending Device ID: $deviceId');

      final response = await http.post(
        url,
        body: jsonEncode({'id': deviceId}),
        headers: {'Content-Type': 'application/json'},
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final cookies = response.headers['set-cookie'];
        if (cookies != null) {
          await _secureStorage.write(key: 'session_cookie', value: cookies);
          print('Session cookie saved: $cookies');
        }

        final isNew = response.headers['isNew'];
        if (isNew == '1') {
          Navigator.pushReplacementNamed(context, '/main'); // 신규 회원 -> 메인 페이지
        } else {
          Navigator.pushReplacementNamed(context, '/login'); // 기존 회원 -> 로그인 페이지
        }
      } else {
        print('Server error: ${response.statusCode} ${response.body}');
        setState(() {
          errorMessage = 'Server error: ${response.statusCode}';
        });
      }
    } catch (e) {
      print('Error sending Device ID: $e');
      setState(() {
        errorMessage = 'Error sending Device ID';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    final buttonWidth = screenHeight * 0.5;
    final buttonHeight = screenHeight * 0.08;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/start/start_background.png',
              fit: BoxFit.fitHeight,
              alignment: Alignment.center,
            ),
          ),
          Align(
            alignment: const Alignment(0, -0.5),
            child: isLoading
                ? const CircularProgressIndicator() // 로딩 중 표시
                : errorMessage != null
                ? Text(
              errorMessage!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            )
                : Text(
              deviceId ?? 'Unknown Device ID', // 기기 ID 표시
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, 0.8),
            child: ElevatedButton(
              onPressed: _sendDeviceId,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: buttonWidth * 0.2,
                  vertical: buttonHeight * 0.5,
                ),
                backgroundColor: Colors.white,
                shadowColor: Colors.grey,
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              child: const Text(
                'START',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
