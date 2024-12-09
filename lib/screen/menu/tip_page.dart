import 'dart:convert';
import 'package:flutter/services.dart'; // rootBundle 사용
import 'package:flutter/material.dart';

void main() {
  runApp(Tip());
}

class Tip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DigitalCarbonFootprintTips(),
    );
  }
}

class DigitalCarbonFootprintTips extends StatefulWidget {
  @override
  _DigitalCarbonFootprintTipsState createState() =>
      _DigitalCarbonFootprintTipsState();
}

class _DigitalCarbonFootprintTipsState
    extends State<DigitalCarbonFootprintTips> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  List<Map<String, String>> tips = [];

  @override
  void initState() {
    super.initState();
    _loadTips();
  }

  Future<void> _loadTips() async {
    try {
      // assets에서 JSON 파일 읽기
      String jsonString = await rootBundle.loadString('lib/screen/menu/tips.json');
      final List<dynamic> jsonData = json.decode(jsonString);

      setState(() {
        tips = jsonData.map((e) => Map<String, String>.from(e)).toList();
      });
    } catch (e) {
      print("Error loading tips.json: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('환경 꿀팁'),
      ),
      body: tips.isEmpty
          ? Center(child: CircularProgressIndicator()) // 데이터 로딩 중
          : Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: tips.length,
              itemBuilder: (context, index) {
                final tip = tips[index];
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        tip["title"]!,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),
                      Image.asset(
                        tip["image"]!,
                        height: 200,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(height: 20),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            tip["text"]!,
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: _currentIndex > 0
                      ? () {
                    _pageController.previousPage(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                      : null,
                ),
                Text(
                  '${_currentIndex + 1}/${tips.length}',
                  style: TextStyle(fontSize: 16),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward),
                  onPressed: _currentIndex < tips.length - 1
                      ? () {
                    _pageController.nextPage(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
