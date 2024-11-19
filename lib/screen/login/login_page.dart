import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart'; // Android용 WebView
import 'package:webview_windows/webview_windows.dart'; // Windows용 WebView
import 'dart:io'; // 플랫폼 확인
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../main/main_page.dart';
class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final WebViewCookieManager _cookieManager = WebViewCookieManager();
  // Android용 WebView Controller
  late WebViewController _webViewController;

  // Windows용 WebView Controller
  late WebviewController _windowsWebViewController;

  bool _isWebViewVisible = false;

  final String naverServerUrl = 'http://223.130.162.100:4525/login/request/naver';
  final String kakaoServerUrl = 'http://223.130.162.100:4525/login/request/kakao';

  String? _naverUserId;
  String? _naverAccessToken;
  String? _kakaoUserId;
  String? _kakaoAccessToken;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      // Android용 WebView 초기화
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
      // Windows용 WebView 초기화
      _windowsWebViewController = WebviewController();
      _initializeWindowsWebView();
    }
  }

  // Windows WebView 초기화
  Future<void> _initializeWindowsWebView() async {
    try {
      await _windowsWebViewController.initialize();
    } catch (e) {
      print("Windows WebView 초기화 실패: $e");
    }
  }

  // 네이버 로그인 페이지 로드
  void _loadNaverLoginPage() async {
    final response = await http.get(Uri.parse(naverServerUrl));
    if (response.statusCode == 200) {
      final naverLoginUrl = response.body;
      _loadWebView(naverLoginUrl);
    } else {
      print('네이버 로그인 URL 로딩 실패');
    }
  }

  // 카카오 로그인 페이지 로드
  void _loadKakaoLoginPage() async {
    final response = await http.get(Uri.parse(kakaoServerUrl));
    if (response.statusCode == 200) {
      final kakaoLoginUrl = response.body;
      _loadWebView(kakaoLoginUrl);
    } else {
      print('카카오 로그인 URL 로딩 실패');
    }
  }

  // WebView 로드 (Android/Windows 구분)
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

  // Redirect URI 처리
  void _handleRedirectUri(String url, {required bool isNaver}) async {
    if (Platform.isWindows) {
      // Windows WebView 닫기
      await _windowsWebViewController.dispose(); // close 대신 dispose 사용
    }
    setState(() {
      _isWebViewVisible = false; // Android WebView 숨기기
    });

    final response = await http.post(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (isNaver) {
        _naverUserId = data['id'];
        _naverAccessToken = data['access_token'];
        print('네이버 로그인 성공: ID=$_naverUserId, 토큰=$_naverAccessToken');
      } else {
        _kakaoUserId = data['id'];
        _kakaoAccessToken = data['access_token'];
        print('카카오 로그인 성공: ID=$_kakaoUserId, 토큰=$_kakaoAccessToken');
      }

      // 메인 페이지로 이동
      Navigator.pushReplacementNamed(context, '/main');
    } else {
      print('로그인 완료 후 토큰 데이터 요청 실패');
    }
  }

  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['clearCookies'] == true) {
      _clearCookiesAndCache();
    }
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
