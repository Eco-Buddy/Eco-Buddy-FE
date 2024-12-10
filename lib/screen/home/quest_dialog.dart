import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../provider/pet_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class QuestDialog extends StatefulWidget {
  @override
  _QuestDialogState createState() => _QuestDialogState();
}

class _QuestDialogState extends State<QuestDialog> {
  Map<String, dynamic>? _currentQuest;
  bool _showResult = false;
  bool _isCorrect = false;
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadRandomQuest();
  }

  Future<void> _loadRandomQuest() async {
    try {
      final String data = await rootBundle.loadString('lib/screen/home/quests.json');
      final List<dynamic> quests = json.decode(data);
      final random = Random();
      setState(() {
        _currentQuest = quests[random.nextInt(quests.length)];
      });
    } catch (e) {
      print('Error loading quests.json: $e');
    }
  }

  Future<void> _updatePointsInStorage(int newPoints) async {
    await _storage.write(key: 'points', value: newPoints.toString());
  }

  void _checkAnswer(String selectedHint) {
    if (_currentQuest != null) {
      setState(() {
        _isCorrect = selectedHint == _currentQuest!['answer'];
        _showResult = true;

        final petProvider = Provider.of<PetProvider>(context, listen: false);
        final int reward = _isCorrect ? 1000 : 100;
        final int updatedPoints = petProvider.petPoints + reward;
        petProvider.updatePetPoints(updatedPoints);

        _updatePointsInStorage(updatedPoints);

        print(_isCorrect
            ? '정답입니다! +1000 포인트'
            : '오답입니다... +100 포인트');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: _currentQuest == null
          ? Center(child: CircularProgressIndicator())
          : !_showResult
          ? _buildQuestionContent()
          : _buildResultContent(),
    );
  }

  Widget _buildQuestionContent() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // 배경 흰색
        borderRadius: BorderRadius.all(Radius.circular(16)), // 모서리 둥글게
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Center(
              child: Text(
                'Quiz',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _currentQuest!['question'],
              style: TextStyle(
                fontSize: 18,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          ...List.generate(4, (index) {
            String hintKey = 'hint${index + 1}';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
              child: ElevatedButton(
                onPressed: () => _checkAnswer(_currentQuest![hintKey]),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50), // 버튼 크기 고정
                  backgroundColor: Colors.white, // 배경색 흰색
                  side: const BorderSide(color: Colors.grey, width: 3.0), // 회색 테두리
                  textStyle: const TextStyle(fontSize: 16), // 텍스트 크기 지정
                ),
                child: Center(
                  child: Text(
                    _currentQuest![hintKey],
                    textAlign: TextAlign.center, // 중앙 정렬
                    style: const TextStyle(color: Colors.black), // 텍스트 색상을 검은색으로 수정
                  ),
                ),
              ),
            );
          }),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _refreshPoints();
            },
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.grey[100], // 배경색 설정
              foregroundColor: Colors.red, // 텍스트 색상
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12), // 버튼 모서리 둥글게
              ),
            ),
            child: Text(
              '닫기',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildResultContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _isCorrect ? '정답입니다!' : '오답입니다...',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _isCorrect ? Colors.green : Colors.red,
            ),
          ),
        ),
        if (!_isCorrect)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '정답: ${_currentQuest!['answer']}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _currentQuest!['explanation'],
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
        // 오답일 경우 정답도 표시
        Text(
          _isCorrect ? '+1000 포인트' : '+100 포인트',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _isCorrect ? Colors.green : Colors.grey,
          ),
        ),
        Text(
          _isCorrect ? '' : '다음번엔 꼭 맞춰봐요!',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            _refreshPoints();
          },
          child: Text('확인'),
        )
      ],
    );
  }


  Future<void> _refreshPoints() async {
    final String? points = await _storage.read(key: 'points');
    if (points != null) {
      final petProvider = Provider.of<PetProvider>(context, listen: false);
      petProvider.updatePetPoints(int.parse(points));
      print('포인트 갱신됨: $points');
    }
  }
}
