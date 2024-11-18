import 'package:flutter/material.dart';
import '../../data/repository/user_repository.dart';
import '../../data/model/user_model.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({Key? key}) : super(key: key);

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  late Future<UserModel> user;

  @override
  void initState() {
    super.initState();
    user = UserRepository().getUserData(); // 사용자 데이터 로드
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '메뉴',
          style: TextStyle(
            fontWeight: FontWeight.bold, // Bold 적용
            color: Colors.white, // 하얀색 글자
          ),
        ),
        backgroundColor: Colors.green[400],
      ),
      body: FutureBuilder<UserModel>(
        future: user,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('사용자 정보를 불러오는데 실패했습니다.'));
          }

          final userData = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // 사용자 프로필 카드
              _buildUserProfile(userData),
              const SizedBox(height: 16.0),
              // 메뉴 섹션
              _buildMenuSection(
                title: '일반 설정',
                items: [
                  _buildMenuItem(
                    context,
                    icon: Icons.settings,
                    title: '설정',
                    subtitle: '알림, 개인정보 등',
                    onTap: () {
                      Navigator.pushNamed(context, '/settings');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              _buildMenuSection(
                title: '환경 꿀팁',
                items: [
                  _buildMenuItem(
                    context,
                    icon: Icons.info,
                    title: '앱 소개',
                    subtitle: '앱에 대해 알아보기',
                    onTap: () {
                      Navigator.pushNamed(context, '/about');
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.lightbulb,
                    title: '환경 꿀팁',
                    subtitle: '환경을 지키는 꿀팁 확인',
                    onTap: () {
                      Navigator.pushNamed(context, '/ecoTips');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              _buildMenuSection(
                title: '기타',
                items: [
                  _buildMenuItem(
                    context,
                    icon: Icons.notifications,
                    title: '알림 관리',
                    subtitle: '앱 알림 설정',
                    onTap: () {
                      Navigator.pushNamed(context, '/notifications');
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.help_outline,
                    title: '도움말 / FAQ',
                    subtitle: '자주 묻는 질문',
                    onTap: () {
                      Navigator.pushNamed(context, '/faq');
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.exit_to_app,
                    title: '로그아웃',
                    subtitle: '현재 계정에서 로그아웃',
                    onTap: () {
                      Navigator.pushNamed(context, '/login');
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.lightbulb,
                    title: '쓰레기 생성',
                    subtitle: '미션 생성을 위한 쓰레기 생성',
                    onTap: () {
                      Navigator.pushNamed(context, '/makeTrash');
                    },
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUserProfile(UserModel user) {
    return Card(
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: AssetImage(user.profileImage),
            ),
            const SizedBox(width: 16.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${user.nickname}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text('레벨: ${user.level}', style: const TextStyle(fontSize: 16)),
                Text('칭호: ${user.title}', style: const TextStyle(fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection({
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8.0),
        ...items,
      ],
    );
  }

  Widget _buildMenuItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
      }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.green, size: 36),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold, // Bold 적용
            color: Colors.black, // 하얀색 적용하려면 여기 수정
          ),
        ),
        subtitle: Text(subtitle),
        onTap: onTap,
      ),
    );
  }
}
