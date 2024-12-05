import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NewbiePage extends StatefulWidget {
  @override
  _NewbiePageState createState() => _NewbiePageState();
}

class _NewbiePageState extends State<NewbiePage> {
  final _petNameController = TextEditingController();
  final _secureStorage = FlutterSecureStorage();

  Future<void> _savePetName() async {
    final petName = _petNameController.text;
    if (petName.isNotEmpty) {
      await _secureStorage.write(key: 'petName', value: petName);
      print('✅ 펫 이름 저장 완료: $petName');
      Navigator.pushReplacementNamed(context, '/main');
    } else {
      print('❌ 펫 이름을 입력해주세요.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('신규 회원 설정')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '환영합니다! 먼저 펫의 이름을 설정해주세요.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _petNameController,
              decoration: const InputDecoration(
                labelText: '펫 이름',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _savePetName,
              child: const Text('저장하고 시작하기'),
            ),
          ],
        ),
      ),
    );
  }
}
