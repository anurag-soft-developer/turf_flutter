import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/config/constants.dart';
import '../../../core/models/team/team_ref_field_instance.dart';
import '../../../match_up/model/team_match_model.dart';
import '../../../scoring/cricket/cricket_scoring_controller.dart';
import 'match_stats_error_card.dart';
import 'match_stats_loading_card.dart';
import 'match_status_chip.dart';

/// Hero score: batting side, big runs/wickets, overs + run rate.
///
/// Self-observes [CricketScoringController] so the parent does not need to wrap it
/// in [Obx].
String _teamLabel(dynamic ref, String Function(String teamId) teamLabelForId) {
  final h = TeamRefFieldInstance(ref);
  if (h.isPopulated) return h.getDisplayName();
  final id = h.getId();
  if (id != null && id.isNotEmpty) return teamLabelForId(id);
  return h.getDisplayName();
}

String _runRateLabel(int runs, int legalBalls) {
  if (legalBalls <= 0) return '—';
  final rr = runs / (legalBalls / 6.0);
  return rr.toStringAsFixed(1);
}

class CricketMatchStatsPanel extends StatelessWidget {
  const CricketMatchStatsPanel({
    super.key,
    required this.controller,
    required this.teamLabelForId,
    required this.onRetry,
  });

  final CricketScoringController controller;
  final String Function(String teamId) teamLabelForId;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = controller.isFetchingCricketMatch.value;
      final match = controller.cricketMatch.value;
      final err = controller.errorMessage.value;

      if (loading && match == null) {
        return const MatchStatsLoadingCard();
      }

      if (match == null && err != null && err.isNotEmpty) {
        return MatchStatsErrorCard(message: err, onRetry: onRetry);
      }

      if (match == null) {
        return MatchStatsErrorCard(
          message: 'No match data loaded.',
          onRetry: onRetry,
        );
      }

      final cs = match.cricketState;
      if (cs == null) {
        return const SizedBox.shrink();
      }

      final summary = currentInningsSummary(cs);
      final runs = summary?.runs ?? 0;
      final wickets = summary?.wickets ?? 0;
      final legalBalls = summary?.legalBalls ?? 0;
      final oversStr = oversFromBalls(legalBalls);
      final battingName = _teamLabel(cs.battingTeamId, teamLabelForId);
      final rr = _runRateLabel(runs, legalBalls);

      return Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    battingName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(AppColors.textColor),
                    ),
                  ),
                ),
                MatchStatusChip(status: match.status),
                if (loading) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: const Color(
                        AppColors.primaryColor,
                      ).withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '$runs/$wickets',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 52,
                  height: 1.0,
                  letterSpacing: -1.5,
                  color: Color(AppColors.textColor),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$oversStr / ${cs.maxOvers} ov  ·  RR $rr  ·  '
              'Inn ${cs.currentInnings}/${cs.inningsSummaries.length}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(AppColors.textSecondaryColor),
              ),
            ),
          ],
        ),
      );
    });
  }
}

/// Returns the summary for the currently-active innings, or the last one
/// available if the index is out of range.
CricketInningsSummaryModel? currentInningsSummary(CricketStateModel cs) {
  final list = cs.inningsSummaries;
  if (list.isEmpty) return null;
  final idx = cs.currentInnings >= 1 ? cs.currentInnings - 1 : 0;
  if (idx >= 0 && idx < list.length) return list[idx];
  return list.last;
}

/// Mirrors backend `isInningsComplete` (wickets, overs, chase target).
bool isCricketInningsComplete(CricketStateModel cs) {
  final summary = currentInningsSummary(cs);
  if (summary == null) return false;

  final maxLegal = cs.maxOvers * 6;
  if (summary.wickets >= 10 || summary.legalBalls >= maxLegal) {
    return true;
  }

  final innIdx = cs.currentInnings - 1;
  if (innIdx > 0 && cs.inningsSummaries.isNotEmpty) {
    final firstInningsRuns = cs.inningsSummaries.first.runs;
    if (summary.runs > firstInningsRuns) {
      return true;
    }
  }

  return false;
}

/// Formats a count of legal balls into a cricket-style "overs.balls" string,
/// e.g. 13 balls -> `2.1`.
String oversFromBalls(int balls) => '${balls ~/ 6}.${balls % 6}';
