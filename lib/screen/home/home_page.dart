import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import '../../provider/pet_provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  final secureStorage = const FlutterSecureStorage();

  Future<String> _loadProfileImage() async {
    final profileImage = await secureStorage.read(key: 'profileImage');
    return profileImage ?? ''; // 기본값으로 빈 문자열 반환
  }

  @override
  Widget build(BuildContext context) {
    final petProvider = Provider.of<PetProvider>(context);

    if (!petProvider.isInitialized) {
      // PetProvider 초기화 중 로딩 화면 표시
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final pet = petProvider.pet;

    return FutureBuilder<String>(
      future: _loadProfileImage(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // 프로필 이미지 로딩 중 로딩 화면 표시
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final profileImage = snapshot.data ?? '';

        return Scaffold(
          body: Stack(
            children: [
              _buildBackground(),
              _buildFloor(),
              Positioned(
                top: 20,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildUserProfile(
                      pet?.petName ?? '귀여운 펫', // Pet 닉네임 표시
                      profileImage,
                    ),
                    _buildTokenInfo(pet?.points ?? 0), // Pet 포인트 표시
                  ],
                ),
              ),
              _buildIcons(context),
              _buildCharacter(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: Image.asset(
        'assets/images/background/background_1.png',
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildFloor() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Image.asset(
        'assets/images/floor/floor_1.png',
        fit: BoxFit.cover,
        height: 150,
      ),
    );
  }

  Widget _buildIcons(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.2,
      left: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIconButton(
            'assets/images/icon/shop_icon.png',
            onTap: () {
              // 상점 버튼 클릭 처리
              print("Shop Icon Clicked");
            },
          ),
          const SizedBox(height: 8),
          _buildIconButton(
            'assets/images/icon/custom_icon.png',
            onTap: () {
              // 커스텀 버튼 클릭 처리
              print("Custom Icon Clicked");
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCharacter() {
    return Positioned(
      top: 300,
      left: (MediaQueryData.fromWindow(WidgetsBinding.instance.window).size.width - 160) / 2,
      child: Image.asset(
        'assets/images/character/happy-1.png',
        width: 160,
        height: 160,
      ),
    );
  }

  Widget _buildUserProfile(String petName, String profileImage) {
    return Container(
      decoration: _buildInfoBoxDecoration(),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFA57C50),
            backgroundImage: profileImage.isNotEmpty
                ? NetworkImage(profileImage) as ImageProvider
                : const AssetImage('assets/images/profile/default.png'),
          ),
          const SizedBox(width: 8.0),
          Text(
            petName,
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

  Widget _buildTokenInfo(int points) {
    return Container(
      decoration: _buildInfoBoxDecoration(),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.transparent,
            backgroundImage: const AssetImage('assets/images/icon/leaf_token.png'),
          ),
          const SizedBox(width: 8.0),
          Text(
            points.toString(),
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

  Widget _buildIconButton(String iconPath, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: const BoxDecoration(
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
