import 'package:flutter/material.dart';

class Character {
  String emotion; // 'happy', 'normal', 'sad'
  Offset position; // 현재 위치
  int walkFrameIndex; // 걸어다니기 애니메이션 프레임 인덱스
  bool isWalking; // 캐릭터가 걷고 있는지 여부
  String currentImage; // 현재 표시할 이미지
  bool isFacingRight; // 캐릭터가 오른쪽을 보고 있는지 여부

  Character({
    this.emotion = 'normal',
    this.position = const Offset(0, 0),
    this.walkFrameIndex = 0,
    this.isWalking = false,
    this.isFacingRight = true, // 기본적으로 오른쪽을 보고 있음
  }) : currentImage = 'assets/images/character/normal.png';

  void updateEmotion(String newEmotion) {
    emotion = newEmotion;
    currentImage = _getStaticImageForEmotion(newEmotion);
  }

  void moveTo(Offset newPosition, {bool faceRight = true}) {
    if (emotion != 'sad') {
      position = newPosition;
      isWalking = true;
      isFacingRight = faceRight; // 이동 방향에 따라 시선 변경
    } else {
      isWalking = false; // 슬픈 상태에서는 움직이지 않음
    }
  }

  void updateWalkFrame() {
    if (isWalking) {
      walkFrameIndex = (walkFrameIndex + 1) % 4; // 4프레임 반복
      currentImage = _getWalkImageForEmotion(emotion, walkFrameIndex);
    } else {
      currentImage = _getStaticImageForEmotion(emotion);
    }
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

  String _getWalkImageForEmotion(String emotion, int frameIndex) {
    return 'assets/images/character/${emotion}-walk${frameIndex + 1}.png';
  }
}