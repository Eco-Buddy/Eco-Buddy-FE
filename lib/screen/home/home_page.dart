import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/user_provider.dart';
import '../shop/shop_modal.dart';
import 'mission_dialog.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isTrashVisible = true; // 쓰레기 활성화 상태

  void _openShopModal(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) => ShopModal(
        currentPoints: userProvider.user?.points ?? 0, // 현재 포인트 전달
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    if (userProvider.user == null) {
      return const Center(child: CircularProgressIndicator());
    }

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
          // 상단 사용자 정보 및 포인트
          Positioned(
            top: 20,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildUserInfo(userProvider),
                const SizedBox(width: 16.0),
                _buildTokenInfo(userProvider),
              ],
            ),
          ),
          // 상점 및 커스텀 버튼
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
          // 쓰레기 미션 버튼
          if (_isTrashVisible)
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
  }

  void _showMissionPopup(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => MissionDialog(
        title: '쓰레기 치우기',
        missionRequest: '다음 미션을 수행해 쓰레기를 치워주세요!',
        missionContent: '메일 20개 삭제',
        missionDescription:
        '메일 1개당 4g의 탄소발자국이 발생합니다.\n20개면 80g을 줄일 수 있겠네요!',
        onComplete: () {
          Navigator.pop(context);

          // 포인트 업데이트 및 쓰레기 상태 변경
          userProvider.updateUserPoints(100);
          setState(() {
            _isTrashVisible = false;
          });

          // 5초 후 쓰레기 다시 활성화
          Future.delayed(const Duration(seconds: 5), () {
            setState(() {
              _isTrashVisible = true;
            });
          });

          _showCompletionDialog(context);
        },
        onLater: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showCompletionDialog(BuildContext context) {
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
  }

  Widget _buildUserInfo(UserProvider userProvider) {
    final user = userProvider.user!;

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
            user.nickname,
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

  Widget _buildTokenInfo(UserProvider userProvider) {
    final user = userProvider.user!;

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
          Text(
            user.points.toString(),
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
