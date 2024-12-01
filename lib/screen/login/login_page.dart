import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart'; // Android용 WebView
import 'package:webview_windows/webview_windows.dart'; // Windows용 WebView
import 'dart:io'; // 플랫폼 확인
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // 로컬 저장소 사용
import '../main/main_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final WebViewCookieManager _cookieManager = WebViewCookieManager();
  late WebViewController _webViewController;
  late WebviewController _windowsWebViewController;

  bool _isWebViewVisible = false;

  final String naverServerUrl = 'http://223.130.162.100:4525/login/request/naver';
  final String kakaoServerUrl = 'http://223.130.162.100:4525/login/request/kakao';

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      WidgetsFlutterBinding.ensureInitialized();
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: (NavigationRequest request) {
              if (request.url.startsWith(
                  "http://223.130.162.100:4525/login/oauth2/code/naver")) {
                _handleRedirectUri(request.url, isNaver: true);
                return NavigationDecision.prevent;
              } else if (request.url.startsWith(
                  "http://223.130.162.100:4525/login/oauth2/code/kakao")) {
                _handleRedirectUri(request.url, isNaver: false);
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
          ),
        );
    } else if (Platform.isWindows) {
      _windowsWebViewController = WebviewController();
      _initializeWindowsWebView();
    }
  }

  Future<void> _initializeWindowsWebView() async {
    try {
      await _windowsWebViewController.initialize();
    } catch (e) {
      print("Windows WebView 초기화 실패: $e");
    }
  }

  void _loadNaverLoginPage() async {
    final response = await http.get(Uri.parse(naverServerUrl));
    if (response.statusCode == 200) {
      final naverLoginUrl = response.body;
      _loadWebView(naverLoginUrl);
    } else {
      print('네이버 로그인 URL 로딩 실패');
    }
  }

  void _loadKakaoLoginPage() async {
    final response = await http.get(Uri.parse(kakaoServerUrl));
    if (response.statusCode == 200) {
      final kakaoLoginUrl = response.body;
      _loadWebView(kakaoLoginUrl);
    } else {
      print('카카오 로그인 URL 로딩 실패');
    }
  }

  void _loadWebView(String url) {
    if (Platform.isAndroid) {
      setState(() {
        _isWebViewVisible = true;
      });
      _webViewController.loadRequest(Uri.parse(url));
    } else if (Platform.isWindows) {
      _windowsWebViewController.loadUrl(url);
      _windowsWebViewController.url.listen((String? redirectedUrl) {
        if (redirectedUrl != null &&
            redirectedUrl.startsWith(
                "http://223.130.162.100:4525/login/oauth2/code")) {
          _handleRedirectUri(redirectedUrl,
              isNaver: redirectedUrl.contains("naver"));
        }
      });
    }
  }

  void _handleRedirectUri(String url, {required bool isNaver}) async {
    if (Platform.isWindows) {
      await _windowsWebViewController.dispose();
    }
    setState(() {
      _isWebViewVisible = false;
    });

    final response = await http.post(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _saveUserData(
        id: data['id'],
        name: data['name'],
        profileImage: data['profile_image'],
        accessToken: data['access_token'],
        isNew: response.headers['isNew'] == "1",
        isNaver: isNaver,
      );

      print('${isNaver ? "네이버" : "카카오"} 로그인 성공: ID=${data['id']}, 토큰=${data['access_token']}');

      Navigator.pushReplacementNamed(context, '/main');
    } else {
      print('로그인 완료 후 토큰 데이터 요청 실패');
    }
  }

  Future<void> _saveUserData({
    required String id,
    required String name,
    required String profileImage,
    required String accessToken,
    required bool isNew,
    required bool isNaver,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('userId', id);
    await prefs.setString('userName', name);
    await prefs.setString('profileImage', profileImage);
    await prefs.setString('accessToken', accessToken);
    await prefs.setBool('isNew', isNew);
    await prefs.setString('provider', isNaver ? 'naver' : 'kakao');

    print('사용자 데이터가 저장되었습니다.');
  }

  Future<void> _clearCookiesAndCache() async {
    await _cookieManager.clearCookies();
    print('쿠키와 캐시가 삭제되었습니다.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: WillPopScope(
        onWillPop: () async {
          if (_isWebViewVisible) {
            setState(() {
              _isWebViewVisible = false;
            });
            return false;
          }
          return true;
        },
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'ECO Buddy',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '디지털 탄소 발자국을 줄이는 여정을 시작하세요!',
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton.icon(
                      onPressed: _loadKakaoLoginPage,
                      icon: Image.asset(
                        'assets/images/icon/kakao_icon.png',
                        width: 24,
                        height: 24,
                      ),
                      label: const Text(
                        '카카오 로그인',
                        style: TextStyle(color: Colors.black, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFEE500),
                        elevation: 0,
                        minimumSize: const Size(200, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadNaverLoginPage,
                      icon: Image.asset(
                        'assets/images/icon/naver_icon.png',
                        width: 24,
                        height: 24,
                      ),
                      label: const Text(
                        '네이버 로그인',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF03C75A),
                        elevation: 0,
                        minimumSize: const Size(200, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isWebViewVisible && Platform.isAndroid)
              WebViewWidget(controller: _webViewController),
            if (_isWebViewVisible && Platform.isWindows)
              Positioned.fill(
                child: Webview(_windowsWebViewController),
              ),
          ],
        ),
      ),
    );
  }
}
