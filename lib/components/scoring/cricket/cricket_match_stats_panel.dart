import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/config/constants.dart';
import '../../../core/models/team/team_ref_field_instance.dart';
import '../../../match_up/model/team_match_model.dart';
import '../../../scoring/scoring_controller.dart';
import 'match_stats_error_card.dart';
import 'match_stats_loading_card.dart';
import 'match_status_chip.dart';

/// Hero panel: batting side above the score, runs/wickets, then overs as
/// current/max (e.g. `2.1 / 20 ov`) and innings index.
///
/// Self-observes [ScoringController] so the parent does not need to wrap it
/// in [Obx].
String _teamLabel(dynamic ref, String Function(String teamId) teamLabelForId) {
  final h = TeamRefFieldInstance(ref);
  if (h.isPopulated) return h.getDisplayName();
  final id = h.getId();
  if (id != null && id.isNotEmpty) return teamLabelForId(id);
  return h.getDisplayName();
}

class CricketMatchStatsPanel extends StatelessWidget {
  const CricketMatchStatsPanel({
    super.key,
    required this.controller,
    required this.teamLabelForId,
    required this.onRetry,
  });

  final ScoringController controller;
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

      return Container(
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
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 4,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(AppColors.primaryColor),
                    Color(AppColors.secondaryColor),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.sports_cricket_rounded,
                        size: 22,
                        color: const Color(
                          AppColors.primaryColor,
                        ).withValues(alpha: 0.9),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        battingName,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(AppColors.textColor),
                        ),
                      ),
                      const Spacer(),
                      MatchStatusChip(status: match.status),
                      if (loading) ...[
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 16,
                          height: 16,
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
                  const SizedBox(height: 8),
                  // Text(
                  //   battingName,
                  //   maxLines: 2,
                  //   overflow: TextOverflow.ellipsis,
                  //   style: const TextStyle(
                  //     fontSize: 16,
                  //     fontWeight: FontWeight.w600,
                  //     height: 1.25,
                  //     color: Color(AppColors.textColor),
                  //   ),
                  // ),
                  // const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '$runs/$wickets',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 44,
                        height: 1.05,
                        letterSpacing: -1,
                        color: Color(AppColors.textColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$oversStr / ${cs.maxOvers} ov · Innings '
                    '${cs.currentInnings}/${cs.inningsSummaries.length}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(AppColors.textSecondaryColor),
                    ),
                  ),
                ],
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
