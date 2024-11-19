import 'package:flutter/material.dart';

class ShopModal extends StatefulWidget {
  const ShopModal({Key? key}) : super(key: key);

  @override
  _ShopModalState createState() => _ShopModalState();
}

class _ShopModalState extends State<ShopModal> {
  // 카테고리 목록
  final List<String> categories = ['벽지', '바닥'];
  String selectedCategory = '벽지'; // 기본 선택된 카테고리

  // 아이템 데이터
  final Map<String, List<Map<String, String>>> items = {
    '벽지': [
      {'name': '벽지 1', 'image': 'assets/images/background/background_1.png'},
      {'name': '벽지 2', 'image': 'assets/images/background/background_2.png'},
    ],
    '바닥': [
      {'name': '바닥 1', 'image': 'assets/images/floor/floor_1.png'},
      {'name': '바닥 2', 'image': 'assets/images/floor/floor_2.png'},
    ],
    '가구': [], // 가구는 준비 중
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 상단 카테고리와 SHOP 텍스트
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 카테고리 버튼
                Row(
                  children: categories.map((category) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCategory = category; // 선택된 카테고리 변경
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 12.0),
                        margin: const EdgeInsets.only(right: 8.0),
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
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const Text(
                  'SHOP',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          // 물품 그리드
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
                childAspectRatio: 0.8,
              ),
              itemCount: items[selectedCategory]?.length ?? 0,
              itemBuilder: (BuildContext context, int index) {
                final item = items[selectedCategory]![index];
                return _buildProductCard(
                  name: item['name']!,
                  image: item['image']!,
                );
              },
            ),
          ),
          const SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard({required String name, required String image}) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      elevation: 4.0,
      child: Column(
        children: [
          Expanded(
            child: Image.asset(
              image,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              name,
              style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
