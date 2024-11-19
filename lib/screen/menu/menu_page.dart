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
  final UserRepository userRepository = UserRepository();

  @override
  void initState() {
    super.initState();
    user = userRepository.getUserData(); // 사용자 데이터 로드
  }

  Future<void> _updateUserName(String newName) async {
    await userRepository.updateUserName(newName);
    setState(() {
      // 사용자 데이터를 다시 로드
      user = userRepository.getUserData();
    });
  }

  Future<void> _showNameChangeDialog(String currentName) async {
    final TextEditingController nameController = TextEditingController();
    nameController.text = currentName;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('이름 변경'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: '새로운 이름 입력'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // 다이얼로그 닫기
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                final newName = nameController.text.trim();
                if (newName.isNotEmpty) {
                  _updateUserName(newName);
                  Navigator.pop(context); // 다이얼로그 닫기
                }
              },
              child: const Text('변경'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearCookiesAndCache() async {
    // 쿠키와 캐시 삭제
    // WebViewController 또는 WebViewCookieManager를 사용하여 캐시와 쿠키 삭제
    print('쿠키와 캐시 삭제 완료');
    // WebViewController.clearCache()와 WebViewCookieManager().clearCookies() 사용 가능
  }

  void _logout() {
    Navigator.pushReplacementNamed(
      context,
      '/login',
      arguments: {'clearCookies': true}, // 로그아웃 시 쿠키 삭제 명령 전달
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '메뉴',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
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
                    onTap: _logout, // 로그아웃 버튼
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
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
                      user.nickname,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text('레벨: ${user.level}', style: const TextStyle(fontSize: 16)),
                    Text('칭호: ${user.title}', style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.green),
              onPressed: () => _showNameChangeDialog(user.nickname),
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
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        subtitle: Text(subtitle),
        onTap: onTap,
      ),
    );
  }
}
