import 'package:flutter/material.dart';
import 'data_usage_page.dart'; // Import the data usage page you've created

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Data Usage App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: DataUsagePage(), // Set DataUsagePage as the home screen
    );
  }
}
