import 'package:flutter/material.dart';

import '../../../core/config/constants.dart';

/// Empty-state body shown before a cricket scoring session has been started.
class CricketStartOnlyBody extends StatelessWidget {
  const CricketStartOnlyBody({
    super.key,
    required this.isStarting,
    this.canStart = true,
    required this.errorText,
    required this.onStart,
  });

  final bool isStarting;
  /// When false, the button is disabled (e.g. batting side not chosen yet).
  final bool canStart;
  final String? errorText;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_cricket_rounded,
              size: 56,
              color: const Color(
                AppColors.primaryColor,
              ).withValues(alpha: 0.85),
            ),
            const SizedBox(height: 20),
            const Text(
              'Cricket scoring',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: Color(AppColors.textColor),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              canStart
                  ? 'Start the session to record balls and view the scorecard.'
                  : 'Pick who bats first, set overs, then start scoring.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(AppColors.textSecondaryColor),
                height: 1.35,
              ),
            ),
            if (errorText != null && errorText!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                errorText!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(AppColors.errorColor),
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: 260,
              child: ElevatedButton.icon(
                onPressed: (isStarting || !canStart) ? null : onStart,
                icon: isStarting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.play_arrow_rounded),
                label: Text(isStarting ? 'Starting…' : 'Start scoring'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(AppColors.primaryColor),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
