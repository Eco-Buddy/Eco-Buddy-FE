import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart';
import 'dart:io';

class LogoutManager {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  /// 모든 Secure Storage 데이터 삭제
  Future<void> clearSecureStorage() async {
    try {
      await _secureStorage.deleteAll();
      print('✅ Secure Storage 데이터 삭제 완료');
    } catch (e) {
      print('❌ Secure Storage 데이터 삭제 실패: $e');
    }
  }

  /// WebView 쿠키 및 캐시 삭제(Android/iOS)
  Future<void> clearWebViewCookiesAndCache({WebViewController? androidWebViewController}) async {
    if (androidWebViewController != null) {
      try {
        await androidWebViewController.clearCache();
        await WebViewCookieManager().clearCookies();
        print('✅ Android/iOS WebView 쿠키 및 캐시 삭제 완료');
      } catch (e) {
        print('❌ Android/iOS WebView 쿠키 및 캐시 삭제 실패: $e');
      }
    } else {
      print('❗ Android WebViewController가 설정되지 않았습니다.');
    }
  }

  /// WebView 쿠키 및 캐시 삭제(Windows)
  Future<void> clearWindowsWebViewCookiesAndCache(WebviewController? windowsWebViewController) async {
    if (windowsWebViewController != null && windowsWebViewController.value.isInitialized) {
      try {
        await windowsWebViewController.clearCache();
        print('✅ Windows WebView 쿠키 및 캐시 삭제 완료');
      } catch (e) {
        print('❌ Windows WebView 쿠키 및 캐시 삭제 실패: $e');
      }
    } else {
      print('❗ Windows WebViewController가 초기화되지 않았습니다.');
    }
  }

  /// 로그아웃 처리
  Future<void> performLogout({
    WebViewController? androidWebViewController,
    WebviewController? windowsWebViewController,
  }) async {
    try {
      print('🟢 로그아웃 시작');

      // Secure Storage 데이터 삭제
      await clearSecureStorage();

      // WebView 쿠키 및 캐시 삭제
      if (Platform.isAndroid) {
        await clearWebViewCookiesAndCache(androidWebViewController: androidWebViewController);
      } else if (Platform.isWindows) {
        await clearWindowsWebViewCookiesAndCache(windowsWebViewController);
      }

      print('✅ 로그아웃 완료');
    } catch (e) {
      print('❌ 로그아웃 중 오류 발생: $e');
    }
  }
}
