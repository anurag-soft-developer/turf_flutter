import 'package:flutter/material.dart';

import '../../../core/config/constants.dart';
import '../../../team/model/team_model.dart';

class TeamSportStatsSection extends StatelessWidget {
  const TeamSportStatsSection({super.key, required this.team});

  final TeamModel team;

  @override
  Widget build(BuildContext context) {
    final stats = team.statsForSport;
    if (stats == null) return const SizedBox.shrink();

    final items = _buildStatItems(stats);
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate responsive grid layout
          final screenWidth = constraints.maxWidth;
          final crossAxisCount = screenWidth > 500 ? 3 : 2;

          return GridView.count(
            crossAxisCount: crossAxisCount,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero, // Remove default GridView padding
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.2, // Fixed ratio for consistent sizing
            children: items,
          );
        },
      ),
    );
  }

  List<Widget> _buildStatItems(dynamic stats) {
    if (stats is TeamFootballStats) {
      return [
        _StatTile(
          value: stats.goalsScored.toString(),
          label: 'Goals',
          icon: Icons.sports_soccer,
          color: const Color(AppColors.successColor),
        ),
        _StatTile(
          value: stats.goalsConceded.toString(),
          label: 'Conceded',
          icon: Icons.shield_outlined,
          color: const Color(AppColors.errorColor),
        ),
        _StatTile(
          value: stats.cleanSheets.toString(),
          label: 'Clean Sheets',
          icon: Icons.security,
          color: const Color(AppColors.primaryColor),
        ),
        _StatTile(
          value: stats.penaltyGoalsScored.toString(),
          label: 'Penalties',
          icon: Icons.gps_fixed,
          color: const Color(AppColors.accentColor),
        ),
        _StatTile(
          value: stats.yellowCards.toString(),
          label: 'Yellows',
          icon: Icons.rectangle,
          color: const Color(0xFFF59E0B),
        ),
        _StatTile(
          value: stats.redCards.toString(),
          label: 'Reds',
          icon: Icons.rectangle,
          color: const Color(AppColors.errorColor),
        ),
      ];
    }

    if (stats is TeamCricketStats) {
      return [
        _StatTile(
          value: stats.totalRunsScored.toString(),
          label: 'Runs',
          icon: Icons.sports_cricket,
          color: const Color(AppColors.successColor),
        ),
        _StatTile(
          value: stats.totalRunsConceded.toString(),
          label: 'Conceded',
          icon: Icons.shield_outlined,
          color: const Color(AppColors.errorColor),
        ),
        _StatTile(
          value: stats.totalWicketsTaken.toString(),
          label: 'Wickets',
          icon: Icons.bolt,
          color: const Color(AppColors.primaryColor),
        ),
        _StatTile(
          value: stats.highestTeamScore.toString(),
          label: 'Highest',
          icon: Icons.trending_up,
          color: const Color(AppColors.accentColor),
        ),
        _StatTile(
          value: stats.lowestTeamScore.toString(),
          label: 'Lowest',
          icon: Icons.trending_down,
          color: const Color(0xFF6B7280),
        ),
        _StatTile(
          value: stats.timesAllOut.toString(),
          label: 'All Out',
          icon: Icons.cancel_outlined,
          color: const Color(AppColors.errorColor),
        ),
      ];
    }

    return [];
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.3,
              height: 1.0,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 1),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: Color(AppColors.textSecondaryColor),
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
