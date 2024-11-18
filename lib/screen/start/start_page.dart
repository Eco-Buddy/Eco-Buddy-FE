import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // 보안 저장소

class StartPage extends StatefulWidget {
  const StartPage({Key? key}) : super(key: key);

  @override
  _StartPageState createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage(); // 보안 저장소 인스턴스

  @override
  void initState() {
    super.initState();
    _setTestLoginState(); // 테스트용 로그인 상태 설정
  }

  // 테스트용 로그인 상태 설정
  Future<void> _setTestLoginState() async {
    final isLoggedIn = await _secureStorage.read(key: 'isLoggedIn');
    if (isLoggedIn == null) {
      await _secureStorage.write(key: 'isLoggedIn', value: 'false'); // 초기화
    }
  }

  // 로그인 기록 확인 및 페이지 이동
  Future<void> _navigateBasedOnLoginStatus() async {
    final isLoggedIn = await _secureStorage.read(key: 'isLoggedIn');
    if (isLoggedIn == 'true') {
      Navigator.pushReplacementNamed(context, '/main'); // MainPage로 이동
    } else {
      Navigator.pushReplacementNamed(context, '/login'); // LoginPage로 이동
    }
  }

  @override
  Widget build(BuildContext context) {
    // 화면 크기 가져오기
    final screenHeight = MediaQuery.of(context).size.height;

    // 버튼 크기 설정 (화면 비율에 따라 크기 조정)
    final buttonWidth = screenHeight * 0.5; // 화면 높이의 50%
    final buttonHeight = screenHeight * 0.08; // 화면 높이의 8%

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 배경 이미지
          Positioned.fill(
            child: Image.asset(
              'assets/images/start/start_background.png', // 배경 이미지 경로
              fit: BoxFit.fitHeight, // 세로로 꽉 차도록 설정
              alignment: Alignment.center, // 이미지를 화면 중앙에 정렬
            ),
          ),
          // 중앙에 Start 버튼
          Align(
            alignment: Alignment(0, 0.8), // 화면 하단으로 배치 (-1: 위, 1: 아래)
            child: ElevatedButton(
              onPressed: _navigateBasedOnLoginStatus, // Start 버튼 클릭 시 로그인 상태 확인 후 이동
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: buttonWidth * 0.2,
                  vertical: buttonHeight * 0.5,
                ),
                backgroundColor: Colors.white, // 버튼 배경색
                shadowColor: Colors.grey, // 그림자 색상
                elevation: 10, // 버튼 그림자 높이
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50), // 둥근 모서리
                ),
              ),
              child: const Text(
                'START',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black, // 텍스트 색상
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
