import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart'; // For Android WebView
import 'package:webview_windows/webview_windows.dart'; // For Windows WebView
import 'dart:io'; // For platform check
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Secure storage
import '../../provider/pet_provider.dart';  // 예시
import 'package:provider/provider.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({Key? key}) : super(key: key);

  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  WebViewController? _androidWebViewController; // For Android WebView
  WebviewController? _windowsWebViewController; // For Windows WebView
  bool _isInitialized = false;
  String? newPetName; // 클래스 상태 변수

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  bool _containsSpecialCharacters(String input) {
    final RegExp specialCharRegex = RegExp(r'[!@#\$%^&*(),.?":{}|<>]');
    return specialCharRegex.hasMatch(input);
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
    try {
      final provider = await _secureStorage.read(key: 'provider');
      final accessToken = await _secureStorage.read(key: 'accessToken');

      if (provider != null && accessToken != null) {
        final response = await http.post(
          Uri.parse('http://223.130.162.100:4525/$provider/logout'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'access_token': accessToken}),
        );

        if (response.statusCode == 200) {
          print('✅ 로그아웃 성공');
        } else {
          print('❌ 로그아웃 실패: ${response.statusCode}');
        }
      }

      await _secureStorage.deleteAll();
      print('🔑 Secure storage cleared.');

      if (Platform.isAndroid && _androidWebViewController != null) {
        await _androidWebViewController!.clearCache();
        print('✅ Android WebView cache cleared.');
      } else if (Platform.isWindows && _windowsWebViewController != null && _isInitialized) {
        await _windowsWebViewController!.clearCache();
        await _windowsWebViewController!.clearCookies();
        print('✅ Windows WebView cookies and cache cleared.');
      }

      Navigator.pushReplacementNamed(context, '/start');
    } catch (e) {
      print('❌ 로그아웃 처리 중 오류 발생: $e');
    }
  }

  // MenuPage에서 펫 이름 수정하기
  Future<void> _editPetName(BuildContext context) async {
    // TextEditingController 사용
    TextEditingController petNameController = TextEditingController();

    String? newPetName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('펫 이름 수정'),
        content: TextField(
          controller: petNameController, // 컨트롤러로 값 관리
          decoration: const InputDecoration(
            hintText: '새로운 펫 이름을 입력하세요',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // 다이얼로그 닫을 때 입력된 값 반환
              Navigator.pop(context, petNameController.text);
            },
            child: const Text('확인'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context), // 취소시 다이얼로그 닫기
            child: const Text('취소'),
          ),
        ],
      ),
    );

    newPetName = newPetName?.trim();

    if(newPetName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('펫 이름을 비워둘 수는 없습니다!')),
      );
    }
    else if (_containsSpecialCharacters(newPetName)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('특수 문자는 사용할 수 없습니다!')),
      );
    }
    else {
      print('새로운 펫 이름: $newPetName');
      // 펫 이름을 업데이트하는 메서드 호출
      await Provider.of<PetProvider>(context, listen: false).updatePetName(newPetName!);
      // 로컬 스토리지에 업데이트된 펫 이름 저장
      // final petDataString = await _secureStorage.read(key: 'petData');
      // if (petDataString != null) {
      //   final petData = jsonDecode(petDataString);
      //   petData['petName'] = newPetName;
      //   await _secureStorage.write(key: 'petData', value: jsonEncode(petData));
      // }
      // 성공적으로 업데이트 되었으면 UI도 갱신할 수 있습니다.
      setState(() {}); // UI 업데이트
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('펫 이름이 업데이트되었습니다: $newPetName')),
      );
    }
  }

  Future<Map<String, dynamic>> _loadUserData() async {
    final profileImage = await _secureStorage.read(key: 'profileImage') ?? '';
    final userName = await _secureStorage.read(key: 'userName') ?? '사용자 이름';
    final petDataString = await _secureStorage.read(key: 'petData');
    Map<String, dynamic> petData = {};
    if (petDataString != null) {
      petData = jsonDecode(petDataString);
    }
    return {
      'profileImage': profileImage,
      'userName': userName,
      'petName': petData['petName'] ?? '귀여운 펫',
      'petLevel': petData['petLevel'] ?? 1,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('메뉴'),
        backgroundColor: Colors.green,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('오류가 발생했습니다.'),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // FutureBuilder를 다시 빌드
                    },
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }
          else {
            final data = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildUserProfile(data['profileImage'], data['userName'], data['petName'], data['petLevel']),
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
                        final petProvider = Provider.of<PetProvider>(context, listen: false); // Provider 사용
                        petProvider.printAllSecureStorage();
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
            );
          }
        },
      ),
    );
  }

  Widget _buildUserProfile(String profileImage, String userName, String petName, int petLevel) {
    return Card(
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey[300],
              backgroundImage: profileImage.startsWith('http')
                  ? NetworkImage(profileImage)
                  : null,
              child: profileImage.isEmpty ? const Icon(Icons.person, size: 40, color: Colors.white) : null,
            ),
            const SizedBox(width: 16.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '펫 이름: $petName',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  '레벨: $petLevel',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
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
