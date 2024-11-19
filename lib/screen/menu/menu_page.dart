import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/user_provider.dart';
import '../../data/model/user_model.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    if (userProvider.user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final user = userProvider.user!;

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
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 사용자 프로필 카드
          _buildUserProfile(context, userProvider, user),
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
                onTap: () => _logout(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfile(
      BuildContext context, UserProvider userProvider, UserModel user) {
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
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text('레벨: ${user.level}',
                        style: const TextStyle(fontSize: 16)),
                    Text('칭호: ${user.title}',
                        style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.green),
              onPressed: () => _showNameChangeDialog(context, userProvider),
            ),
          ],
        ),
      ),
    );
  }

  void _showNameChangeDialog(
      BuildContext context, UserProvider userProvider) {
    final TextEditingController nameController =
    TextEditingController(text: userProvider.user?.nickname ?? '');

    showDialog(
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
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                final newName = nameController.text.trim();
                if (newName.isNotEmpty) {
                  userProvider.updateUserName(newName);
                  Navigator.pop(context);
                }
              },
              child: const Text('변경'),
            ),
          ],
        );
      },
    );
  }

  void _logout(BuildContext context) {
    Navigator.pushReplacementNamed(
      context,
      '/login',
      arguments: {'clearCookies': true},
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
