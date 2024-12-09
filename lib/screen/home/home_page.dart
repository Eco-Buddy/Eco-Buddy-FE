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
import './quest_dialog.dart';
import 'character_provider.dart';
import 'quest_dialog.dart';  // 퀘스트 다이얼로그
import 'package:intl/intl.dart'; // 시간을 비교하고 포맷을 지정하기 위한 라이브러리
import 'package:login_test/screen/home/sad_mood_dialog.dart';  // 임포트 추가

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = true;
  String _backgroundImage = "assets/items/background/background_1.png";
  String _floorImage = "assets/items/floor/floor_1.png";
  String _profileImage = "assets/images/profile/default.png";
  String _userName = '사용자 이름';
  late Map<String, dynamic> _itemsData;
  final secureStorage = const FlutterSecureStorage();
  late CharacterProvider _characterProvider;
  int userPoints = 0; // 홈 페이지에서 관리할 포인트
  String _emotionText = ''; // 감정을 저장할 텍스트
  bool _showTrash = false; // 쓰레기 아이콘을 보일지 여부
  static const _missionCooldown = Duration(seconds: 5); // 미션 쿨다운 시간 (30분)

  @override
  void initState() {
    super.initState();
    _initializeData();
    _checkTrashCooldown();
    _updatePetPoints();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final characterProvider = Provider.of<CharacterProvider>(context, listen: false);
      // Secure Storage에서 carbonTotal과 discount를 읽음
      characterProvider.updateEmotion('normal');
      characterProvider.startWalking(context);
    });
  }

  Future<void> _updatePetPoints() async {
    final petProvider = Provider.of<PetProvider>(context, listen: false);
    // petPoints 값 업데이트
    setState(() {
      userPoints = petProvider.pet.points; // PetProvider에서 포인트 가져오기
    });
    print("포인트 변경됨:");
  }

  Future<void> _checkCharacterEmotion() async {
    if (_characterProvider.getCurrentEmotion() == 'sad') {
      // 감정이 sad일 때 다이얼로그 띄우기
      showDialog(
        context: context,
        builder: (context) => SadMoodDialog(
          onQuizSelected: () {
            // 퀴즈 풀기 선택 시 처리
            showDialog(
              context: context,
              builder: (context) => QuestDialog(),
            );
          },
          onCoinSelected: () async {
            // 코인 소모하기 선택 시 처리
            final secureStorage = FlutterSecureStorage();
            final String? carbonTotal = await secureStorage.read(key: 'carbonTotal');
            final discount = await secureStorage.read(key: 'discount');
            if (carbonTotal != null && discount != null) {
              final result = double.tryParse(carbonTotal) ?? 0.0;
              final coinCost = (result / 10000).toInt() * 100;  // 코인 계산

              final petProvider = Provider.of<PetProvider>(context, listen: false);
              if (petProvider.petPoints >= coinCost) {
                await petProvider.updatePetPoints(petProvider.petPoints - coinCost);
              } else {
                print("포인트 부족");
              }
            }
          },
        ),
      );
    }
  }

  Future<void> _checkTrashCooldown() async {
    final lastMissionTimeString = await secureStorage.read(key: 'lastMissionTime');
    if (lastMissionTimeString != null) {
      print(lastMissionTimeString);
      final lastMissionTime = DateTime.parse(lastMissionTimeString);
      final currentTime = DateTime.now();
      final timeDifference = currentTime.difference(lastMissionTime);

      if (timeDifference >= _missionCooldown) {
        setState(() {
          _showTrash = true; // 일정 시간이 지나면 쓰레기 아이콘을 다시 보이도록 설정
        });
      }
    } else {
      // lastMissionTime이 null이면 첫 실행이므로, 바로 쓰레기 아이콘을 표시
      print('null');
      setState(() {
        _showTrash = true;
      });
    }
  }

  Future<void> _onMissionComplete(int reward) async {
    final petProvider = Provider.of<PetProvider>(context, listen: false);
    final updatedPoints = petProvider.petPoints + reward;

    // 포인트 갱신
    await petProvider.updatePetPoints(updatedPoints);

    // 현재 시간을 secureStorage에 저장 (미션 완료 시간)
    await secureStorage.write(key: 'lastMissionTime', value: DateTime.now().toIso8601String());

    // 쓰레기 아이콘을 숨김
    setState(() {
      _showTrash = false;
    });
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

    setState(() {
      _isLoading = true; // Start loading
    });

    try {
      final userData = await _loadUserData();
      _itemsData = await _loadItemsJson();

      final petDataString = await secureStorage.read(key: 'petData');
      if (petDataString != null) {
        final petData = jsonDecode(petDataString);

        // PetProvider 초기값 설정
        final petProvider = Provider.of<PetProvider>(context, listen: false);
        petProvider.setPet(Pet.fromJson(petData)); // Provider와 동기화
      }

      final backgroundId = userData['background'] ?? 1001;
      final floorId = userData['floor'] ?? 2001;

      setState(() {
        _backgroundImage = _getItemImageById('벽지', backgroundId);
        _floorImage = _getItemImageById('바닥', floorId);
        _profileImage = userData['profileImage'] ?? '';
        _userName = userData['userName'] ?? '사용자 이름';

        _isLoading = false; // End loading
      });
    } catch (e) {
      setState(() {
        _isLoading = false; // End loading in case of error
      });
      print('Error initializing data: $e');
    }
  }

  Future<Map<String, dynamic>> _loadUserData() async {
    final profileImage = await secureStorage.read(key: 'profileImage') ?? '';
    final userName = await secureStorage.read(key: 'userName') ?? '사용자 이름';
    final petDataString = await secureStorage.read(key: 'petData');
    Map<String, dynamic> petData = {};
    if (petDataString != null) {
      petData = jsonDecode(petDataString);
    }
    return {
      'profileImage': profileImage,
      'userName': userName,
      'background': petData['background'],
      'floor': petData['floor'],
    };
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

  Future<Map<String, dynamic>> _loadItemsJson() async {
    final String response = await rootBundle.loadString('assets/items/items.json');
    return jsonDecode(response);
  }

  @override
  Widget build(BuildContext context) {
    final petProvider = Provider.of<PetProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          // If _isLoading is true, show a loading indicator
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(), // Show loading spinner
            ),

          _buildBackground(_backgroundImage),
          _buildFloor(_floorImage),
          _buildCharacter(context),
          Positioned(
            top: 30,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildUserProfile(petProvider.petName, _profileImage),
                Consumer<PetProvider>(
                  builder: (context, petProvider, child) {
                    return _buildTokenInfo(petProvider.petPoints);
                  },
                ),
              ],
            ),
          ),
          _buildIcons(context),
          if (_showTrash) _buildTrash(context), // 쓰레기 아이콘이 보일 때만 표시
          _buildQuestButton(context),
        ],
      ),
    );
  }

  Widget _buildTrash(BuildContext context) {
    final petProvider = Provider.of<PetProvider>(context);
    return Positioned(
      bottom: 120,
      left: MediaQueryData.fromWindow(WidgetsBinding.instance.window).size.width * 4 / 5,
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

                    // 포인트 갱신
                    final updatedPoints = petProvider.petPoints + (mission['reward'] as int);
                    print("미션 완료: ${mission['reward']} 포인트 추가, 총 포인트: $updatedPoints");
                    await _onMissionComplete(mission['reward'] as int); // 미션 완료 처리
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
        onTap: () async {
          print("Quest Button Clicked");

          await showDialog(
            context: context,
            builder: (context) => QuestDialog(),
          );
          // Secure Storage에서 포인트 갱신
          final secureStorage = FlutterSecureStorage();
          final String? updatedPoints = await secureStorage.read(key: 'points');
          if (updatedPoints != null) {
            final petProvider = Provider.of<PetProvider>(context, listen: false);
            petProvider.updatePetPoints(int.parse(updatedPoints));
            print('퀘스트 창 닫힘 후 포인트 갱신됨: $updatedPoints');
          }
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
        height: 130,
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
          const SizedBox(height: 12),

          _buildIconButton(
            'assets/images/icon/custom_icon.png',
            onTap: () async {  // 여기에서 onTap을 async로 변경
              await showModalBottomSheet(
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
                    onItemsSelected: (backgroundId, floorId) async {  // 이 부분도 async로 변경
                      print('Selected backgroundId: $backgroundId, floorId: $floorId');

                      setState(() {
                        if (backgroundId != null) {
                          _backgroundImage = _getItemImageById('벽지', backgroundId);
                        }
                        if (floorId != null) {
                          _floorImage = _getItemImageById('바닥', floorId);
                        }
                      });

                      final petDataString = await secureStorage.read(key: 'petData');
                      Map<String, dynamic> petData = petDataString != null ? jsonDecode(petDataString) : {};

                      // Update the petData with new background and floor
                      petData['background'] = backgroundId;
                      petData['floor'] = floorId;
                      await secureStorage.write(key: 'petData', value: jsonEncode(petData));

                      print('Updated petData: $petData');
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
      bottom: 120, // 바닥 이미지 위
      left: characterProvider.character.position.dx,
      child: GestureDetector(
        onTap: () {
          print('현재 감정: ${characterProvider.getCurrentEmotion()}'); // 클릭 시 로그 확인
          characterProvider.checkCarbonAndSetEmotion();
          if (characterProvider.getCurrentEmotion() == 'sad') {
            showDialog(
              context: context,
              builder: (context) {
                return SadMoodDialog(
                  onQuizSelected: () {
                    // 퀴즈 풀기 선택 시 처리
                    showDialog(
                      context: context,
                      builder: (context) => QuestDialog(),
                    );
                  },
                  onCoinSelected: () async {
                    // 코인 소모하기 선택 시 처리
                    final secureStorage = FlutterSecureStorage();
                    final String? carbonTotal = await secureStorage.read(
                        key: 'carbonTotal');
                    final discount = await secureStorage.read(key: 'discount');
                    if (carbonTotal != null && discount != null) {
                      final result = double.tryParse(carbonTotal) ?? 0.0;
                      final coinCost = (result / 10000).toInt() * 100; // 코인 계산

                      final petProvider = Provider.of<PetProvider>(
                          context, listen: false);
                      if (petProvider.petPoints >= coinCost) {
                        await petProvider.updatePetPoints(petProvider
                            .petPoints - coinCost);
                        print("코인 소모: $coinCost, 남은 포인트: ${petProvider
                            .petPoints - coinCost}");
                      } else {
                        print("포인트 부족");
                      }
                    }
                  },
                );
              },
            );
          }
        },
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()..scale(characterProvider.character.isFacingRight ? 1.0 : -1.0, 1.0),
          child: Image.asset(
            characterProvider.character.currentImage,
            width: 140,
            height: 140,
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfile(String petName, String profileImage) {
    return Container(
      decoration: _buildInfoBoxDecoration(),
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFA57C50),
            backgroundImage: profileImage.startsWith('http')
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
    return Consumer<PetProvider>(
      builder: (context, petProvider, child) {
        return GestureDetector(
          onTap: () async {
            // 토큰 아이콘 클릭 시 printAllSecureStorage() 호출
            await petProvider.printAllSecureStorage();
            // 필요 시 알림창 표시
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('SecureStorage 내용이 콘솔에 출력되었습니다.')),
            );
          },
          child: Container(
            decoration: _buildInfoBoxDecoration(),
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.transparent,
                  backgroundImage:
                  const AssetImage('assets/images/icon/leaf_token.png'),
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
          ),
        );
      },
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
