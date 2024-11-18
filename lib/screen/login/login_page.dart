import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 앱 이름과 설명
              const Text(
                'ECO Buddy',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '디지털 탄소 발자국을 줄여보세요!',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              const SizedBox(height: 40),
              // 카카오 로그인 버튼
              ElevatedButton.icon(
                onPressed: () {
                  // MainPage로 이동
                  Navigator.pushReplacementNamed(context, '/main');
                },
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
              // 네이버 로그인 버튼
              ElevatedButton.icon(
                onPressed: () {
                  // MainPage로 이동
                  Navigator.pushReplacementNamed(context, '/main');
                },
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
    );
  }
}
