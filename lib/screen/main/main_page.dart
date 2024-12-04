import 'dart:io';
import 'package:flutter/material.dart';
import '../stats/digital_carbon_page.dart';
import '../stats/windows_display.dart';
import '../stats/window_initializer.dart';
import '../home/home_page.dart';
import '../menu/menu_page.dart';
import '../../common/widget/custom_bottom_bar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final initializer = WindowInitializer();

  int currentIndex = 1; // 기본 선택된 탭: 홈 페이지


  // 페이지를 플랫폼에 따라 나누기
  Widget get statsPage {
    if (Platform.isWindows) {
      return DisplayUsagePage(updateDailyUsage: initializer.updateDailyUsage, updateHourlyUsage: initializer.updateHourlyUsage);// 윈도우용 페이지
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
      HomePage(), // 홈 페이지
      const MenuPage(), // 메뉴 페이지
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: currentIndex, // 현재 선택된 페이지 표시
        children: pages,     // 페이지 리스트
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
