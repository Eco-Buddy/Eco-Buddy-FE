import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class QuestDialog extends StatefulWidget {
  const QuestDialog({Key? key}) : super(key: key);

  @override
  _QuestDialogState createState() => _QuestDialogState();
}

class _QuestDialogState extends State<QuestDialog> {
  late String _question;
  late List<String> _hints;
  late String _answer;

  @override
  void initState() {
    super.initState();
    _loadQuestData();
  }

  // 퀘스트 데이터를 로드하고 랜덤으로 문제를 선택
  Future<void> _loadQuestData() async {
    try {
      final String response = await rootBundle.loadString('lib/screen/home/quests.json');
      final List<dynamic> quests = jsonDecode(response);

      final random = Random();
      final quest = quests[random.nextInt(quests.length)];

      setState(() {
        _question = quest['question'] as String;
        _answer = quest['answer'] as String;
        _hints = [
          quest['hint1'] as String,
          quest['hint2'] as String,
          quest['hint3'] as String,
          quest['hint4'] as String,
        ].where((hint) => hint.isNotEmpty).toList();
      });
    } catch (e) {
      print("Error loading quest data: $e");
    }
  }

  // 정답 확인
  void _checkAnswer(String selectedAnswer) {
    if (selectedAnswer == _answer) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('정답!', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('오답!', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hints.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 질문 텍스트
            Text(
              _question,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // 힌트 버튼들
            ..._hints.map((hint) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                    backgroundColor: Colors.teal, // 버튼 색상
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // 둥근 모서리
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () => _checkAnswer(hint),
                  child: Text(hint),
                ),
              );
            }).toList(),

            const SizedBox(height: 24),

            // 닫기 버튼
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(context); // 다이얼로그 닫기
              },
              child: const Text(
                '닫기',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
