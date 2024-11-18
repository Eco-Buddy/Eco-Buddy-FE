import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Naver & Kakao Login App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: NaverLoginScreen(),
    );
  }
}

class NaverLoginScreen extends StatefulWidget {
  @override
  _NaverLoginScreenState createState() => _NaverLoginScreenState();
}

class _NaverLoginScreenState extends State<NaverLoginScreen> {
  late WebViewController _controller;
  bool _isWebViewVisible = false;
  final String naverServerUrl = 'http://223.130.162.100:4525/login/request/naver';
  final String kakaoServerUrl = 'http://223.130.162.100:4525/login/request/kakao';
  final String naverLogoutServerUrl = 'http://223.130.162.100:4525/logout/naver';
  final String kakaoLogoutServerUrl = 'http://223.130.162.100:4525/logout/kakao';

  String? naverUserId;
  String? naverAccessToken;
  String? kakaoUserId;
  String? kakaoAccessToken;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
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

  // 네이버 로그인 페이지 로드
  void _loadNaverLoginPage() async {
    setState(() {
      _isWebViewVisible = true;
    });

    final response = await http.get(Uri.parse(naverServerUrl));
    if (response.statusCode == 200) {
      String naverLoginUrl = response.body;
      _controller.loadRequest(Uri.parse(naverLoginUrl));
    } else {
      print('네이버 로그인 URL 로딩 실패');
    }
  }

  // 카카오 로그인 페이지 로드
  void _loadKakaoLoginPage() async {
    setState(() {
      _isWebViewVisible = true;
    });

    final response = await http.get(Uri.parse(kakaoServerUrl));
    if (response.statusCode == 200) {
      String kakaoLoginUrl = response.body;
      _controller.loadRequest(Uri.parse(kakaoLoginUrl));
    } else {
      print('카카오 로그인 URL 로딩 실패');
    }
  }

  // 네이버 로그아웃
  void _naverLogout() async {
    if (naverUserId != null && naverAccessToken != null) {
      await _clearCookiesAndCache(); // 웹뷰의 쿠키와 캐시를 삭제
      final response = await http.post(
        Uri.parse(naverLogoutServerUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'id': naverUserId,
          'access_token': naverAccessToken,
        }),
      );
      if (response.statusCode == 200) {
        setState(() {
          naverUserId = null;
          naverAccessToken = null;
        });
        print('네이버 로그아웃 성공');
      } else {
        print('네이버 로그아웃 실패');
      }
    } else {
      print('네이버 로그인 정보가 없습니다.');
    }
  }

  // 카카오 로그아웃
  void _kakaoLogout() async {
    if (kakaoUserId != null && kakaoAccessToken != null) {
      await _clearCookiesAndCache(); // 웹뷰의 쿠키와 캐시를 삭제
      final response = await http.post(
        Uri.parse(kakaoLogoutServerUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'id': kakaoUserId,
          'access_token': kakaoAccessToken,
        }),
      );
      if (response.statusCode == 200) {
        setState(() {
          kakaoUserId = null;
          kakaoAccessToken = null;
        });
        print('카카오 로그아웃 성공');
      } else {
        print('카카오 로그아웃 실패');
      }
    } else {
      print('카카오 로그인 정보가 없습니다.');
    }
  }

  // 쿠키와 캐시 삭제 함수
  Future<void> _clearCookiesAndCache() async {
    await _controller.clearCache();
    await WebViewCookieManager().clearCookies();
    print('쿠키와 캐시 삭제 완료');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WillPopScope(
        onWillPop: () async {
          if (_isWebViewVisible) {
            // 웹뷰가 열려 있을 때 뒤로 가기를 누르면 웹뷰를 닫음
            setState(() {
              _clearCookiesAndCache();
              _isWebViewVisible = false;
            });
            return false; // 앱을 종료하지 않음
          }
          return true; // 앱을 종료함
        },
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'ECO Buddy',
                    style: TextStyle(fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.green),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '디지털 탄소 발자국을 줄여보세요!',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 32),
                  // Kakao login button
                  GestureDetector(
                    onTap: () => _loadKakaoLoginPage(),
                    child: Image.asset(
                      'assets/kakao_login_btn.png',
                      // Path to your Kakao login button image
                      width: 240,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Naver login button
                  GestureDetector(
                    onTap: () => _loadNaverLoginPage(),
                    child: Image.asset(
                      'assets/naver_login_btn.png',
                      // Path to your Naver login button image
                      width: 240,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Show user ID and access token
                  if (naverUserId != null || kakaoUserId != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (naverUserId != null) ...[
                            Text('Naver User ID: $naverUserId'),
                            Text('Naver Access Token: $naverAccessToken'),
                          ],
                          if (kakaoUserId != null) ...[
                            Text('Kakao User ID: $kakaoUserId'),
                            Text('Kakao Access Token: $kakaoAccessToken'),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // 웹뷰가 필요할 때만 표시
            _isWebViewVisible
                ? WebViewWidget(controller: _controller)
                : Container(),
          ],
        ),
      ),
    );
  }


  // Redirect URI 핸들링
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
          naverAccessToken = data['access_token'];
        } else {
          kakaoUserId = data['id'];
          kakaoAccessToken = data['access_token'];
        }
      });

      print('User ID: ${isNaver ? naverUserId : kakaoUserId}');
      print('Access Token: ${isNaver ? naverAccessToken : kakaoAccessToken}');
    } else {
      print('로그인 완료 후 토큰 데이터 요청 실패');
    }
  }
}
