import 'package:flutter/material.dart';

class MissionDialog extends StatelessWidget {
  final String title;
  final String missionRequest;
  final String missionContent;
  final String missionDescription;
  final VoidCallback onComplete;
  final VoidCallback onLater;

  const MissionDialog({
    Key? key,
    required this.title,
    required this.missionRequest,
    required this.missionContent,
    required this.missionDescription,
    required this.onComplete,
    required this.onLater,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            missionRequest,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.task_alt, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  missionContent,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            missionDescription,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onLater,
          child: const Text(
            '다음에 할게요',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        ElevatedButton(
          onPressed: onComplete,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
          child: const Text(
            '수행 완료',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
