import 'package:flutter/material.dart';
import '../stats/stats_page.dart';
import '../home/home_page.dart';
import '../menu/menu_page.dart';
import '../../common/widget/custom_bottom_bar.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int currentIndex = 1; // 기본 선택된 탭: 홈 페이지

  final List<Widget> pages = [
    const StatsPage(),  // 통계 페이지
    HomePage(),   // 홈 페이지
    const MenuPage(),   // 메뉴 페이지
  ];

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
