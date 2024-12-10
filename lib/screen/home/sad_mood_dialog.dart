import 'dart:convert'; // Add this line for jsonDecode
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SadMoodDialog extends StatelessWidget {
  final Function onQuizSelected;
  final Function onCoinSelected;

  const SadMoodDialog({required this.onQuizSelected, required this.onCoinSelected, Key? key}) : super(key: key);

  Future<Map<String, dynamic>> _getCoinData() async {
    final secureStorage = FlutterSecureStorage();

    // `petData` 불러오기
    final petDataString = await secureStorage.read(key: 'petData');
    Map<String, dynamic> petData = {};

    if (petDataString != null) {
      petData = Map<String, dynamic>.from(jsonDecode(petDataString));
    }

    final totalCarbonString = await secureStorage.read(key: 'carbonTotal') ?? '0';
    final discountString = await secureStorage.read(key: 'discount') ?? '0';

    final totalCarbon = double.tryParse(totalCarbonString) ?? 0.0;
    final discount = double.tryParse(discountString) ?? 0.0;
    final userCoins = petData['points'] ?? 0; // `points` 값 가져오기
    int tmp = 100;
    final coinCost = ((totalCarbon - discount) / tmp).floor() * 100;

    return {'coinCost': coinCost, 'userCoins': userCoins};
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getCoinData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final coinCost = snapshot.data?['coinCost'] ?? 0;
        final userCoins = snapshot.data?['userCoins'] ?? 0;
        print('$coinCost | $userCoins');
        final isAffordable = userCoins >= coinCost;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.5, // 화면 너비의 80%로 제한
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "펫의 기분이 나쁩니다!",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "디지털 탄소 발생량이 많아서 답답하대요.\n미션을 수행해서 펫의 기분을 풀어주세요!",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text("미션 수행"),
                    ),
                    ElevatedButton(
                      onPressed: isAffordable
                          ? () {
                        onCoinSelected(coinCost);
                        Navigator.of(context).pop();
                      }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/icon/leaf_token.png',
                            width: 24,
                            height: 24,
                          ),
                          SizedBox(width: 8),
                          Text(isAffordable ? "-$coinCost" : "포인트 부족"),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }
}
