import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                _buildUserInfo(),
                const SizedBox(width: 16.0), // 사용자 정보와 토큰 사이에 고정된 간격 추가
                _buildTokenInfo(),
              ],
            ),
          ),
          // Shop Icon과 Custom Icon
          Positioned(
            top: MediaQuery.of(context).size.height * 0.2,
            left: 16, // 왼쪽에 고정
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // 아이콘들을 왼쪽 정렬
              children: [
                _buildIconButton(
                  'assets/images/icon/shop_icon.png',
                  onTap: () {
                    print("Shop Icon Clicked");
                  },
                ),
                const SizedBox(height: 8), // 간격
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
  }

  Widget _buildUserInfo() {
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
          const Text(
            '캐릭터 이름',
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
        width: 80, // 아이콘 크기 유지
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle, // 원형으로 유지
          color: Colors.transparent, // 배경 투명
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
