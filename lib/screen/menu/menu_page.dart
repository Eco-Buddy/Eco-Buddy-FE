import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart'; // For Android WebView
import 'package:webview_windows/webview_windows.dart'; // For Windows WebView
import 'dart:io'; // For platform check
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Secure storage

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

  @override
  void initState() {
    super.initState();
    _initializeWebView();
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
      // Retrieve stored data
      final provider = await _secureStorage.read(key: 'provider');
      final accessToken = await _secureStorage.read(key: 'accessToken');

      // Call logout API
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

      // Clear secure storage
      await _secureStorage.deleteAll();
      print('🔑 Secure storage cleared.');

      // Clear WebView cookies and cache
      if (Platform.isAndroid && _androidWebViewController != null) {
        await _androidWebViewController!.clearCache();
        print('✅ Android WebView cache cleared.');
      } else if (Platform.isWindows && _windowsWebViewController != null && _isInitialized) {
        await _windowsWebViewController!.clearCache();
        await _windowsWebViewController!.clearCookies();
        print('✅ Windows WebView cookies and cache cleared.');
      }

      // Navigate to start page
      Navigator.pushReplacementNamed(context, '/start');
    } catch (e) {
      print('❌ 로그아웃 처리 중 오류 발생: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('메뉴'),
        backgroundColor: Colors.green,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildUserProfile(),
          const SizedBox(height: 16.0),
          _buildMenuSection(
            title: '일반 설정',
            items: [
              _buildMenuItem(
                icon: Icons.settings,
                title: '설정',
                subtitle: '알림, 개인정보 등',
                onTap: () => Navigator.pushNamed(context, '/settings'),
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

  Widget _buildUserProfile() {
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '사용자 이름',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '레벨: 1',
                  style: TextStyle(fontSize: 16),
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
