import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart'; // Android용 WebView
import 'package:webview_windows/webview_windows.dart'; // Windows용 WebView
import 'dart:convert';
import 'package:http/http.dart' as http;

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late WebViewController _androidWebViewController;
  final WebviewController _windowsWebViewController = WebviewController();

  bool _isWebViewVisible = false;

  // API URLs
  final String naverServerUrl = 'http://223.130.162.100:4525/login/request/naver';
  final String kakaoServerUrl = 'http://223.130.162.100:4525/login/request/kakao';

  String? naverUserId;
  String? kakaoUserId;

  @override
  void initState() {
    super.initState();
    if (Platform.isWindows) {
      _initializeWindowsWebView();
    } else if (Platform.isAndroid) {
      _androidWebViewController = WebViewController()
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
    }
  }

  Future<void> _initializeWindowsWebView() async {
    try {
      await _windowsWebViewController.initialize();
      print('Windows WebView initialized successfully');
    } catch (e) {
      print('Failed to initialize Windows WebView: $e');
    }
  }

  void _loadNaverLoginPage() async {
    setState(() {
      _isWebViewVisible = true;
    });

    final response = await http.get(Uri.parse(naverServerUrl));
    if (response.statusCode == 200) {
      String naverLoginUrl = response.body;
      if (Platform.isAndroid) {
        _androidWebViewController.loadRequest(Uri.parse(naverLoginUrl));
      } else if (Platform.isWindows) {
        await _windowsWebViewController.loadUrl(naverLoginUrl);
      }
    } else {
      print('네이버 로그인 URL 로딩 실패');
    }
  }

  void _loadKakaoLoginPage() async {
    setState(() {
      _isWebViewVisible = true;
    });

    final response = await http.get(Uri.parse(kakaoServerUrl));
    if (response.statusCode == 200) {
      String kakaoLoginUrl = response.body;
      if (Platform.isAndroid) {
        _androidWebViewController.loadRequest(Uri.parse(kakaoLoginUrl));
      } else if (Platform.isWindows) {
        await _windowsWebViewController.loadUrl(kakaoLoginUrl);
      }
    } else {
      print('카카오 로그인 URL 로딩 실패');
    }
  }

  void _handleRedirectUri(String url, {required bool isNaver}) async {
    setState(() {
      _isWebViewVisible = false;
    });

    final response = await http.post(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        if (isNaver) {
          naverUserId = data['id'];
        } else {
          kakaoUserId = data['id'];
        }
      });

      print('User ID: ${isNaver ? naverUserId : kakaoUserId}');
    } else {
      print('로그인 완료 후 토큰 데이터 요청 실패');
    }

    Navigator.pushReplacementNamed(context, '/main');
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
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '디지털 탄소 발자국을 줄여보세요!',
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
            if (_isWebViewVisible)
              Platform.isAndroid
                  ? WebViewWidget(controller: _androidWebViewController)
                  : Platform.isWindows
                  ? SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: Webview(_windowsWebViewController), // 수정된 부분
              )
                  : Container(),
          ],
        ),
      ),
    );
  }
}
