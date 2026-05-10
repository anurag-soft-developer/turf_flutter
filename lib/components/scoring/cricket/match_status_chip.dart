import 'package:flutter/material.dart';

import '../../../core/config/constants.dart';
import '../../../match_up/model/team_match_model.dart';

/// Pill chip displaying a short label for a [TeamMatchStatus].
class MatchStatusChip extends StatelessWidget {
  const MatchStatusChip({super.key, required this.status});

  final TeamMatchStatus status;

  @override
  Widget build(BuildContext context) {
    final label = shortMatchStatusLabel(status);
    final bg = switch (status) {
      TeamMatchStatus.ongoing => const Color(AppColors.successColor),
      TeamMatchStatus.completed ||
      TeamMatchStatus.draw ||
      TeamMatchStatus.abandoned => const Color(AppColors.textSecondaryColor),
      _ => const Color(AppColors.primaryColor),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bg.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: bg.withValues(alpha: 0.95),
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Short, user-facing label for a [TeamMatchStatus].
String shortMatchStatusLabel(TeamMatchStatus s) => switch (s) {
  TeamMatchStatus.requested => 'Requested',
  TeamMatchStatus.accepted => 'Accepted',
  TeamMatchStatus.negotiating => 'Negotiating',
  TeamMatchStatus.scheduleFinalized => 'Scheduled',
  TeamMatchStatus.rejected => 'Rejected',
  TeamMatchStatus.expired => 'Expired',
  TeamMatchStatus.cancelled => 'Cancelled',
  TeamMatchStatus.ongoing => 'Live',
  TeamMatchStatus.completed => 'Completed',
  TeamMatchStatus.draw => 'Draw',
  TeamMatchStatus.abandoned => 'Abandoned',
};
