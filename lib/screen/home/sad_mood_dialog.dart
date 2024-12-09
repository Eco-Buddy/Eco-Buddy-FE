import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'quest_dialog.dart';  // 퀘스트 다이얼로그

class SadMoodDialog extends StatelessWidget {
  final Function onQuizSelected;
  final Function onCoinSelected;

  const SadMoodDialog({required this.onQuizSelected, required this.onCoinSelected, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("펫의 기분이 나쁩니다!"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("디지털 탄소 발생량이 많아서 답답하대요. 미션을 수행해서 펫의 기분을 풀어주세요!"),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                onPressed: () {
                  onQuizSelected();  // 퀴즈 풀기 선택
                  Navigator.of(context).pop();
                },
                child: Text("퀴즈 풀기"),
              ),
              ElevatedButton(
                onPressed: () {
                  onCoinSelected();  // 코인 소모 선택
                  Navigator.of(context).pop();
                },
                child: Text("코인 소모하기"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
