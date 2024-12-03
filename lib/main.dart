import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Provider import
import 'provider/user_provider.dart'; // UserProvider import
import 'screen/start/start_page.dart'; // StartPage import
import 'screen/login/login_page.dart'; // LoginPage import
import 'screen/main/main_page.dart'; // MainPage import
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// 윈도우 관련 api
import 'package:windows_single_instance/windows_single_instance.dart';
import 'package:window_manager/window_manager.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'screen/stats/windows_tray.dart';

import 'dart:io';
import 'screen/stats/window_initializer.dart';

late final FlutterSecureStorage secureStorage;

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // 안드로이드 세팅
  // if(Platform.isAndroid){
  //   secureStorage = FlutterSecureStorage(
  //     aOptions: AndroidOptions(
  //       encryptedSharedPreferences: true,
  //     ),
  //   );
  // }

  // 윈도우 세팅
  if(Platform.isWindows){

    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    launchAtStartup.setup(
      appName: packageInfo.appName,
      appPath: Platform.resolvedExecutable,
      // Set packageName parameter to support MSIX.
      packageName: 'com.flutter.digital_carbon',
    );

    await launchAtStartup.enable();
    // await launchAtStartup.disable();
    bool isEnabled = await launchAtStartup.isEnabled();
    print('Launch at startup is enabled: $isEnabled');

    await windowManager.ensureInitialized();
    await WindowsSingleInstance.ensureSingleInstance(
        args,
        "custom_identifier",
        onSecondWindow: (args) {
          print(args);
        });

    WindowOptions windowOptions = const WindowOptions(
      size: Size(800, 600),
      skipTaskbar: false,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      // await windowManager.show();
      await windowManager.hide();
    });

    if (Platform.isWindows) {
      await setupWindowsTray();
    }

    // 앱을 켰을 때 실행해야 하는거!
    final initializerService = WindowInitializer();
    await initializerService.initializeApp();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final userProvider = UserProvider();
            userProvider.fetchUserData(); // 사용자 데이터를 초기화
            return userProvider;
          },
        ),
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
