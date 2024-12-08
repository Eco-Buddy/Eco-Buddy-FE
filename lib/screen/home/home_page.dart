import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../provider/pet_provider.dart';
import '../shop/shop_modal.dart';
import '../shop/custom_modal.dart';
import './mission_dialog.dart';
import 'character_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _backgroundImage = '';
  String _floorImage = '';
  String _profileImage = '';
  String _petName = '귀여운 펫';
  int _petPoints = 0;
  late Map<String, dynamic> _itemsData;
  final secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<List<dynamic>> _loadMissionsJson() async {
    try {
      final String response = await rootBundle.loadString('lib/screen/home/missions.json');
      return jsonDecode(response) as List<dynamic>;
    } catch (e) {
      print('Error loading missions JSON: $e');
      return [];
    }
  }

  Future<void> _initializeData() async {
    try {
      final petData = await _loadPetData();
      _itemsData = await _loadItemsJson();

      final backgroundId = petData?['background'] ?? 1001;
      final floorId = petData?['floor'] ?? 2001;

      setState(() {
        _backgroundImage = _getItemImageById('벽지', backgroundId);
        _floorImage = _getItemImageById('바닥', floorId);
        _profileImage = petData?['profileImage'] ?? '';
        _petName = petData?['petName'] ?? '귀여운 펫';
        _petPoints = petData?['points'] ?? 0;
      });
    } catch (e) {
      print('Error initializing data: $e');
    }
  }

  String _getItemImageById(String category, int itemId) {
    try {
      return _itemsData[category]?.firstWhere(
            (item) => item['itemId'] == itemId,
        orElse: () {
          print('Warning: Could not find itemId: $itemId in category: $category');
          return {'image': 'assets/images/default.png'};
        },
      )['image'] ?? 'assets/images/default.png';
    } catch (e) {
      print('Error getting item image for itemId: $itemId in category: $category. Error: $e');
      return 'assets/images/default.png';
    }
  }

  Future<Map<String, dynamic>?> _loadPetData() async {
    final petData = await secureStorage.read(key: 'petData');
    if (petData != null) {
      return jsonDecode(petData);
    }
    return null;
  }

  Future<Map<String, dynamic>> _loadItemsJson() async {
    final String response = await rootBundle.loadString('assets/items/items.json');
    return jsonDecode(response);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(_backgroundImage),
          _buildFloor(_floorImage),
          Positioned(
            top: 20,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildUserProfile(_petName, _profileImage),
                _buildTokenInfo(_petPoints),
              ],
            ),
          ),
          _buildIcons(context),
          _buildCharacter(context),
          _buildTrash(context),
          _buildQuestButton(context),
        ],
      ),
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
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20.0),
                    topRight: Radius.circular(20.0),
                  ),
                ),
                builder: (BuildContext context) {
                  return CustomModal(
                    onItemsSelected: (backgroundId, floorId) {
                      print('Selected backgroundId: $backgroundId, floorId: $floorId');

                      setState(() {
                        if (backgroundId != null) {
                          _backgroundImage = _getItemImageById('벽지', backgroundId);
                        }
                        if (floorId != null) {
                          _floorImage = _getItemImageById('바닥', floorId);
                        }
                      });
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCharacter(BuildContext context) {
    final characterProvider = Provider.of<CharacterProvider>(context);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500),
      bottom: 140, // 바닥 이미지 위
      left: characterProvider.character.position.dx,
      child: GestureDetector(
        onTap: () {
          characterProvider.updateEmotion('happy'); // 감정 변경 예제
        },
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()..scale(characterProvider.character.isFacingRight ? 1.0 : -1.0, 1.0),
          child: Image.asset(
            characterProvider.character.currentImage,
            width: 160,
            height: 160,
          ),
        ),
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
