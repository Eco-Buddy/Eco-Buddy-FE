import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../provider/pet_provider.dart';
import '../shop/shop_modal.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  final secureStorage = const FlutterSecureStorage();

  Future<String> _loadProfileImage() async {
    final profileImage = await secureStorage.read(key: 'profileImage');
    return profileImage ?? ''; // 기본값으로 빈 문자열 반환
  }

  Future<Map<String, dynamic>?> _loadPetData() async {
    final petData = await secureStorage.read(key: 'petData');
    if (petData != null) {
      return jsonDecode(petData);
    }
    return null;
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

    return FutureBuilder<Map<String, dynamic>?> (
      future: _loadPetData(),
      builder: (context, petSnapshot) {
        if (petSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final petData = petSnapshot.data;
        final petName = petData != null ? petData['petName'] ?? '귀여운 펫' : '귀여운 펫';
        final petPoints = petData != null ? petData['points'] ?? 0 : 0;

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
                          petName, // Pet 닉네임 표시
                          profileImage,
                        ),
                        _buildTokenInfo(petPoints), // Pet 포인트 표시
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
              // 상점 버튼 클릭 시 Shop Modal 팝업
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return ShopModal();
                },
              );
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
