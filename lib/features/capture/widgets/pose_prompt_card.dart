import 'package:flutter/material.dart';

class PosePromptCard extends StatelessWidget {
  final String posePrompt;

  const PosePromptCard({
    super.key,
    required this.posePrompt,
  });

  @override
  Widget build(BuildContext context) {
    if (posePrompt.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(160),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 18),
          const SizedBox(width: 8),
          Text(
            posePrompt,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
