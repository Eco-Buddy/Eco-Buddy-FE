import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'character.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CharacterProvider with ChangeNotifier {
  Character character = Character(
    position: Offset(
      MediaQueryData.fromWindow(WidgetsBinding.instance.window).size.width / 2 - 80, // 가로 중앙
      MediaQueryData.fromWindow(WidgetsBinding.instance.window).size.height / 2 - 80, // 세로 중앙
    ),
  );
  Timer? _walkTimer;
  bool _movingRight = true; // 초기 방향: 오른쪽
  final Random _random = Random();
  final secureStorage = const FlutterSecureStorage(); // Secure Storage 인스턴스

  bool _isDisposed = false; // dispose 상태 추적용 변수

  @override
  void dispose() {
    _isDisposed = true;  // dispose 호출 시 상태 변경
    super.dispose();
  }

  String getCurrentEmotion() {
    return character.emotion;
  }

  void updateEmotion(String emotion) {
    character.updateEmotion(emotion);
    if (emotion == 'sad') {
      stopWalking();  // Stop walking if sad
    }
    notifyListeners();
  }

  Future<void> checkCarbonAndSetEmotion() async {
    final carbonTotalString = await secureStorage.read(key: 'carbonTotal');
    final discountString = await secureStorage.read(key: 'discount');
    if (carbonTotalString != null && discountString != null) {
      final result = double.parse(carbonTotalString) - double.parse(discountString);
      if (result > 10000) {
        updateEmotion('sad');
      } else {
        updateEmotion('normal');
      }
    } else {
      print('응 없어');
    }
  }

  void startWalking(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    _moveCharacter(screenWidth, steps: 1, speed: 100);

    _walkTimer?.cancel();
    _walkTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_isDisposed) return; // 위젯이 dispose되었으면 더 이상 작업을 하지 않음

      checkCarbonAndSetEmotion();
      _movingRight = _random.nextBool(); // 랜덤으로 이동 방향 설정
      int randomSteps = _random.nextInt(3) + 1; // 1~3 걸음 랜덤 설정
      double randomSpeed = _random.nextDouble() * 100 + 50; // 50~150ms 랜덤 속도 설정
      _moveCharacter(screenWidth, steps: randomSteps, speed: randomSpeed);
    });
  }

  void _moveCharacter(double screenWidth, {required int steps, required double speed}) {
    if (character.emotion != 'happy' && character.emotion != 'normal') return; // happy 상태에서만 움직임

    character.isWalking = true;
    character.updateWalkFrame();
    notifyListeners();

    int completedSteps = 0;
    final stepDistance = 15.0;
    final stepTimer = Timer.periodic(Duration(milliseconds: speed.toInt()), (timer) {
      if (_isDisposed) {
        timer.cancel();  // 위젯이 dispose되었으면 타이머 취소
        return;
      }

      if (completedSteps >= steps * 4) {
        timer.cancel();
        character.isWalking = false;
        character.currentImage = _getStaticImageForEmotion(character.emotion);
        notifyListeners();
        return;
      }

      final currentX = character.position.dx;
      if (_movingRight && currentX + stepDistance + 160 >= screenWidth) {
        _movingRight = false;
      } else if (!_movingRight && currentX - stepDistance <= 0) {
        _movingRight = true;
      }

      final newPosition = Offset(
        _movingRight ? currentX + stepDistance : currentX - stepDistance,
        character.position.dy,
      );

      character.moveTo(newPosition, faceRight: !_movingRight);
      character.updateWalkFrame();
      completedSteps++;
      notifyListeners();
    });
  }

  String _getStaticImageForEmotion(String emotion) {
    switch (emotion) {
      case 'happy':
        return 'assets/images/character/happy.png';
      case 'sad':
        return 'assets/images/character/sad.png';
      default:
        return 'assets/images/character/normal.png';
    }
  }

  void stopWalking() {
    _walkTimer?.cancel();
    character.isWalking = false;
    character.currentImage = _getStaticImageForEmotion(character.emotion);
    notifyListeners();
  }
}
