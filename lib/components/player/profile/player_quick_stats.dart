import 'package:flutter/material.dart';

import '../../../core/config/constants.dart';
import '../../../core/models/user_field_instance.dart';
import '../../../core/models/user/player_stats_models.dart';

class PlayerQuickStats extends StatelessWidget {
  const PlayerQuickStats({super.key, required this.helper});

  final UserFieldInstance helper;

  @override
  Widget build(BuildContext context) {
    final model = helper.getModel();
    final allStats = model?.playerSportStats ?? [];

    // Calculate overall stats across all sports
    int totalMatches = 0;
    int totalWins = 0;
    // int totalSports = allStats.length;

    for (final entry in allStats) {
      if (entry.sportType == SportType.football &&
          entry.footballStats != null) {
        totalMatches += entry.footballStats!.matchesPlayed;
        totalWins += entry.footballStats!.matchesWon;
      } else if (entry.sportType == SportType.cricket &&
          entry.cricketStats != null) {
        // For cricket, we don't have matches won directly, so use a different approach
        final batting = entry.cricketStats?.batting;
        if (batting != null) {
          totalMatches += batting.innings;
        }
      }
    }

    final winRate = totalMatches > 0 ? (totalWins / totalMatches * 100) : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _QuickStatItem(
            value: totalMatches.toString(),
            label: 'Matches',
            color: const Color(AppColors.textColor),
          ),
          _divider(),
          _QuickStatItem(
            value: totalWins.toString(),
            label: 'Wins',
            color: const Color(AppColors.successColor),
          ),
          _divider(),
          // _QuickStatItem(
          //   value: totalSports.toString(),
          //   label: 'Sports',
          //   color: const Color(AppColors.accentColor),
          // ),
          // _divider(),
          _QuickStatItem(
            value: '${winRate.toStringAsFixed(0)}%',
            label: 'Win Rate',
            color: const Color(AppColors.primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 32,
      width: 1,
      color: const Color(AppColors.dividerColor),
    );
  }
}

class _QuickStatItem extends StatelessWidget {
  const _QuickStatItem({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(AppColors.textSecondaryColor),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
