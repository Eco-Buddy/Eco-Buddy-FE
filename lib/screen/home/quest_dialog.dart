import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class QuestDialog extends StatefulWidget {
  const QuestDialog({Key? key}) : super(key: key);

  @override
  _QuestDialogState createState() => _QuestDialogState();
}

class _QuestDialogState extends State<QuestDialog> {
  late String currentQuestion;
  late String currentAnswer;
  TextEditingController _answerController = TextEditingController();
  String feedbackMessage = "";
  int earnedPoints = 0;
  List<dynamic> quests = [];  // 초기값을 빈 리스트로 설정

  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    loadQuests();
  }

  // 퀴즈 JSON 파일 로딩
  Future<void> loadQuests() async {
    try {
      final String response = await rootBundle.loadString('lib/screen/home/quests.json');
      final List<dynamic> questsData = jsonDecode(response);
      setState(() {
        quests = questsData;
        isLoading = false;
      });
      if (quests.isNotEmpty) {
        _loadNextQuestion(); // 데이터가 로드되면 첫 번째 퀴즈를 로드
      }
    } catch (e) {
      print('퀘스트 데이터를 불러오는 중 에러 발생: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // 다음 퀴즈로 넘어가기
  void _loadNextQuestion() {
    if (quests.isNotEmpty) {
      final quest = quests[0];
      setState(() {
        currentQuestion = quest['question'];
        currentAnswer = quest['answer'];
        feedbackMessage = "";
        earnedPoints = 0;
        _answerController.clear();
      });
    }
  }

  // 제출 버튼 클릭 시
  void _submitAnswer() {
    final userAnswer = _answerController.text.trim();
    if (userAnswer == currentAnswer) {
      setState(() {
        earnedPoints = quests[0]['points'] * 2; // 정답이면 포인트 두 배
        feedbackMessage = "정답입니다! ${earnedPoints}포인트를 얻었습니다.";
      });
    } else {
      setState(() {
        earnedPoints = 30; // 틀리면 30포인트
        feedbackMessage = "아쉽습니다. 정답은 '$currentAnswer'입니다. 30포인트를 드립니다.";
      });
    }
    setState(() {
      quests.removeAt(0); // 퀴즈 하나를 풀었으니 목록에서 제거
    });
    if (quests.isNotEmpty) {
      _loadNextQuestion(); // 다음 퀴즈 로딩
    } else {
      // 퀴즈가 끝났을 때 처리
      setState(() {
        feedbackMessage = "모든 퀴즈를 완료했습니다.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      title: const Text(
        "퀘스트",
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
      ),
      content: quests.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            currentQuestion,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _answerController,
            decoration: const InputDecoration(
              labelText: '정답을 입력하세요',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          if (feedbackMessage.isNotEmpty)
            Text(
              feedbackMessage,
              style: TextStyle(
                fontSize: 14,
                color: earnedPoints == 0 ? Colors.red : Colors.green,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            '닫기',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        ElevatedButton(
          onPressed: _submitAnswer,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
          child: const Text(
            '제출',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
