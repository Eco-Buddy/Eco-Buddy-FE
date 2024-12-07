import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart'; // Android용 WebView
import 'package:webview_windows/webview_windows.dart'; // Windows용 WebView
import 'dart:io'; // 플랫폼 확인
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // 보안 저장소

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage(); // 보안 저장소
  WebViewController? _androidWebViewController; // Android WebView Controller
  WebviewController? _windowsWebViewController; // Windows WebView Controller
  bool _isWebViewVisible = false;

  final String naverServerUrl = 'http://223.130.162.100:4525/login/request/naver';
  final String kakaoServerUrl = 'http://223.130.162.100:4525/login/request/kakao';

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      _initializeAndroidWebView();
    } else if (Platform.isWindows) {
      _initializeWindowsWebView();
    }
  }

  void _initializeAndroidWebView() {
    _androidWebViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith("http://223.130.162.100:4525/login/oauth2/code/naver")) {
              _handleRedirectUri(request.url, isNaver: true);
              return NavigationDecision.prevent;
            } else if (request.url.startsWith("http://223.130.162.100:4525/login/oauth2/code/kakao")) {
              print("카카오 이동");
              _handleRedirectUri(request.url, isNaver: false);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );
  }

  Future<void> _initializeWindowsWebView() async {
    _windowsWebViewController = WebviewController();
    try {
      await _windowsWebViewController!.initialize();
      _windowsWebViewController!.url.listen((url) {
        if (url != null && url.startsWith("http://223.130.162.100:4525/login/oauth2/code")) {
          if (url.contains("naver")) {
            _handleRedirectUri(url, isNaver: true);
          } else if (url.contains("kakao")) {
            _handleRedirectUri(url, isNaver: false);
          }
        }
      });
      print("Windows WebView 초기화 성공");
    } catch (e) {
      print("Windows WebView 초기화 실패: $e");
    }
  }

  void _loadWebView(String url) {
    setState(() {
      _isWebViewVisible = true;
    });

    if (Platform.isAndroid && _androidWebViewController != null) {
      _androidWebViewController!.loadRequest(Uri.parse(url));
    } else if (Platform.isWindows && _windowsWebViewController != null) {
      _windowsWebViewController!.loadUrl(url);
    }
  }

  void _loadLoginPage(String serverUrl) async {
    final sessionCookie = await _secureStorage.read(key: 'session_cookie');

    try {
      final response = await http.get(
        Uri.parse(serverUrl),
        headers: {
          if (sessionCookie != null) 'Cookie': 'JSESSIONID=$sessionCookie',
        },
      );
      if (response.statusCode == 200) {
        final loginUrl = response.body;
        _loadWebView(loginUrl);
      } else {
        print('로그인 URL 로딩 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('로그인 요청 중 오류 발생: $e');
    }
  }

  void _loadNaverLoginPage() => _loadLoginPage(naverServerUrl);
  void _loadKakaoLoginPage() => _loadLoginPage(kakaoServerUrl);

  void _handleRedirectUri(String url, {required bool isNaver}) async {
    setState(() {
      _isWebViewVisible = false;
    });

    final sessionCookie = await _secureStorage.read(key: 'session_cookie');
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',

          if (sessionCookie != null) 'Cookie': 'JSESSIONID=$sessionCookie',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['id'] != null && data['access_token'] != null) {
          final isNew = response.headers['isnew'] == "1"; // isNew 값을 가져옴
          print('isNew: $isNew');
          await _saveUserData(
            id: data['id'],
            name: data['name'] ?? '',
            profileImage: data['profile_image'] ?? '',
            accessToken: data['access_token'],
            isNew: isNew, // 추가된 부분
            isNaver: isNaver,
          );

          // 페이지 이동 로직
          if (isNew) {
            print('🆕 신규 회원입니다. Newbie 페이지로 이동합니다.');
            Navigator.pushReplacementNamed(context, '/newbie');
          } else {
            print('✅ 기존 회원입니다. Main 페이지로 이동합니다.');
            Navigator.pushReplacementNamed(context, '/main');
          }
        } else {
          print('❌ 데이터가 올바르지 않습니다: $data');
        }
      } else {
        print('로그인 완료 후 토큰 데이터 요청 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('Redirect 처리 중 오류 발생: $e');
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
            if (_isWebViewVisible)
              Positioned.fill(
                child: Stack(
                  children: [
                    if (Platform.isAndroid)
                      WebViewWidget(controller: _androidWebViewController!),
                    if (Platform.isWindows)
                      Webview(_windowsWebViewController!),
                    Positioned(
                      top: 40,
                      left: 16,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () {
                          setState(() {
                            _isWebViewVisible = false;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
