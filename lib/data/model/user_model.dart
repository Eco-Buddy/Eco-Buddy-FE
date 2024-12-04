class UserModel {
  String nickname;
  final int level;
  final String title;
  final String profileImage;
  int points; // 포인트 필드 추가

  UserModel({
    required this.nickname,
    required this.level,
    required this.title,
    required this.profileImage,
    this.points = 0, // 기본값 설정
  });

  // JSON 데이터를 UserModel로 변환
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      nickname: json['nickname'],
      level: json['level'],
      title: json['title'],
      profileImage: json['profile_image'],
      points: json['points'] ?? 0,
    );
  }

  // UserModel을 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'nickname': nickname,
      'level': level,
      'title': title,
      'profile_image': profileImage,
      'points': points, // 포인트 필드 포함
    };
  }
}
