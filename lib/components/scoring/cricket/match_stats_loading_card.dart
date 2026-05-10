import 'package:flutter/material.dart';

import '../../../core/config/constants.dart';

/// Loading placeholder shown while the match stats are being fetched.
class MatchStatsLoadingCard extends StatelessWidget {
  const MatchStatsLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Column(
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          SizedBox(height: 16),
          Text(
            'Loading match stats…',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(AppColors.textSecondaryColor),
            ),
          ),
        ],
      ),
    );
  }
}
