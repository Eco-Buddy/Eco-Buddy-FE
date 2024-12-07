import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:ui'; // BackdropFilter를 위해 필요

class ShopModal extends StatefulWidget {
  const ShopModal({Key? key}) : super(key: key);

  @override
  _ShopModalState createState() => _ShopModalState();
}

class _ShopModalState extends State<ShopModal> {
  int userPoints = 0; // 사용자 포인트 상태 관리
  final secureStorage = const FlutterSecureStorage();
  final List<String> categories = ['벽지', '바닥'];
  String selectedCategory = '벽지';

  final Map<String, List<Map<String, dynamic>>> items = {
    '벽지': [
      {
        'name': '벽지 1',
        'image': 'assets/images/background/background_1.png',
        'price': 0,
        'isPurchased': false,
      },
      {
        'name': '벽지 2',
        'image': 'assets/images/background/background_2.png',
        'price': 0,
        'isPurchased': false,
      },
    ],
    '바닥': [
      {
        'name': '바닥 1',
        'image': 'assets/images/floor/floor_1.png',
        'price': 0,
        'isPurchased': false,
      },
      {
        'name': '바닥 2',
        'image': 'assets/images/floor/floor_2.png',
        'price': 0,
        'isPurchased': false,
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadUserPoints();
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),
        ),
        DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.9,
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
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16.0,
                        crossAxisSpacing: 16.0,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: items[selectedCategory]?.length ?? 0,
                      itemBuilder: (BuildContext context, int index) {
                        final item = items[selectedCategory]![index];
                        return _buildProductCard(
                          name: item['name']!,
                          image: item['image']!,
                          price: item['price'],
                          isPurchased: item['isPurchased'],
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
    return Container(
      width: 160,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        elevation: 4.0,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
            ],
          ),
        ),
      ),
    );
  }
}
