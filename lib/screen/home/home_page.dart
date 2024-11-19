import 'package:flutter/material.dart';
import '../../data/repository/user_repository.dart';
import '../../data/model/user_model.dart';
import '../shop/shop_modal.dart'; // 상점 모달 추가
import 'mission_dialog.dart'; // MissionDialog 임포트

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
              Positioned.fill(
                child: Image.asset(
                  'assets/images/background/background_1.png',
                  fit: BoxFit.cover,
                ),
              ),
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
              Positioned(
                top: MediaQuery.of(context).size.height * 0.2,
                left: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIconButton(
                      'assets/images/icon/shop_icon.png',
                      onTap: () => _openShopModal(context),
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
              Positioned(
                top: MediaQuery.of(context).size.height * 0.56,
                left: (MediaQuery.of(context).size.width - 160) / 2,
                child: Image.asset(
                  'assets/images/character/happy-1.png',
                  width: 160,
                  height: 160,
                ),
              ),
              Positioned(
                bottom: 150,
                left: MediaQuery.of(context).size.width * 0.1,
                child: GestureDetector(
                  onTap: () => _showMissionPopup(context),
                  child: Image.asset(
                    'assets/images/trash/trash_1.png',
                    width: 60,
                    height: 60,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openShopModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) => const ShopModal(),
    );
  }

  void _showMissionPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => MissionDialog(
        title: '쓰레기 치우기',
        missionRequest: '다음 미션을 수행해 쓰레기를 치워주세요!',
        missionContent: '매일 20개 삭제',
        missionDescription: '성공 시 탄소발자국이 감소됩니다.\n매일 미션으로 추가 보상을 얻으세요!',
        onComplete: () {
          Navigator.pop(context);
          _showCompletionDialog(context);
        },
        onLater: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showCompletionDialog(BuildContext context) {
    UserRepository().updateUserPoints(100).then((_) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('미션 완료!'),
          content: const Text('축하합니다! 보상을 획득했습니다. (+100 포인트)'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('확인'),
            ),
          ],
        ),
      );
    }).catchError((error) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('오류'),
          content: Text('포인트 업데이트 중 오류가 발생했습니다: $error'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('확인'),
            ),
          ],
        ),
      );
    });
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
