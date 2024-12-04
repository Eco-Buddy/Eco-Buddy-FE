import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // SecureStorage import
import 'provider/pet_provider.dart';
import 'screen/start/start_page.dart'; // StartPage import
import 'screen/login/login_page.dart'; // LoginPage import
import 'screen/login/newbie.dart'; // NewbiePage import
import 'screen/main/main_page.dart'; // MainPage import

// 윈도우 관련 API
import 'package:windows_single_instance/windows_single_instance.dart';
import 'package:window_manager/window_manager.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'screen/stats/windows_tray.dart';

import 'dart:io';
import 'screen/stats/window_initializer.dart';

// 전역 SecureStorage 변수 선언
final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // 윈도우 세팅
  if (Platform.isWindows) {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    launchAtStartup.setup(
      appName: packageInfo.appName,
      appPath: Platform.resolvedExecutable,
      packageName: 'com.flutter.digital_carbon',
    );

    await launchAtStartup.enable();
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
      await windowManager.hide();
    });

    if (Platform.isWindows) {
      await setupWindowsTray();
    }

    final initializerService = WindowInitializer();
    await initializerService.initializeApp();
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        // PetProvider에 SecureStorage 전달
        final petProvider = PetProvider(secureStorage: secureStorage);
        _initializePetProvider(petProvider);
        return petProvider;
      },
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Eco Buddy',
        theme: ThemeData(primarySwatch: Colors.green),
        initialRoute: '/start',
        routes: {
          '/newbie': (context) => NewbiePage(),
          '/start': (context) => const StartPage(),
          '/login': (context) => const LoginPage(),
          '/main': (context) => const MainPage(),
        },
      ),
    );
  }

  // PetProvider 초기화 로직
  Future<void> _initializePetProvider(PetProvider petProvider) async {
    // 1. 로컬 데이터 로드
    await petProvider.loadLocalData();

    // 2. 서버 동기화 작업
    final userId = await secureStorage.read(key: 'userId');
    if (userId != null) {
      await petProvider.fetchPetData();
    }
  }
}
