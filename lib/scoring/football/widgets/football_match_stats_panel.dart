import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../components/scoring/cricket/match_stats_error_card.dart';
import '../../../components/scoring/cricket/match_stats_loading_card.dart';
import '../../../core/config/constants.dart';
import '../football_scoring_controller.dart';
import '../model/football_scoring_models.dart';

class FootballMatchStatsPanel extends StatelessWidget {
  const FootballMatchStatsPanel({
    super.key,
    required this.controller,
    required this.fromTeamName,
    required this.toTeamName,
    required this.onRetry,
  });

  final FootballScoringController controller;
  final String fromTeamName;
  final String toTeamName;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isFetchingFootballMatch.value &&
          controller.footballMatch.value == null) {
        return const MatchStatsLoadingCard();
      }

      final match = controller.footballMatch.value;
      final fs = match?.footballState;
      if (match == null || fs == null) {
        final err = controller.errorMessage.value;
        return MatchStatsErrorCard(
          message: err != null && err.isNotEmpty
              ? err
              : 'Football state unavailable.',
          onRetry: onRetry,
        );
      }

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(AppColors.dividerColor)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Innings ${fs.currentInnings}/${fs.inningsSummaries.length} · ${periodLabel(fs.currentPeriod)}',
              style: const TextStyle(
                fontSize: 13,
                color: Color(AppColors.textSecondaryColor),
              ),
            ),
            if (fs.matchMinute != null) ...[
              const SizedBox(height: 4),
              Text(
                "${fs.matchMinute}'",
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(AppColors.textSecondaryColor),
                ),
              ),
            ],
            if (fs.inningsSummaries.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...List.generate(fs.inningsSummaries.length, (i) {
                final inn = fs.inningsSummaries[i];
                final p = inn.period;
                final periodText =
                    p != null ? ' · ${periodLabel(p)}' : '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    'Inn ${i + 1}$periodText: ${inn.scoreTeamOne}–${inn.scoreTeamTwo}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(AppColors.textSecondaryColor),
                    ),
                  ),
                );
              }),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ScoreColumn(
                    teamName: fromTeamName,
                    goals: fs.scoreTeamOne,
                  ),
                ),
                const Text(
                  '–',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                Expanded(
                  child: _ScoreColumn(
                    teamName: toTeamName,
                    goals: fs.scoreTeamTwo,
                    alignEnd: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _ScoreColumn extends StatelessWidget {
  const _ScoreColumn({
    required this.teamName,
    required this.goals,
    this.alignEnd = false,
  });

  final String teamName;
  final int goals;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          teamName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$goals',
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: Color(AppColors.primaryColor),
          ),
        ),
      ],
    );
  }
}
