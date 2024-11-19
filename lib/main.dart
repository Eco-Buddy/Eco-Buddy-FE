import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Provider import
import 'provider/user_provider.dart'; // UserProvider import
import 'screen/start/start_page.dart'; // StartPage import
import 'screen/login/login_page.dart'; // LoginPage import
import 'screen/main/main_page.dart'; // MainPage import

void main() {
  // Flutter 플랫폼 초기화
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()..loadUser()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Eco Buddy',
        theme: ThemeData(
          primarySwatch: Colors.green,
        ),
        initialRoute: '/start', // StartPage를 초기 라우트로 설정
        routes: {
          '/start': (context) => const StartPage(), // StartPage
          '/login': (context) => const LoginPage(), // LoginPage
          '/main': (context) => const MainPage(), // MainPage
        },
      ),
    );
  }
}
