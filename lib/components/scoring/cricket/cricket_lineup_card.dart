import 'package:flutter/material.dart';
import 'package:flutter_application_1/components/shared/app_network_image.dart';
import 'package:get/get.dart';

import '../../../core/config/constants.dart';
import '../../../core/models/user_field_instance.dart';
import '../../../match_up/announced_players/model/announced_player_model.dart';
import '../../../match_up/model/team_match_model.dart';
import '../../../scoring/common/lineup_helpers.dart';
import '../../../scoring/cricket/cricket_scoring_controller.dart';
import '../../../scoring/cricket/model/cricket_over_event_model.dart';
import '../../../scoring/cricket/model/cricket_scoring_models.dart';
import '../announced_player_list_tile.dart';
import 'cricket_match_stats_panel.dart';
import 'cricket_this_over_strip.dart';

/// User ids dismissed (out) in [innings], from over event ball data.
Set<String> dismissedBatsmanUserIds(List<CricketOverEvent> overs, int innings) {
  final out = <String>{};
  for (final o in overs) {
    if (o.innings != innings) continue;
    for (final b in o.ballEvents) {
      if (!b.isWicket || b.wicketsFallen < 1) continue;
      final id = UserFieldInstance(b.dismissedUserId).getId();
      if (id != null && id.isNotEmpty) out.add(id);
    }
  }
  return out;
}

AnnouncedPlayerModel? announcedPlayerForUserId(
  TeamMatchModel match,
  String? userId,
) {
  if (userId == null || userId.isEmpty) return null;
  for (final p in match.announcedPlayers) {
    if (p.participantId == userId) return p;
  }
  return null;
}

List<AnnouncedPlayerModel> playingXiForTeam(
  TeamMatchModel match,
  String teamId,
) {
  if (teamId.isEmpty) return const [];
  // Prefer live active lineup once scoring state is present.
  if (match.cricketState != null) {
    return activePlayersForTeam(match, teamId);
  }
  return match.announcedPlayers
      .where((p) => p.teamIdHelper.getId() == teamId && !p.isSubstitute)
      .toList();
}

enum _LineupRole { striker, nonStriker, bowler }

class _BattingFigures {
  const _BattingFigures({required this.runs, required this.balls});

  final int runs;
  final int balls;
}

_BattingFigures battingFiguresForUser(
  List<CricketOverEvent> overs,
  int innings,
  String? userId,
) {
  if (userId == null || userId.isEmpty) {
    return const _BattingFigures(runs: 0, balls: 0);
  }

  var runs = 0;
  var balls = 0;
  for (final over in overs) {
    if (over.innings != innings) continue;
    for (final ball in over.ballEvents) {
      final strikerId = UserFieldInstance(ball.strikerUserId).getId();
      if (strikerId != userId) continue;
      runs += ball.runsOffBat;
      if (ball.isLegalDelivery) {
        balls += 1;
      }
    }
  }

  return _BattingFigures(runs: runs, balls: balls);
}

List<CricketBallEvent> latestOverBalls(
  List<CricketOverEvent> overs,
  int innings, {
  bool clearCompletedOver = false,
}) {
  CricketOverEvent? latest;
  for (final over in overs) {
    if (over.innings != innings) continue;
    if (latest == null ||
        over.overAfter > latest.overAfter ||
        (over.overAfter == latest.overAfter &&
            over.sequence > latest.sequence)) {
      latest = over;
    }
  }
  if (latest == null) return const [];
  final legal = latest.ballEvents.where((b) => b.isLegalDelivery).length;
  // After next bowler is selected, hide the finished over until new balls.
  if (legal >= 6 && clearCompletedOver) return const [];
  return latest.ballEvents;
}

int _runsConcededInOver(List<CricketBallEvent> balls) {
  var sum = 0;
  for (final ball in balls) {
    sum += ball.totalRunsOnDelivery;
  }
  return sum;
}

/// Striker / non-striker cards in a row, plus bowler merged with this over.
class CricketLineupCard extends StatefulWidget {
  const CricketLineupCard({
    super.key,
    required this.controller,
    this.onThisOverTap,
  });

  final CricketScoringController controller;

  /// Opens overs history from the merged bowler + this-over card.
  final VoidCallback? onThisOverTap;

  @override
  State<CricketLineupCard> createState() => _CricketLineupCardState();
}

class _CricketLineupCardState extends State<CricketLineupCard> {
  String? _draftStriker;
  String? _draftNon;
  String? _draftBowler;

  String? _effStriker(CricketStateModel cs) =>
      _draftStriker ?? cs.strikerUserHelper.getId();

  String? _effNon(CricketStateModel cs) =>
      _draftNon ?? cs.nonStrikerUserHelper.getId();

  String? _effBowler(CricketStateModel cs) =>
      _draftBowler ?? cs.bowlerUserHelper.getId();

  Future<void> _tryCommit(TeamMatchModel match, CricketStateModel cs) async {
    final s = _effStriker(cs);
    final n = _effNon(cs);
    final b = _effBowler(cs);
    if (s == null ||
        s.isEmpty ||
        n == null ||
        n.isEmpty ||
        b == null ||
        b.isEmpty) {
      return;
    }
    if (s == n) return;

    final ok = await widget.controller.updateCricketState(
      UpdateCricketStateRequest(
        strikerUserId: s,
        nonStrikerUserId: n,
        bowlerUserId: b,
      ),
    );
    if (!mounted) return;
    if (ok) {
      setState(() {
        _draftStriker = null;
        _draftNon = null;
        _draftBowler = null;
      });
    }
  }

  Future<void> _openPicker({
    required BuildContext context,
    required TeamMatchModel match,
    required CricketStateModel cs,
    required _LineupRole role,
    required Set<String> dismissed,
  }) async {
    final battingId = cs.battingTeamHelper.getId() ?? '';
    final bowlingId = cs.bowlingTeamHelper.getId() ?? '';

    final strikerEff = _effStriker(cs);
    final nonEff = _effNon(cs);

    List<AnnouncedPlayerModel> candidates;
    switch (role) {
      case _LineupRole.striker:
      case _LineupRole.nonStriker:
        candidates = playingXiForTeam(match, battingId);
      case _LineupRole.bowler:
        candidates = playingXiForTeam(match, bowlingId);
    }

    final picked = await showModalBottomSheet<AnnouncedPlayerModel>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Text(
                    switch (role) {
                      _LineupRole.striker => 'Select striker',
                      _LineupRole.nonStriker => 'Select non-striker',
                      _LineupRole.bowler => 'Select bowler',
                    },
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: Color(AppColors.textColor),
                    ),
                  ),
                ),
                for (var index = 0; index < candidates.length; index++)
                  Builder(
                    builder: (context) {
                      final p = candidates[index];
                      final uid = p.participantId ?? '';
                      var disabled = uid.isEmpty;
                      if (role == _LineupRole.striker ||
                          role == _LineupRole.nonStriker) {
                        if (dismissed.contains(uid)) disabled = true;
                        if (role == _LineupRole.striker &&
                            uid.isNotEmpty &&
                            uid == nonEff) {
                          disabled = true;
                        }
                        if (role == _LineupRole.nonStriker &&
                            uid.isNotEmpty &&
                            uid == strikerEff) {
                          disabled = true;
                        }
                      }

                      return AnnouncedPlayerListTile.fromPlayer(
                        p,
                        enabled: !disabled,
                        subtitle: disabled
                            ? (dismissed.contains(uid)
                                  ? 'Out'
                                  : 'Already at other crease')
                            : null,
                        onTap: () => Navigator.pop(ctx, p),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || picked == null) return;
    final id = picked.participantId;
    if (id == null || id.isEmpty) return;

    setState(() {
      switch (role) {
        case _LineupRole.striker:
          _draftStriker = id;
        case _LineupRole.nonStriker:
          _draftNon = id;
        case _LineupRole.bowler:
          _draftBowler = id;
      }
    });

    await _tryCommit(match, cs);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final match = widget.controller.cricketMatch.value;
      final overs = widget.controller.cricketOvers;
      final busy =
          widget.controller.isSendingUpdate.value ||
          widget.controller.isUpdatingCricketLineup.value;

      final m = match;
      if (m == null || m.cricketState == null) {
        return const SizedBox.shrink();
      }

      final cs = m.cricketState!;
      final dismissed = dismissedBatsmanUserIds(overs, cs.currentInnings);

      final sId = _effStriker(cs);
      final nId = _effNon(cs);
      final bId = _effBowler(cs);
      final strikerFigures = battingFiguresForUser(
        overs,
        cs.currentInnings,
        sId,
      );
      final nonStrikerFigures = battingFiguresForUser(
        overs,
        cs.currentInnings,
        nId,
      );
      final awaitingNextBowler = isAwaitingNextOverBowler(cs, overs.toList());
      final thisOverBalls = latestOverBalls(
        overs,
        cs.currentInnings,
        clearCompletedOver:
            !awaitingNextBowler && !isCricketInningsComplete(cs),
      );
      final bowlerOverRuns = _runsConcededInOver(thisOverBalls);
      final bowlerLegalBalls =
          thisOverBalls.where((b) => b.isLegalDelivery).length;
      final needsPick = sId == null ||
          sId.isEmpty ||
          nId == null ||
          nId.isEmpty ||
          bId == null ||
          bId.isEmpty;

      final thisOverStrip = CricketThisOverStrip(
        controller: widget.controller,
        innings: cs.currentInnings,
        onTap: widget.onThisOverTap,
        embedded: true,
      );

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (needsPick)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Tap a player to set striker, non-striker and bowler.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: _BatsmanCard(
                  role: 'Striker',
                  highlight: true,
                  player: announcedPlayerForUserId(m, sId),
                  fallbackUserField: cs.strikerUserId,
                  figures: strikerFigures,
                  busy: busy,
                  onTap: busy
                      ? null
                      : () => _openPicker(
                          context: context,
                          match: m,
                          cs: cs,
                          role: _LineupRole.striker,
                          dismissed: dismissed,
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _BatsmanCard(
                  role: 'Non-striker',
                  player: announcedPlayerForUserId(m, nId),
                  fallbackUserField: cs.nonStrikerUserId,
                  figures: nonStrikerFigures,
                  busy: busy,
                  onTap: busy
                      ? null
                      : () => _openPicker(
                          context: context,
                          match: m,
                          cs: cs,
                          role: _LineupRole.nonStriker,
                          dismissed: dismissed,
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _BowlerOverCard(
            player: announcedPlayerForUserId(m, bId),
            fallbackUserField: cs.bowlerUserId,
            overRuns: bowlerOverRuns,
            overBalls: bowlerLegalBalls,
            busy: busy,
            onBowlerTap: busy
                ? null
                : () => _openPicker(
                    context: context,
                    match: m,
                    cs: cs,
                    role: _LineupRole.bowler,
                    dismissed: dismissed,
                  ),
            thisOver: thisOverStrip,
          ),
        ],
      );
    });
  }
}

class _BatsmanCard extends StatelessWidget {
  const _BatsmanCard({
    required this.role,
    required this.player,
    required this.fallbackUserField,
    required this.figures,
    required this.busy,
    required this.onTap,
    this.highlight = false,
  });

  final String role;
  final AnnouncedPlayerModel? player;
  final dynamic fallbackUserField;
  final _BattingFigures figures;
  final bool busy;
  final VoidCallback? onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = player?.avatar;
    final name =
        player?.name ??
        UserFieldInstance(fallbackUserField).getName() ??
        'Select player';
    final placeholder =
        player == null &&
        (UserFieldInstance(fallbackUserField).getId() == null ||
            UserFieldInstance(fallbackUserField).getId()!.isEmpty);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: highlight
                  ? const Color(AppColors.primaryColor).withValues(alpha: 0.45)
                  : const Color(AppColors.dividerColor).withValues(alpha: 0.75),
              width: highlight ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      role.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: highlight
                            ? const Color(AppColors.primaryColor)
                            : const Color(AppColors.textSecondaryColor),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.swap_horiz_rounded,
                    size: 18,
                    color: onTap != null && !busy
                        ? const Color(AppColors.primaryColor)
                        : Colors.grey.shade400,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(
                      AppColors.primaryColor,
                    ).withValues(alpha: 0.12),
                    backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                        ? AppNetworkImage.provider(avatarUrl)
                        : null,
                    child: avatarUrl == null || avatarUrl.isEmpty
                        ? Icon(
                            Icons.person,
                            size: 18,
                            color: placeholder
                                ? Colors.grey.shade400
                                : const Color(AppColors.primaryColor),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          placeholder ? 'Tap to select' : name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: placeholder
                                ? Colors.grey.shade500
                                : const Color(AppColors.textColor),
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${figures.runs}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  letterSpacing: -0.3,
                                  color: Color(AppColors.textColor),
                                ),
                              ),
                              TextSpan(
                                text: ' (${figures.balls})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: Color(AppColors.textSecondaryColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BowlerOverCard extends StatelessWidget {
  const _BowlerOverCard({
    required this.player,
    required this.fallbackUserField,
    required this.overRuns,
    required this.overBalls,
    required this.busy,
    required this.onBowlerTap,
    required this.thisOver,
  });

  final AnnouncedPlayerModel? player;
  final dynamic fallbackUserField;
  final int overRuns;
  final int overBalls;
  final bool busy;
  final VoidCallback? onBowlerTap;
  final Widget thisOver;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = player?.avatar;
    final name =
        player?.name ??
        UserFieldInstance(fallbackUserField).getName() ??
        'Select player';
    final placeholder =
        player == null &&
        (UserFieldInstance(fallbackUserField).getId() == null ||
            UserFieldInstance(fallbackUserField).getId()!.isEmpty);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(AppColors.dividerColor).withValues(alpha: 0.75),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onBowlerTap,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(
                          AppColors.primaryColor,
                        ).withValues(alpha: 0.12),
                        backgroundImage:
                            avatarUrl != null && avatarUrl.isNotEmpty
                            ? AppNetworkImage.provider(avatarUrl)
                            : null,
                        child: avatarUrl == null || avatarUrl.isEmpty
                            ? Icon(
                                Icons.person,
                                size: 20,
                                color: placeholder
                                    ? Colors.grey.shade400
                                    : const Color(AppColors.primaryColor),
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'BOWLER',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                                color: Color(AppColors.textSecondaryColor),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              placeholder ? 'Tap to select' : name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: placeholder
                                    ? Colors.grey.shade500
                                    : const Color(AppColors.textColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '$overRuns ($overBalls)',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(AppColors.textSecondaryColor),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.swap_horiz_rounded,
                        size: 18,
                        color: onBowlerTap != null && !busy
                            ? const Color(AppColors.primaryColor)
                            : Colors.grey.shade400,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: Color(AppColors.dividerColor)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: thisOver,
            ),
          ],
        ),
      ),
    );
  }
}
