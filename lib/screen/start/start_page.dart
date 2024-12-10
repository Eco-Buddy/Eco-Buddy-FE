import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:unique_identifier/unique_identifier.dart';

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
    _fetchDeviceId();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    setState(() {
      isLoading = false;
    });
  }

  // 기기 ID 가져오기
  Future<void> _fetchDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    String id = 'unknown';

    try {
      if (Platform.isAndroid) {
        try {
          id = (await UniqueIdentifier.serial)!;
        } on PlatformException {
          id = 'Failed to get Unique Identifier';
        }
        try {
          await _secureStorage.write(key: 'deviceId', value: id);
          print('1: Device ID 저장 완료');
        } catch (e) {
          print('Device ID 저장 실패: $e');
        }
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        id = windowsInfo.deviceId ?? 'unknown'; // Windows ID 가져오기
        try {
          await _secureStorage.write(key: 'deviceId', value: id);
          print('2: Device ID 저장 완료');
        } catch (e) {
          print('Device ID 저장 실패: $e');
        }
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
    _sendDeviceId();
  }

  // 기존 로그인 정보 확인 후 이동 결정
  Future<void> _checkLoginAndNavigate() async {
    final accessToken = await _secureStorage.read(key: 'accessToken');
    final deviceId = await _secureStorage.read(key: 'deviceId');
    if(deviceId == null)
      _fetchDeviceId();
    final userId = await _secureStorage.read(key: 'userId');
    final sessionCookie = await _secureStorage.read(key: 'session_cookie');
    final petData = await _secureStorage.read(key: 'petData');

    print('토큰: $accessToken');
    print('기기: $deviceId');
    print('유저: $userId');
    print('세션 쿠키: $sessionCookie');

    if (accessToken != null && deviceId != null && userId != null && petData != null) {
      print('🎉이전 로그인 기록 확인, 2차 검증.');
      checkMembership();
    } else {
      print('🔒로그인 정보가 없습니다. 로그인 페이지로 이동합니다.');

      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> checkMembership() async {

    final accessToken = await _secureStorage.read(key: 'accessToken') ?? '';
    final deviceId = await _secureStorage.read(key: 'deviceId') ?? '';
    final userId = await _secureStorage.read(key: 'userId') ?? '';

    final response = await http.post(
      Uri.parse('http://ecobuddy.kro.kr:4525/check'),
      headers: {
        'authorization': accessToken,
        'deviceId': deviceId,
        'userId': userId,
      },
    );

    if (response.statusCode == 200) {
      print('🎉기존 계정 확인, 메인 페이지로 이동합니다.');
      final responseData = jsonDecode(response.body);
      await _secureStorage.write(
        key: 'accessToken',
        value: responseData['new_accessToken'],
      );
      Navigator.pushReplacementNamed(context, '/main');
    }
    else {
      print('🔒회원 정보가 없습니다. 로그인 페이지로 이동합니다.');
      Navigator.pushReplacementNamed(context, '/login');
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
            print('세션 쿠키 저장 완료: $sessionId');
          }
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
    final backgroundImage = Platform.isAndroid
        ? 'assets/images/start/start_background2.png' // Android에서는 _2 이미지
        : 'assets/images/start/start_background.png'; // 다른 플랫폼에서는 기본 이미지
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              backgroundImage,
              fit: BoxFit.cover,
            ),
          ),
          if (!isLoading)
            Align(
              alignment: const Alignment(0, 0.8),
              child: ElevatedButton(
                onPressed: _checkLoginAndNavigate,
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
