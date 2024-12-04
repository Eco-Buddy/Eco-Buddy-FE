import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import '../../provider/pet_provider.dart';
import 'dart:convert'; // 추가: jsonDecode 함수 사용을 위한 패키지

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  final secureStorage = const FlutterSecureStorage();

  /// SecureStorage에서 펫 데이터를 가져오는 함수
  Future<Map<String, dynamic>?> _loadPetData() async {
    final petData = await secureStorage.read(key: 'petData');
    if (petData != null) {
      return jsonDecode(petData); // JSON 문자열을 Map<String, dynamic>으로 변환
    }
    return null; // 데이터가 없으면 null 반환
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _loadPetData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // 데이터 로딩 중 로딩 화면 표시
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          // 에러가 발생한 경우
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '펫 데이터를 불러오는 중 오류가 발생했습니다.',
                    style: TextStyle(fontSize: 16, color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _loadPetData(), // 다시 시도
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            ),
          );
        }

        final petData = snapshot.data;

        if (petData == null) {
          // 펫 데이터가 없는 경우
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '저장된 펫 데이터가 없습니다.',
                    style: TextStyle(fontSize: 16, color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        }

        // 펫 데이터가 존재하는 경우
        final petName = petData['petName'] ?? '알 수 없는 펫';
        final petLevel = petData['petLevel'] ?? 0;
        final points = petData['points'] ?? 0;

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
                    _buildUserProfile(petName, petLevel),
                    _buildTokenInfo(points),
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

  Future<String> _loadProfileImage() async {
    final profileImage = await secureStorage.read(key: 'profileImage');
    return profileImage ?? ''; // 저장된 프로필 이미지가 없으면 빈 문자열 반환
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

  Widget _buildUserProfile(String petName, int petLevel) {
    return FutureBuilder<String>(
      future: _loadProfileImage(),
      builder: (context, snapshot) {
        final profileImage = snapshot.data ?? '';

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    petName,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '레벨: $petLevel',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
