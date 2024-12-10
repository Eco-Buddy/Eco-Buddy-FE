import 'package:flutter/material.dart';

class PetMissionDialog extends StatelessWidget {
  final String title; // 제목
  final String missionRequest; // 미션 요청 메시지
  final String missionContent; // 미션 내용
  final String missionDescription; // 미션 설명
  final VoidCallback onComplete; // 수행 완료 콜백
  final VoidCallback onLater; // 나중에 수행 콜백

  const PetMissionDialog({
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
          // 미션 요청 메시지
          Text(
            missionRequest,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // 미션 내용
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
          // 미션 설명
          Text(
            missionDescription,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        // '다음에 할게요' 버튼
        TextButton(
          onPressed: onLater,
          child: const Text(
            '다음에 할게요',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        // '수행 완료' 버튼
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
