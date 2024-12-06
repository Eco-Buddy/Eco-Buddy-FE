import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart'; // Provider import
import '../stats/digital_carbon_page.dart';
import '../stats/windows_display.dart';
import '../stats/window_initializer.dart';
import '../home/home_page.dart';
import '../menu/menu_page.dart';
import '../../common/widget/custom_bottom_bar.dart';
import '../../provider/pet_provider.dart'; // PetProvider import

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final initializer = WindowInitializer();
  int currentIndex = 1; // 기본 선택된 탭: 홈 페이지
  bool isLoading = true; // 로딩 상태
  bool hasError = false; // 에러 상태

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
    _initializePetData(); // 펫 데이터 초기화
  }

  Future<void> _initializePetData() async {
    final petProvider = Provider.of<PetProvider>(context, listen: false); // Provider 사용

    try {
      // 서버에서 데이터 가져오기 (항상 실행)
      await petProvider.loadPetDataFromServer();

      // 가져온 데이터를 로컬 저장소에 저장
      await petProvider.savePetDataToServer();
    } catch (e) {
      print('❌ 펫 데이터 초기화 중 오류 발생: $e');
      setState(() {
        hasError = true;
      });
    } finally {
      setState(() {
        isLoading = false; // 로딩 상태 종료
      });

    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      // 로딩 화면 표시
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (hasError) {
      // 에러 화면 표시
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '펫 데이터를 불러오는 중 오류가 발생했습니다.',
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializePetData, // 다시 시도 버튼
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    // 정상적인 페이지 렌더링
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: pages,
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
