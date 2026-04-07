import 'package:flutter/material.dart';

import '../../../core/config/constants.dart';
import '../../../team/model/team_model.dart';

class TeamQuickStatsBar extends StatelessWidget {
  const TeamQuickStatsBar({super.key, required this.team});

  final TeamModel team;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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
          _StatItem(value: team.matchesPlayed.toString(), label: 'Played'),
          _divider(),
          _StatItem(
            value: team.wins.toString(),
            label: 'Won',
            valueColor: const Color(AppColors.successColor),
          ),
          // _divider(),
          // _StatItem(
          //   value: team.losses.toString(),
          //   label: 'Lost',
          //   valueColor: const Color(AppColors.errorColor),
          // ),
          // _divider(),
          // _StatItem(value: team.draws.toString(), label: 'Drawn'),
          _divider(),
          _StatItem(
            value: '${(team.winRate * 100).toStringAsFixed(0)}%',
            label: 'Win Rate',
            valueColor: const Color(AppColors.primaryColor),
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

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label, this.valueColor});

  final String value;
  final String label;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: valueColor ?? const Color(AppColors.textColor),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(AppColors.textSecondaryColor),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
