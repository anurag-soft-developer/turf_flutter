import 'package:flutter/material.dart';

import '../../core/config/constants.dart';
import '../../team/model/team_model.dart';

class TeamStatsRow extends StatelessWidget {
  const TeamStatsRow({
    super.key,
    required this.team,
    this.compact = false,
  });

  final TeamModel team;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      fontSize: compact ? 11 : 12,
      color: const Color(AppColors.textSecondaryColor),
      fontWeight: FontWeight.w500,
    );
    final valueStyle = labelStyle.copyWith(
      fontWeight: FontWeight.w700,
      color: const Color(AppColors.textColor),
    );

    return Wrap(
      spacing: 0,
      runSpacing: 4,
      children: [
        _chip('W', '${team.wins}', valueStyle, labelStyle),
        _dot(),
        _chip('L', '${team.losses}', valueStyle, labelStyle),
        _dot(),
        _chip('D', '${team.draws}', valueStyle, labelStyle),
        if (!compact) ...[
          _dot(),
          _chip('Played', '${team.matchesPlayed}', valueStyle, labelStyle),
        ],
      ],
    );
  }

  Widget _chip(
      String label, String value, TextStyle vStyle, TextStyle lStyle) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label ', style: lStyle),
        Text(value, style: vStyle),
      ],
    );
  }

  Widget _dot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Text(
        '·',
        style: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
