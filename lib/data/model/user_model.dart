class UserModel {
  final String nickname;
  final int level;
  final String title;
  final String profileImage;

  UserModel({
    required this.nickname,
    required this.level,
    required this.title,
    required this.profileImage,
  });

  // JSON 데이터를 UserModel로 변환
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      nickname: json['nickname'],
      level: json['level'],
      title: json['title'],
      profileImage: json['profile_image'],
    );
  }

  // UserModel을 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'nickname': nickname,
      'level': level,
      'title': title,
      'profile_image': profileImage,
    };
  }
}
