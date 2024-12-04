import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart'; // For Android WebView
import 'package:webview_windows/webview_windows.dart'; // For Windows WebView
import 'dart:io'; // For platform check
import '../../provider/pet_provider.dart'; // PetProvider import

class MenuPage extends StatefulWidget {
  const MenuPage({Key? key}) : super(key: key);

  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  WebViewController? _androidWebViewController; // For Android WebView
  WebviewController? _windowsWebViewController; // For Windows WebView
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _initializeWebView() async {
    if (Platform.isAndroid) {
      _androidWebViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted);
      print("✅ Android WebView 초기화 성공");
    } else if (Platform.isWindows) {
      _windowsWebViewController = WebviewController();
      await _windowsWebViewController!.initialize();
      setState(() {
        _isInitialized = true;
      });
      print("✅ Windows WebView 초기화 성공");
    } else {
      print("⚠️ WebView 지원되지 않는 플랫폼");
    }
  }

  Future<void> _logout() async {
    // 로그아웃 로직 구현 (생략)
  }

  Future<void> _editPetName(BuildContext context) async {
    final petProvider = Provider.of<PetProvider>(context, listen: false);

    String? tempPetName; // 선언 위치를 조정하여 `onChanged`에서 사용할 수 있도록 수정

    tempPetName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('펫 이름 수정'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: '새로운 펫 이름을 입력하세요',
          ),
          onChanged: (value) {
            tempPetName = value; // 값 업데이트
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, tempPetName),
            child: const Text('확인'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
        ],
      ),
    );

    if (tempPetName?.isNotEmpty ?? false) {
      print('새로운 펫 이름: $tempPetName');

      try {
        // 펫 이름 변경 후 서버와 동기화
        petProvider.pet?.petName = tempPetName!;
        await petProvider.savePetDataToServer();
        print('✅ 펫 이름 업데이트 완료');
      } catch (e) {
        print('❌ 펫 이름 업데이트 중 오류 발생: $e');
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final petProvider = Provider.of<PetProvider>(context);
    final pet = petProvider.pet;

    return Scaffold(
      appBar: AppBar(
        title: const Text('메뉴'),
        backgroundColor: Colors.green,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildUserProfile(pet),
          const SizedBox(height: 16.0),
          _buildMenuSection(
            title: '펫 관리',
            items: [
              _buildMenuItem(
                icon: Icons.pets,
                title: '펫 이름 수정',
                subtitle: '펫 이름을 변경합니다.',
                onTap: () => _editPetName(context),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          _buildMenuSection(
            title: '정보',
            items: [
              _buildMenuItem(
                icon: Icons.tips_and_updates,
                title: '환경 꿀팁',
                subtitle: '환경을 지키는 유용한 팁들',
                onTap: () {
                  // 환경 꿀팁 페이지로 이동
                  print('환경 꿀팁 클릭됨');
                },
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          _buildMenuSection(
            title: '기타',
            items: [
              _buildMenuItem(
                icon: Icons.exit_to_app,
                title: '로그아웃',
                subtitle: '계정에서 로그아웃',
                onTap: _logout,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfile(Pet? pet) {
    return Card(
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.person, size: 40, color: Colors.white),
            ),
            const SizedBox(width: 16.0),
            if (pet != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '펫 이름: ${pet.petName}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '레벨: ${pet.petLevel}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              )
            else
              const Text('펫 정보가 없습니다.'),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection({
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8.0),
        ...items,
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.green, size: 36),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(subtitle),
        onTap: onTap,
      ),
    );
  }
}
