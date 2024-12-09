import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import '../stats/digital_carbon_page.dart';
import '../stats/windows_display.dart';
import '../stats/window_initializer.dart';
import '../home/home_page.dart';
import '../menu/menu_page.dart';
import '../../common/widget/custom_bottom_bar.dart';
import '../../provider/pet_provider.dart'; // PetProvider import
import '../stats/mobile_initializer.dart';
import '../../provider/pet_provider.dart';
import '../home/character_provider.dart'; // CharacterProvider import

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final initializer = WindowInitializer();
  final mobileInitializer = DataFetchService();
  int currentIndex = 1; // 기본 선택된 탭: 홈 페이지
  bool isLoading = true; // 로딩 상태
  bool hasError = false; // 에러 상태

  final GlobalKey<DataUsagePageState> _dataUsageKey = GlobalKey<DataUsagePageState>(); // 키 추가
  final GlobalKey<DisplayUsagePageState> _displayUsageKey = GlobalKey<DisplayUsagePageState>();


  Widget get statsPage {
    if (Platform.isWindows) {
      return DisplayUsagePage(
        updateDailyUsage: initializer.updateDailyUsage,
        updateHourlyUsage: initializer.updateHourlyUsage,
        key: _displayUsageKey
      ); // 윈도우용 페이지
    } else if (Platform.isAndroid) {
      return DataUsagePage(key: _dataUsageKey); // 안드로이드용 페이지
    } else {
      throw UnsupportedError('현재 플랫폼은 지원되지 않습니다.');
    }
  }

  void _refreshStatsPage() {
    if (Platform.isAndroid) {
      _dataUsageKey.currentState?.fetchData(); // _fetchData 호출
    }
    else if (Platform.isWindows) {
      _displayUsageKey.currentState?.refreshData();
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
    _initializeDataAndPetData();
  }

  Future<void> _initializeDataAndPetData() async {
    try {
      // 데이터 초기화
      await _initializeData(); // 첫 번째 함수 실행
      // 펫 데이터 초기화
      await _initializePetData(); // 두 번째 함수 실행
    } catch (e) {
      print('❌ 초기화 중 오류 발생: $e');
      setState(() {
        hasError = true;
      });
    }
  }

  Future<void> _initializeData() async {
    try {
      await mobileInitializer.fetchAndStoreCarbonFootprint(); // 데이터 처리 및 저장
    } catch (e) {
      print('❌ 데이터 초기화 중 오류 발생: $e');
    }
  }

  Future<void> _initializePetData() async {
    final petProvider = Provider.of<PetProvider>(context, listen: false);

    try {
      // 서버에서 데이터 가져오기 (항상 실행)
      await petProvider.loadPetDataFromServer();
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
    final secureStorage = const FlutterSecureStorage(); // FlutterSecureStorage 객체 생성

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

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CharacterProvider()), // CharacterProvider 등록
        ChangeNotifierProvider(create: (_) => PetProvider(secureStorage: secureStorage)), // PetProvider 등록
      ],
      child: Scaffold(
        body: IndexedStack(
          index: currentIndex,
          children: pages,
        ),
        bottomNavigationBar: CustomBottomBar(
          currentIndex: currentIndex,
          onTap: (index) {
            setState(() {
              if (index == currentIndex && index == 0) {
                // 통계 페이지 클릭 시 새로고침
                _refreshStatsPage();
              } else {
                currentIndex = index;
              }
            });
          },
        ),
      ),
    );
  }
}
