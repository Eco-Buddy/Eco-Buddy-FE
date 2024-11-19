import 'package:flutter/material.dart';
import '../../data/repository/user_repository.dart'; // 사용자 데이터를 불러오기 위한 Repository
import '../../data/model/user_model.dart'; // 사용자 모델

class HomePage extends StatelessWidget {
  final Future<UserModel> user = UserRepository().getUserData();

  HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel>(
      future: user,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('사용자 정보를 불러오는데 실패했습니다.'));
        }

        final userData = snapshot.data!;
        return Scaffold(
          body: Stack(
            children: [
              // 배경 이미지
              Positioned.fill(
                child: Image.asset(
                  'assets/images/background/background_1.png',
                  fit: BoxFit.cover,
                ),
              ),
              // 바닥 이미지
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Image.asset(
                  'assets/images/floor/floor_1.png',
                  fit: BoxFit.cover,
                  height: 150,
                ),
              ),
              // 사용자 정보와 토큰 정보
              Positioned(
                top: 20,
                left: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildUserInfo(userData.nickname),
                    const SizedBox(width: 16.0),
                    _buildTokenInfo(),
                  ],
                ),
              ),
              // Shop Icon과 Custom Icon
              Positioned(
                top: MediaQuery.of(context).size.height * 0.2,
                left: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIconButton(
                      'assets/images/icon/shop_icon.png',
                      onTap: () {
                        print("Shop Icon Clicked");
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildIconButton(
                      'assets/images/icon/custom_icon.png',
                      onTap: () {
                        print("Custom Icon Clicked");
                      },
                    ),
                  ],
                ),
              ),
              // 캐릭터 이미지
              Positioned(
                top: MediaQuery.of(context).size.height * 0.56,
                left: (MediaQuery.of(context).size.width - 160) / 2,
                child: Image.asset(
                  'assets/images/character/happy-1.png',
                  width: 160,
                  height: 160,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserInfo(String nickname) {
    return Container(
      decoration: _buildInfoBoxDecoration(),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFA57C50),
            child: const Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 8.0),
          Text(
            nickname,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTokenInfo() {
    return Container(
      decoration: _buildInfoBoxDecoration(),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.transparent,
            backgroundImage: AssetImage('assets/images/icon/leaf_token.png'),
          ),
          const SizedBox(width: 8.0),
          const Text(
            '10,000',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(String iconPath, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
        ),
        child: Center(
          child: Image.asset(
            iconPath,
            width: 70,
            height: 80,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildInfoBoxDecoration() {
    return BoxDecoration(
      color: const Color(0xFFDCC6A0),
      borderRadius: BorderRadius.circular(25.0),
      border: Border.all(
        color: const Color(0xFFA57C50),
        width: 2,
      ),
    );
  }
}
