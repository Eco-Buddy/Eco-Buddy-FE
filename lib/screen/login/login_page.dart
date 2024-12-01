import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart'; // Android용 WebView
import 'package:webview_windows/webview_windows.dart'; // Windows용 WebView
import 'dart:io'; // 플랫폼 확인
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // 보안 저장소
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
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage(); // 보안 저장소

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
    final sessionCookie = await _secureStorage.read(key: 'session_cookie'); // 세션 쿠키 읽기

    try {
      final response = await http.get(
        Uri.parse(naverServerUrl),
        headers: {
          if (sessionCookie != null) 'Cookie': 'JSESSIONID=$sessionCookie', // 세션 쿠키 포함
        },
      );
      print("Naver Login API Response: Status Code: ${response.statusCode}");
      print("Naver Login API Response: Body: ${response.body}");
      if (response.statusCode == 200) {
        final naverLoginUrl = response.body; // 서버에서 반환된 URL
        _loadWebView(naverLoginUrl); // WebView로 로드
      } else {
        print('네이버 로그인 URL 로딩 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('네이버 로그인 요청 중 오류 발생: $e');
    }
  }

  void _loadKakaoLoginPage() async {
    final sessionCookie = await _secureStorage.read(key: 'session_cookie'); // 세션 쿠키 읽기
    print('Saved Session Cookie: $sessionCookie');
    try {
      final response = await http.get(
        Uri.parse(kakaoServerUrl),
        headers: {
          if (sessionCookie != null) 'Cookie': 'JSESSIONID=$sessionCookie', // 세션 쿠키 포함
        },
      );
      print("Kakao Login API Response: Status Code: ${response.statusCode}");
      print("Kakao Login API Response: Body: ${response.body}");
      if (response.statusCode == 200) {
        final kakaoLoginUrl = response.body; // 서버에서 반환된 URL
        _loadWebView(kakaoLoginUrl); // WebView로 로드
      } else {
        print('카카오 로그인 URL 로딩 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('카카오 로그인 요청 중 오류 발생: $e');
    }
  }

  void _handleRedirectUri(String url, {required bool isNaver}) async {
    print("Handling Redirect for URL: $url");
    if (Platform.isWindows) {
      await _windowsWebViewController.dispose();
    }
    setState(() {
      _isWebViewVisible = false;
    });

    try {
      final sessionCookie = await _secureStorage.read(key: 'session_cookie');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (sessionCookie != null) 'Cookie': 'JSESSIONID=$sessionCookie',
        },
      );
      print("Redirect API Response: Status Code: ${response.statusCode}");
      print("Redirect API Response: Body: ${response.body}");
      print("Request Headers: ${response.request?.headers}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Parsed Data from Redirect Response: $data");
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
        print('로그인 완료 후 토큰 데이터 요청 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('Redirect 처리 중 오류 발생: $e');
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

  Future<void> _saveUserData({
    required String id,
    required String name,
    required String profileImage,
    required String accessToken,
    required bool isNew,
    required bool isNaver,
  }) async {
    await _secureStorage.write(key: 'userId', value: id);
    await _secureStorage.write(key: 'userName', value: name);
    await _secureStorage.write(key: 'profileImage', value: profileImage);
    await _secureStorage.write(key: 'accessToken', value: accessToken);
    await _secureStorage.write(key: 'isNew', value: isNew.toString());
    await _secureStorage.write(key: 'provider', value: isNaver ? 'naver' : 'kakao');

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
