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

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      nickname: json['nickname'] ?? '알 수 없음',
      level: json['level'] ?? 0,
      title: json['title'] ?? '알 수 없음',
      profileImage: json['profile_image'] ?? 'assets/images/profile/default.png',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nickname': nickname,
      'level': level,
      'title': title,
      'profile_image': profileImage,
    };
  }
}
