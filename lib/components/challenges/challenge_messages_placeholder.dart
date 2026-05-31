import 'package:flutter/material.dart';

import '../../core/config/constants.dart';

class ChallengeMessagesPlaceholder extends StatelessWidget {
  const ChallengeMessagesPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(AppColors.dividerColor)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(AppColors.primaryColor).withValues(
                    alpha: 0.1,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.forum_outlined,
                  size: 36,
                  color: Color(AppColors.primaryColor),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Coming Soon',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(AppColors.textColor),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Challenge messaging is on the way. You will be able to chat with the other team right here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(AppColors.textSecondaryColor),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
