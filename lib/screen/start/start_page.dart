import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // 보안 저장소

class StartPage extends StatefulWidget {
  const StartPage({Key? key}) : super(key: key);

  @override
  _StartPageState createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage(); // 보안 저장소 인스턴스
  bool _showTapMessage = false; // "화면을 누르세요" 메시지 표시 여부

  @override
  void initState() {
    super.initState();
    _initStartPage();
  }

  // 1초 뒤에 "화면을 누르세요" 메시지 표시
  Future<void> _initStartPage() async {
    await Future.delayed(const Duration(seconds: 1)); // 1초 대기
    setState(() {
      _showTapMessage = true; // 메시지 표시
    });
  }

  // 로그인 기록 확인 및 페이지 이동
  Future<void> _navigateBasedOnLoginStatus() async {
    final isLoggedIn = await _secureStorage.read(key: 'isLoggedIn'); // 보안 저장소에서 로그인 상태 확인

    if (isLoggedIn == 'true') {
      Navigator.pushReplacementNamed(context, '/main'); // MainPage로 이동
    } else {
      Navigator.pushReplacementNamed(context, '/login'); // LoginPage로 이동
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () => _navigateBasedOnLoginStatus(), // 화면 터치 시 페이지 이동
        child: Center(
          child: _showTapMessage
              ? const Text(
            '화면을 누르세요',
            style: TextStyle(fontSize: 24, color: Colors.green),
          )
              : const CircularProgressIndicator(), // 대기 중 로딩 인디케이터
        ),
      ),
    );
  }
}
