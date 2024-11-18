import 'package:flutter/material.dart';
import 'screen/start/start_page.dart'; // StartPage import

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Eco Buddy',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      initialRoute: '/start', // StartPage를 초기 라우트로 설정
      routes: {
        '/start': (context) => const StartPage(), // StartPage
      },
    );
  }
}
