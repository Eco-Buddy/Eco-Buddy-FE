import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../stats/digital_carbon_page.dart';
import '../stats/windows_display.dart';
import '../stats/window_initializer.dart';
import '../home/home_page.dart';
import '../menu/menu_page.dart';
import '../../common/widget/custom_bottom_bar.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  final initializer = WindowInitializer();
  int currentIndex = 1; // 기본 선택된 탭: 홈 페이지

  Widget get statsPage {
    if (Platform.isWindows) {
      return DisplayUsagePage(
        updateDailyUsage: initializer.updateDailyUsage,
        updateHourlyUsage: initializer.updateHourlyUsage,
      ); // 윈도우용 페이지
    } else if (Platform.isAndroid) {
      return DataUsagePage(); // 안드로이드용 페이지
    } else {
      throw UnsupportedError('현재 플랫폼은 지원되지 않습니다.');
    }
  }

  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
    pages = [
      statsPage, // 통계 페이지 (플랫폼별로 다름)
      const HomePage(), // 홈 페이지
      const MenuPage(), // 메뉴 페이지
    ];
  }

  Future<Map<String, String?>> _loadUserData() async {
    final userId = await secureStorage.read(key: 'userId');
    final profileImage = await secureStorage.read(key: 'profileImage');
    final points = await secureStorage.read(key: 'points');
    return {
      'userId': userId ?? '알 수 없음',
      'profileImage': profileImage ?? '',
      'points': points ?? '0',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, String?>>(
        future: _loadUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('오류 발생: ${snapshot.error}'));
          }

          final data = snapshot.data ?? {};
          final userId = data['userId']!;
          final profileImage = data['profileImage']!;
          final points = data['points']!;

          return Stack(
            children: [
              IndexedStack(
                index: currentIndex,
                children: pages,
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index; // 현재 인덱스 업데이트
          });
        },
      ),
    );
  }
}
