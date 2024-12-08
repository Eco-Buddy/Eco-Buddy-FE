import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'dart:ui'; // BackdropFilter를 위해 필요
import 'package:provider/provider.dart';
import '../../provider/pet_provider.dart'; // PetProvider 추가

class CustomModal extends StatefulWidget {
  const CustomModal({Key? key}) : super(key: key);

  @override
  _CustomModalState createState() => _CustomModalState();
}

class _CustomModalState extends State<CustomModal> with TickerProviderStateMixin {
  Map<String, List<Map<String, dynamic>>> items = {}; // 필터된 아이템 데이터
  late AnimationController _animationController;
  final secureStorage = const FlutterSecureStorage();
  String selectedCategory = '벽지';

  @override
  void initState() {
    super.initState();
    _animationController = BottomSheet.createAnimationController(this);
    _animationController.duration = const Duration(milliseconds: 300);
    _animationController.reverseDuration = const Duration(milliseconds: 300);
    _loadItemsFromServer();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadItemsFromServer() async {
    final petProvider = Provider.of<PetProvider>(context, listen: false);
    try {
      // 1. 캐시된 데이터 확인
      final cachedItems = await secureStorage.read(key: 'cachedItems_$selectedCategory');
      if (cachedItems != null) {
        final cachedData = jsonDecode(cachedItems) as List<dynamic>;
        setState(() {
          items[selectedCategory] = cachedData.map<Map<String, dynamic>>((item) {
            return item as Map<String, dynamic>;
          }).toList();
        });
      }

      // 2. 서버에서 데이터 가져오기
      final range = selectedCategory == '벽지' ? 1000 : 2000;
      final itemData = await petProvider.fetchItemsByRange(range);

      if (itemData.containsKey('items')) {
        final purchasedItemIds = (itemData['items'] as List)
            .map<int>((item) => item['itemId'] as int)
            .toList();

        // items.json에서 아이템 데이터 로드
        final String response = await rootBundle.loadString('assets/items/items.json');
        final data = jsonDecode(response) as Map<String, dynamic>;

        // 3. 서버 데이터와 병합
        final updatedItems = (data[selectedCategory] as List).map<Map<String, dynamic>>((item) {
          final isPurchased = purchasedItemIds.contains(item['itemId']);
          return {
            ...item,
            'isPurchased': isPurchased,
          };
        }).toList();

        // 4. 캐시 업데이트
        await secureStorage.write(
          key: 'cachedItems_$selectedCategory',
          value: jsonEncode(updatedItems),
        );

        // 5. UI 업데이트
        setState(() {
          items[selectedCategory] = updatedItems;
        });
      } else {
        throw Exception('Invalid item data or missing "items" key');
      }
    } catch (error) {
      setState(() {
        items[selectedCategory] = [];
      });
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
            child: Container(),
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
                          'CUSTOM ITEMS',
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
                            ...['벽지', '바닥'].map((category) => GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedCategory = category;
                                  _loadItemsFromServer();
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
                            )),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: items[selectedCategory]?.isEmpty ?? true
                        ? const Center(
                      child: Text(
                        '아이템이 없습니다.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    )
                        : ListView(
                      padding: const EdgeInsets.all(16.0),
                      children: [
                        ...?items[selectedCategory]?.map((item) => _buildItemCard(item)).toList(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
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

  Widget _buildItemCard(Map<String, dynamic> item) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      elevation: 4.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: Image.asset(
                item['image'],
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'] ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    '가격: ${item['price']}',
                    style: const TextStyle(
                      fontSize: 14.0,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
