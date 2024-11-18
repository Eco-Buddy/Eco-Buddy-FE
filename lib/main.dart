import 'package:flutter/material.dart';
import 'screen/main/main_page.dart'; // MainPage import
import 'screen/login/login_page.dart'; // LoginPage import

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // 디버그 배너 제거
      title: 'Eco Buddy',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      initialRoute: '/login', // 기본 라우트를 로그인 페이지로 설정
      routes: {
        '/login': (context) => const LoginPage(), // 로그인 페이지
        '/main': (context) => const MainPage(),  // 메인 페이지 (하단 바 포함)
      },
    );
  }
}
