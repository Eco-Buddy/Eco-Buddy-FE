import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../provider/pet_provider.dart'; // PetProvider 추가

class CustomModal extends StatefulWidget {
  final Function(int? backgroundId, int? floorId) onItemsSelected; // Add callback

  const CustomModal({Key? key, required this.onItemsSelected}) : super(key: key);

  @override
  _CustomModalState createState() => _CustomModalState();
}

class _CustomModalState extends State<CustomModal> with TickerProviderStateMixin {
  Map<String, List<Map<String, dynamic>>> items = {}; // 필터된 아이템 데이터
  final secureStorage = const FlutterSecureStorage();
  String selectedCategory = '벽지';
  int? selectedBackgroundId;
  int? selectedFloorId;

  @override
  void initState() {
    super.initState();
    _loadSelectedItems();
    _loadItemsFromServer();
  }

  Future<void> _loadSelectedItems() async {
    final petData = await secureStorage.read(key: 'petData');
    if (petData != null) {
      final decodedData = jsonDecode(petData);
      setState(() {
        selectedBackgroundId = decodedData['background'];
        selectedFloorId = decodedData['floor'];
      });
    }
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
      print('테스트');

      if (itemData.containsKey('items')) {
        final purchasedItemIds = (itemData['items'] as List)
            .map<int>((item) => item['itemId'] as int)
            .toList();

        // 3. items.json에서 아이템 데이터 로드
        final String response = await rootBundle.loadString('assets/items/items.json');
        final data = jsonDecode(response) as Map<String, dynamic>;

        // 4. 서버 데이터와 병합 후 purchasedItemIds에 포함된 아이템만 필터링
        final updatedItems = (data[selectedCategory] as List).where((item) {
          final itemId = item['itemId'];
          return purchasedItemIds.contains(itemId); // purchasedItemIds에 포함된 아이템만 표시
        }).map<Map<String, dynamic>>((item) {
          final isPurchased = purchasedItemIds.contains(item['itemId']);
          return {
            ...item,
            'isPurchased': isPurchased,
          };
        }).toList();

        // 5. 캐시 업데이트
        await secureStorage.write(
          key: 'cachedItems_$selectedCategory',
          value: jsonEncode(updatedItems),
        );

        // 6. UI 업데이트
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
    return WillPopScope(
      onWillPop: () async {
        // 모달이 닫힐 때 선택된 데이터 반환 및 로그 출력
        print('Closing modal with selection: backgroundId=$selectedBackgroundId, floorId=$selectedFloorId');
        Navigator.pop(context, {
          'backgroundId': selectedBackgroundId,
          'floorId': selectedFloorId,
        });
        return true;
      },
      child: Align(
        alignment: Alignment.bottomCenter,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 220,
          width: MediaQuery.of(context).size.width, // 가로를 화면 전체로 설정
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: ['벽지', '바닥'].map((category) {
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
                    ElevatedButton(
                      onPressed: () async {
                        if (selectedBackgroundId == null || selectedFloorId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('아이템을 선택하세요.')),
                          );
                          return;
                        }
                        print('Final selection: backgroundId: $selectedBackgroundId, floorId: $selectedFloorId');

                        // PetProvider를 통해 서버로 데이터 전달
                        final petProvider = Provider.of<PetProvider>(context, listen: false);
                        await petProvider.updateBackgroundAndFloor(selectedBackgroundId!, selectedFloorId!);
                        Navigator.pop(context, {
                          'backgroundId': selectedBackgroundId,
                          'floorId': selectedFloorId,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green, // 버튼 색상
                        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0), // Vertical and Horizontal Padding
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0), // Rounded corners to match category buttons
                        ),
                      ),
                      child: const Text(
                        '결정',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                          color: Colors.white,
                        ),
                      ),
                    )
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  children: items[selectedCategory]?.map((item) => _buildItemCard(item)).toList() ?? [],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final isSelected = (selectedCategory == '벽지' && item['itemId'] == selectedBackgroundId) ||
        (selectedCategory == '바닥' && item['itemId'] == selectedFloorId);

    return GestureDetector(
      onTap: () {
        setState(() {
          // 카테고리에 따라 선택된 아이템 ID 저장
          if (selectedCategory == '벽지') {
            selectedBackgroundId = item['itemId'];
          } else {
            selectedFloorId = item['itemId'];
          }
        });

        print('Item selected: ${item['name']}, ID: ${item['itemId']}');
        // 선택한 데이터를 부모 위젯에 전달
        widget.onItemsSelected(selectedBackgroundId, selectedFloorId);
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 16.0),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey, // 선택된 상태 표시
            width: isSelected ? 4.0 : 2.0,
          ),
          borderRadius: BorderRadius.circular(12.0),
          color: Colors.white,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              item['image'], // 아이템 이미지
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 8.0),
            Text(
              item['name'], // 아이템 이름
              style: const TextStyle(fontSize: 16.0),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
