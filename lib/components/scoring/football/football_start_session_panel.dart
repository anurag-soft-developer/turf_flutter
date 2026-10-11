import 'package:flutter/material.dart';

import '../../shared/numeric_stepper_field.dart';
import '../../../core/config/constants.dart';

/// Pre-session UI: set match length, then start football scoring.
class FootballStartSessionPanel extends StatelessWidget {
  const FootballStartSessionPanel({
    super.key,
    required this.metaPending,
    required this.matchMinuteController,
    required this.isStarting,
    required this.canStart,
    required this.errorText,
    required this.onStart,
    required this.onMinuteChanged,
    this.minMinutes = 2,
    this.maxMinutes = 90,
  });

  final bool metaPending;
  final TextEditingController matchMinuteController;
  final bool isStarting;
  final bool canStart;
  final String? errorText;
  final VoidCallback onStart;
  final VoidCallback onMinuteChanged;
  final int minMinutes;
  final int maxMinutes;

  @override
  Widget build(BuildContext context) {
    if (metaPending) {
      return const Center(child: CircularProgressIndicator());
    }

    final primary = const Color(AppColors.primaryColor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Match length',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(AppColors.textColor),
                    ),
                  ),
                  const SizedBox(height: 12),
                  NumericStepperField(
                    controller: matchMinuteController,
                    min: minMinutes,
                    max: maxMinutes,
                    step: 5,
                    primaryColor: primary,
                    onChanged: onMinuteChanged,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$minMinutes–$maxMinutes min',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  if (errorText != null && errorText!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      errorText!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: Color(AppColors.errorColor),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: SizedBox(
              height: 52,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (isStarting || !canStart) ? null : onStart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(AppColors.primaryColor),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade600,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isStarting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Start',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
