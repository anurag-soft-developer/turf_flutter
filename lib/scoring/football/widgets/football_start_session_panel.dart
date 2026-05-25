import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/config/constants.dart';

class FootballStartSessionPanel extends StatelessWidget {
  const FootballStartSessionPanel({
    super.key,
    required this.metaPending,
    required this.fromTeamName,
    required this.toTeamName,
    required this.matchMinuteController,
    required this.isStarting,
    required this.errorText,
    required this.onStart,
  });

  final bool metaPending;
  final String fromTeamName;
  final String toTeamName;
  final TextEditingController matchMinuteController;
  final bool isStarting;
  final String? errorText;
  final VoidCallback onStart;

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Start football scoring',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$fromTeamName vs $toTeamName',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(AppColors.textSecondaryColor),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Total match minutes (optional)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Both halves combined, e.g. 90. Each half auto-pauses at half of this.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(AppColors.textSecondaryColor),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: matchMinuteController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: 'e.g. 90',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                if (errorText != null && errorText!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    errorText!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: FilledButton(
            onPressed: isStarting ? null : onStart,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: primary,
            ),
            child: isStarting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Start scoring'),
          ),
        ),
      ],
    );
  }
}
