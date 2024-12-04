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
  static const String validateSession = '/validate_session'; // 세션 유효성 검사
}

class StartPage extends StatefulWidget {
  const StartPage({Key? key}) : super(key: key);

  @override
  _StartPageState createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  String? deviceId;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _fetchDeviceId();
    await _checkExistingSession();
  }

  // 기기 ID 가져오기
  Future<void> _fetchDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    String id = 'unknown';

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        id = androidInfo.id ?? 'unknown';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        id = iosInfo.identifierForVendor ?? 'unknown';
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        id = windowsInfo.deviceId ?? 'unknown';
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to fetch device ID';
      });
    }

    setState(() {
      deviceId = id;
    });
    print('Device ID: $deviceId');
  }

  // 기존 세션 확인 및 유효성 검사
  Future<void> _checkExistingSession() async {
    final existingCookie = await _secureStorage.read(key: 'session_cookie');
    if (existingCookie != null) {
      final isValid = await _validateSessionCookie(existingCookie);
      if (isValid) {
        Navigator.pushReplacementNamed(context, '/main');
        return;
      } else {
        await _secureStorage.delete(key: 'session_cookie'); // 유효하지 않은 세션 삭제
        print('❌ 세션 유효하지 않음. 새 로그인 필요.');
      }
    }
    setState(() {
      isLoading = false; // 로딩 상태 해제
    });
  }

  // 세션 유효성 검사
  Future<bool> _validateSessionCookie(String cookie) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl${ApiEndpoints.validateSession}'),
        headers: {'Cookie': 'JSESSIONID=$cookie'},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('❌ 세션 유효성 검사 중 오류 발생: $e');
      return false;
    }
  }

  // /start API 호출 및 세션 생성
  Future<void> _sendDeviceId() async {
    if (deviceId == null || deviceId == 'unknown') {
      setState(() {
        errorMessage = 'Invalid Device ID';
      });
      return;
    }

    final url = Uri.parse('$baseUrl${ApiEndpoints.start}');
    try {
      final response = await http.post(
        url,
        body: jsonEncode({'id': deviceId}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final cookies = response.headers['set-cookie'];
        if (cookies != null) {
          final sessionId =
          RegExp(r'JSESSIONID=([^;]+)').firstMatch(cookies)?.group(1);
          if (sessionId != null) {
            await _secureStorage.write(key: 'session_cookie', value: sessionId);
          }
        }

        final isNew = response.headers['isNew'];
        if (isNew == '1') {
          Navigator.pushReplacementNamed(context, '/main');
        } else {
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        setState(() {
          errorMessage = 'Server error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error sending Device ID';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/start/start_background.png',
              fit: BoxFit.cover,
            ),
          ),
          Align(
            alignment: const Alignment(0, -0.5),
            child: isLoading
                ? const CircularProgressIndicator()
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
              deviceId ?? 'Unknown Device ID',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          if (!isLoading)
            Align(
              alignment: const Alignment(0, 0.8),
              child: ElevatedButton(
                onPressed: _sendDeviceId,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 15),
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
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
