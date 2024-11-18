import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'screen/main/main_page.dart'; // MainPage import
import 'screen/login/login_page.dart'; // LoginPage import

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // 디버그 배너 제거
      title: 'Eco Buddy',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      initialRoute: '/login',
      // 기본 라우트를 로그인 페이지로 설정
      routes: {
        '/login': (context) => const LoginPage(), // 로그인 페이지
        '/main': (context) => const MainPage(), // 메인 페이지 (하단 바 포함)
      },
    );
  }

  // Redirect URI 핸들링
  void _handleRedirectUri(String url, {required bool isNaver}) async {
    setState(() {
      _isWebViewVisible = false;
    });

    final response = await http.post(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        if (isNaver) {
          naverUserId = data['id'];
          naverAccessToken = data['access_token'];
        } else {
          kakaoUserId = data['id'];
          kakaoAccessToken = data['access_token'];
        }
      });

      print('User ID: ${isNaver ? naverUserId : kakaoUserId}');
      print('Access Token: ${isNaver ? naverAccessToken : kakaoAccessToken}');
    } else {
      print('로그인 완료 후 토큰 데이터 요청 실패');
    }
  }
}
