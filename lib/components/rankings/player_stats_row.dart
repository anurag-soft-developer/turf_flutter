import 'package:flutter/material.dart';

import '../../core/config/constants.dart';
import '../../rankings/model/player_leaderboard_model.dart';

class PlayerStatsRow extends StatelessWidget {
  const PlayerStatsRow({
    super.key,
    required this.matchesWon,
    required this.matchesLost,
    required this.matchesPlayed,
    required this.winRate,
    this.compact = false,
  });

  PlayerStatsRow.fromLeaderboard(
    PlayerLeaderboardRow entry, {
    this.compact = false,
  })  : matchesWon = entry.stats.matchesWon,
        matchesLost = entry.stats.matchesLost,
        matchesPlayed = entry.stats.matchesPlayed,
        winRate = entry.stats.winRate;

  final int matchesWon;
  final int matchesLost;
  final int matchesPlayed;
  final double winRate;
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
        _chip('W', '$matchesWon', valueStyle, labelStyle),
        _dot(),
        _chip('L', '$matchesLost', valueStyle, labelStyle),
        if (!compact) ...[
          _dot(),
          _chip('Played', '$matchesPlayed', valueStyle, labelStyle),
          _dot(),
          _chip('WR', _winRateLabel(), valueStyle, labelStyle),
        ],
      ],
    );
  }

  String _winRateLabel() {
    if (matchesPlayed <= 0) return '0%';
    return '${(winRate * 100).round()}%';
  }

  Widget _chip(
    String label,
    String value,
    TextStyle vStyle,
    TextStyle lStyle,
  ) {
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
