import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // 현재 UI 상태 변수 (웹뷰 사용 여부 등)
  bool _isWebViewVisible = false;

  // 카카오 로그인 버튼 클릭 시 처리
  void _loadKakaoLoginPage() {
    setState(() {
      _isWebViewVisible = false;
    });
    // 메인 페이지로 이동
    Navigator.pushReplacementNamed(context, '/main');
  }

  // 네이버 로그인 버튼 클릭 시 처리
  void _loadNaverLoginPage() {
    setState(() {
      _isWebViewVisible = false;
    });
    // 메인 페이지로 이동
    Navigator.pushReplacementNamed(context, '/main');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: WillPopScope(
        onWillPop: () async {
          if (_isWebViewVisible) {
            setState(() {
              _isWebViewVisible = false;
            });
            return false;
          }
          return true;
        },
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'ECO Buddy',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '디지털 탄소 발자국을 줄이는 여정을 시작하세요!',
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton.icon(
                      onPressed: _loadKakaoLoginPage, // 버튼 클릭 시 처리
                      icon: Image.asset(
                        'assets/images/icon/kakao_icon.png',
                        width: 24,
                        height: 24,
                      ),
                      label: const Text(
                        '카카오 로그인',
                        style: TextStyle(color: Colors.black, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFEE500),
                        elevation: 0,
                        minimumSize: const Size(200, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadNaverLoginPage, // 버튼 클릭 시 처리
                      icon: Image.asset(
                        'assets/images/icon/naver_icon.png',
                        width: 24,
                        height: 24,
                      ),
                      label: const Text(
                        '네이버 로그인',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF03C75A),
                        elevation: 0,
                        minimumSize: const Size(200, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isWebViewVisible)
              Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withOpacity(0.7), // 웹뷰가 보여질 때의 배경 색상
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
