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
  String getCurrentEmotion() {
    return character.emotion;
  }
  void updateEmotion(String emotion) {
    // Update character's emotion and stop walking if 'sad'
    character.updateEmotion(emotion);
    if (emotion == 'sad') {
      stopWalking();  // Stop walking if sad
    }
    notifyListeners();
  }

  Future<void> checkCarbonAndSetEmotion() async {
    // Secure Storage에서 carbonTotal과 discount를 읽어옴
    final carbonTotalString = await secureStorage.read(key: 'carbonTotal');
    final discountString = await secureStorage.read(key: 'discount');

    // 값이 존재하면 파싱하여 계산
    if (carbonTotalString != null && discountString != null) {
      final carbonTotal = double.tryParse(carbonTotalString) ?? 0.0;
      final discount = double.tryParse(discountString) ?? 0.0;

      // 탄소 발생량 계산 (carbonTotal - discount)
      final result = carbonTotal - discount;
      print(result);
      // 탄소 발생량이 10000보다 크면 'sad', 그렇지 않으면 'normal'
      if (result > 10000) {
        updateEmotion('sad');
        print('탄소 발생량이 10000보다 큽니다. 감정은 sad');
      } else {
        updateEmotion('normal');
        print('탄소 발생량이 10000 이하입니다. 감정은 normal');
      }
    }
  }

  void startWalking(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    print('Walking started with screenWidth: $screenWidth'); // 디버깅 로그
    checkCarbonAndSetEmotion();
    // 여기서 캐릭터가 처음 시작할 때부터 걷기 시작
    _moveCharacter(screenWidth, steps: 1, speed: 100); // 한번의 작은 걸음으로 시작

    _walkTimer?.cancel();
    _walkTimer = Timer.periodic(const Duration(seconds: 3), (_) {

      print('Timer triggered');
      _movingRight = _random.nextBool(); // 랜덤으로 이동 방향 설정
      int randomSteps = _random.nextInt(3) + 1; // 1~3 걸음 랜덤 설정
      double randomSpeed = _random.nextDouble() * 100 + 50; // 50~150ms 랜덤 속도 설정
      _moveCharacter(screenWidth, steps: randomSteps, speed: randomSpeed); // 랜덤 걸음 수와 속도 적용
    });
  }


  void _moveCharacter(double screenWidth, {required int steps, required double speed}) {
    if (character.emotion != 'happy' && character.emotion != 'normal')  return; // happy 상태에서만 움직임

    character.isWalking = true; // 걷는 상태로 변경
    character.updateWalkFrame(); // 걷기 애니메이션 초기화
    notifyListeners();

    int completedSteps = 0;
    final stepDistance = 15.0; // 한 번에 움직일 거리
    final stepTimer = Timer.periodic(Duration(milliseconds: speed.toInt()), (timer) {
      if (completedSteps >= steps*4) {
        timer.cancel(); // 모든 걸음 완료 시 타이머 취소
        character.isWalking = false;
        character.currentImage = _getStaticImageForEmotion(character.emotion); // 기본 이미지로 복원
        notifyListeners();
        return;
      }

      final currentX = character.position.dx;
      if (_movingRight && currentX + stepDistance + 160 >= screenWidth) {
        _movingRight = false; // 오른쪽 경계 도달 시 방향 변경
      } else if (!_movingRight && currentX - stepDistance <= 0) {
        _movingRight = true; // 왼쪽 경계 도달 시 방향 변경 및
      }

      final newPosition = Offset(
        _movingRight ? currentX + stepDistance : currentX - stepDistance, // 방향 수정
        character.position.dy,
      );

      character.moveTo(newPosition, faceRight: !_movingRight); // 방향에 따라 시선 반전
      character.updateWalkFrame(); // 걷기 애니메이션 프레임 업데이트
      if (completedSteps >= steps * 4) { // 걸음 수 * 프레임 수 완료
        timer.cancel();
        character.isWalking = false;
        character.currentImage = _getStaticImageForEmotion(character.emotion); // 기본 이미지로 복원
        notifyListeners();
        return;
      }
      notifyListeners();
      completedSteps++;
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
    character.currentImage = _getStaticImageForEmotion(character.emotion); // 기본 이미지로 복원
    notifyListeners();
  }
}
