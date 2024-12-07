import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'dart:ui'; // BackdropFilter를 위해 필요
import 'package:provider/provider.dart';
import '../../provider/pet_provider.dart'; // PetProvider 추가

class ShopModal extends StatefulWidget {
  const ShopModal({Key? key}) : super(key: key);

  @override
  _ShopModalState createState() => _ShopModalState();
}

class _ShopModalState extends State<ShopModal> with TickerProviderStateMixin {
  int userPoints = 0; // 사용자 포인트 상태 관리
  final secureStorage = const FlutterSecureStorage();
  final List<String> categories = ['벽지', '바닥'];
  String selectedCategory = '벽지';
  Map<String, List<Map<String, dynamic>>> items = {};
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = BottomSheet.createAnimationController(this);
    _animationController.duration = const Duration(milliseconds: 300);
    _animationController.reverseDuration = const Duration(milliseconds: 300);
    _loadUserPoints();
    _loadItemsFromServer(); // 서버에서 아이템 불러오기
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserPoints() async {
    final petData = await secureStorage.read(key: 'petData');
    if (petData != null) {
      final decodedData = jsonDecode(petData);
      setState(() {
        userPoints = decodedData['points'] ?? 0;
      });
    }
  }

  Future<void> _loadItemsFromServer() async {
    final petProvider = Provider.of<PetProvider>(context, listen: false);
    try {
      final range = selectedCategory == '벽지' ? 1000 : 2000; // 카테고리에 따라 범위 선택
      final itemData = await petProvider.fetchItemsByRange(range); // `await` 추가
      if (itemData.containsKey('usage')) {
        setState(() {
          items[selectedCategory] = (itemData['usage'] as List).map((item) {
            return {
              'id': item['id'],
              'itemId': item['itemId'],
              'name': '아이템 ${item['itemId']}', // 예시 이름 설정
              'image': 'assets/images/items/item_${item['itemId']}.png', // 예시 이미지 경로
              'price': 100, // 예시 가격 설정
              'isPurchased': false, // 구매 여부 초기화
            };
          }).toList();
        });
      } else {
        throw Exception('Invalid item data or missing "usage" key');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('아이템 로드 중 오류 발생: $error'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(
            ),
          ),
        ),
        DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 1.0,
          minChildSize: 0.6,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 24.0,
                      bottom: 8.0,
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'SHOP',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: categories.map((category) {
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedCategory = category;
                                    });
                                    _loadItemsFromServer(); // 카테고리 변경 시 서버에서 재로드
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12.0,
                                      horizontal: 20.0,
                                    ),
                                    margin: const EdgeInsets.symmetric(horizontal: 8.0),
                                    decoration: BoxDecoration(
                                      color: selectedCategory == category
                                          ? Colors.green[400]
                                          : Colors.grey[300],
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                    child: Text(
                                      category,
                                      style: TextStyle(
                                        color: selectedCategory == category
                                            ? Colors.white
                                            : Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16.0,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(width: 16.0),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                                horizontal: 12.0,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCC6A0),
                                borderRadius: BorderRadius.circular(25.0),
                                border: Border.all(
                                  color: const Color(0xFFA57C50),
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.transparent,
                                    backgroundImage: AssetImage('assets/images/icon/leaf_token.png'),
                                  ),
                                  const SizedBox(width: 8.0),
                                  Text(
                                    userPoints.toString(),
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: items[selectedCategory]?.isEmpty ?? true
                        ? const Center(
                      child: Text(
                        '준비 중입니다.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    )
                        : GridView.builder(
                      padding: const EdgeInsets.all(16.0),
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 230, // 카드의 가로 크기를 고정
                        mainAxisSpacing: 16.0, // 세로 간격
                        crossAxisSpacing: 8.0, // 가로 간격
                        mainAxisExtent: 290, // 카드의 세로 크기 고정
                      ),
                      itemCount: items[selectedCategory]?.length ?? 0,
                      itemBuilder: (BuildContext context, int index) {
                        final item = items[selectedCategory]![index];
                        return _buildProductCard(
                          name: item['name'] ?? '',
                          image: item['image'] ?? '',
                          price: item['price'] ?? 0,
                          isPurchased: item['isPurchased'] ?? false,
                          onPurchase: () {
                            if (userPoints >= (item['price'] as int)) {
                              setState(() {
                                userPoints -= item['price'] as int;
                                item['isPurchased'] = true;
                              });
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('포인트가 부족합니다.'),
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, userPoints), // 포인트 반환
                    child: const Text('닫기'),
                  ),
                  const SizedBox(height: 16.0),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildProductCard({
    required String name,
    required String image,
    required int price,
    required bool isPurchased,
    required VoidCallback onPurchase,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
      ),
      child: SizedBox(
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          elevation: 4.0,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center, // 세로 중앙 정렬
              crossAxisAlignment: CrossAxisAlignment.center, // 가로 중앙 정렬
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Image.asset(
                    image,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  name,
                  style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8.0),
                Text(
                  '가격: $price',
                  style: const TextStyle(fontSize: 14.0, color: Colors.black54),
                ),
                const SizedBox(height: 12.0),
                isPurchased
                    ? const Text(
                  '구매 완료',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                )
                    : ElevatedButton(
                  onPressed: onPurchase,
                  child: const Text('구매하기'),
                ),
                const SizedBox(height: 12.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
