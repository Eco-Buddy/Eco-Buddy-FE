import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../provider/pet_provider.dart';
import '../shop/shop_modal.dart';
import './mission_dialog.dart';

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

  Future<List<dynamic>> _loadMissionsJson() async {
    final String response = await rootBundle.loadString('lib/screen/home/missions.json');
    return jsonDecode(response);
  }

  Future<Map<String, dynamic>> _loadItemsJson() async {
    final String response = await rootBundle.loadString('assets/items/items.json');
    return jsonDecode(response);
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
        final petPoints = petData?['points'] ?? 0;
        final backgroundId = petData != null ? petData['background'] : 1001;
        final floorId = petData != null ? petData['floor'] : 2001;

        return FutureBuilder<Map<String, dynamic>>(
          future: _loadItemsJson(),
          builder: (context, itemsSnapshot) {
            if (itemsSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final itemsData = itemsSnapshot.data ?? {};
            final backgroundImage = itemsData['벽지']?.firstWhere(
                  (item) => item['itemId'] == backgroundId,
              orElse: () => {'image': 'assets/items/background/background_1.png'},
            )['image'] ?? 'assets/items/background/background_1.png';

            final floorImage = itemsData['바닥']?.firstWhere(
                  (item) => item['itemId'] == floorId,
              orElse: () => {'image': 'assets/items/floor/floor_1.png'},
            )['image'] ?? 'assets/items/floor/floor_1.png';

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
                      _buildBackground(backgroundImage),
                      _buildFloor(floorImage),
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
                      _buildTrash(context),
                      _buildQuestButton(context),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTrash(BuildContext context) {
    return Positioned(
      bottom: 150,
      left: MediaQueryData.fromWindow(WidgetsBinding.instance.window).size.width / 3,
      child: GestureDetector(
        onTap: () async {
          final missions = await _loadMissionsJson();
          if (missions.isNotEmpty) {
            final mission = (missions..shuffle()).first; // 랜덤 미션
            showDialog(
              context: context,
              builder: (context) {
                return MissionDialog(
                  title: mission['title'],
                  missionRequest: mission['request'],
                  missionContent: "보상: ${mission['reward']} 포인트",
                  missionDescription: mission['description'],
                  onComplete: () async {
                    Navigator.pop(context);

                    // 현재 포인트 가져오기
                    final petData = await _loadPetData();
                    final currentPoints = petData?['points'] ?? 0;
                    // 포인트 갱신
                    final updatedPoints = currentPoints + mission['reward'];

                    // SecureStorage에 업데이트된 포인트 저장
                    if (petData != null) {
                      petData['points'] = updatedPoints;
                      await secureStorage.write(
                        key: 'petData',
                        value: jsonEncode(petData),
                      );
                    }

                    // PetProvider를 통해 포인트 업데이트 및 서버로 동기화
                    await Provider.of<PetProvider>(context, listen: false).updatePetPoints(updatedPoints);
                    print("미션 완료: ${mission['reward']} 포인트 추가, 총 포인트: $updatedPoints");
                  },

                  onLater: () {
                    Navigator.pop(context);
                  },
                );
              },
            );
          }
        },
        child: Image.asset(
          'assets/images/trash/trash_1.png', // 쓰레기 이미지 경로
          width: 50,
          height: 50,
        ),
      ),
    );
  }

  Widget _buildQuestButton(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.2,
      right: 16,
      child: GestureDetector(
        onTap: () {
          print("Quest Button Clicked");
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Quest"),
              content: const Text("퀘스트 관련 내용을 여기에 표시합니다."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("닫기"),
                ),
              ],
            ),
          );
        },
        child: Image.asset(
          'assets/images/icon/quest_icon.png',
          width: 70,
          height: 80,
        ),
      ),
    );
  }

  Widget _buildBackground(String backgroundImage) {
    return Positioned.fill(
      child: Image.asset(
        backgroundImage,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildFloor(String floorImage) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Image.asset(
        floorImage,
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
              // 상점 버튼 클릭 시 Shop Modal 팝업 (애니메이션 포함)
              showModalBottomSheet(
                context: context,
                isScrollControlled: true, // 모달의 크기 조정 가능
                backgroundColor: Colors.transparent,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20.0),
                    topRight: Radius.circular(20.0),
                  ),
                ),
                builder: (BuildContext context) {
                  return const ShopModal();
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
      bottom: 140,
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
