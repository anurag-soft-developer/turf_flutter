import 'package:flutter/material.dart';

import '../../core/config/constants.dart';

class ChallengeMessagesPlaceholder extends StatelessWidget {
  const ChallengeMessagesPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text(
                  'Chat messages will appear here.\n(Placeholder for now)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(AppColors.textSecondaryColor),
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            enabled: false,
            decoration: InputDecoration(
              hintText: 'Type a message (coming soon)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: const Icon(Icons.send),
            ),
          ),
        ],
      ),
    );
  }
}
