import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/config/constants.dart';
import '../../../core/models/user_field_instance.dart';
import '../../../match_up/announced_players/model/announced_player_model.dart';
import '../../../match_up/model/team_match_model.dart';
import '../../../scoring/cricket/cricket_scoring_controller.dart';
import '../../../scoring/cricket/model/cricket_ball_event_model.dart';
import '../../../scoring/cricket/model/cricket_scoring_models.dart';

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
    if (p.userIdHelper.getId() == userId) return p;
  }
  return null;
}

List<AnnouncedPlayerModel> playingXiForTeam(
  TeamMatchModel match,
  String teamId,
) {
  if (teamId.isEmpty) return const [];
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

List<CricketBallEvent> currentOverBallsForBowler(
  List<CricketOverEvent> overs,
  int innings,
  String? bowlerUserId,
) {
  if (bowlerUserId == null || bowlerUserId.isEmpty) {
    return const [];
  }

  CricketOverEvent? latestOver;
  for (final over in overs) {
    if (over.innings != innings) continue;
    final overBowlerId = UserFieldInstance(over.bowlerUserId).getId();
    if (overBowlerId != bowlerUserId) continue;
    if (latestOver == null ||
        over.overAfter > latestOver.overAfter ||
        over.sequence > latestOver.sequence) {
      latestOver = over;
    }
  }

  return latestOver?.ballEvents ?? const [];
}

int _runsConcededInOver(List<CricketBallEvent> balls) {
  var sum = 0;
  for (final ball in balls) {
    sum += ball.totalRunsOnDelivery;
  }
  return sum;
}

String _ballDeliveryLabel(CricketBallEvent ball) {
  if (ball.isWicket) return 'W';
  if (ball.extrasNoBall) {
    return ball.runsOffBat > 0 ? '${ball.runsOffBat}Nb' : 'Nb';
  }
  if (ball.extrasWide > 0) {
    return ball.totalRunsOnDelivery > 1
        ? '${ball.totalRunsOnDelivery}Wd'
        : 'Wd';
  }
  if (ball.extrasBye > 0) {
    return '${ball.extrasBye}B';
  }
  if (ball.extrasLegBye > 0) {
    return '${ball.extrasLegBye}Lb';
  }
  if (ball.runsOffBat == 0 && ball.totalRunsOnDelivery == 0) {
    return '·';
  }
  return '${ball.runsOffBat}';
}

/// Striker, non-striker, and bowler with avatars; tap to pick from announced squads.
class CricketLineupCard extends StatefulWidget {
  const CricketLineupCard({
    super.key,
    required this.controller,
  });

  final CricketScoringController controller;

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
                    ),
                  ),
                ),
                for (var index = 0; index < candidates.length; index++)
                  Builder(
                    builder: (context) {
                      final p = candidates[index];
                      final uid = p.userIdHelper.getId() ?? '';
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

                      return ListTile(
                        enabled: !disabled,
                        leading: CircleAvatar(
                          backgroundColor: const Color(
                            AppColors.primaryColor,
                          ).withValues(alpha: 0.12),
                          backgroundImage:
                              p.avatar != null && p.avatar!.isNotEmpty
                              ? NetworkImage(p.avatar!)
                              : null,
                          child: p.avatar == null || p.avatar!.isEmpty
                              ? const Icon(
                                  Icons.person,
                                  color: Color(AppColors.primaryColor),
                                )
                              : null,
                        ),
                        title: Text(p.name),
                        subtitle: disabled
                            ? Text(
                                dismissed.contains(uid)
                                    ? 'Out'
                                    : 'Already at other crease',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(AppColors.errorColor),
                                ),
                              )
                            : null,
                        onTap: disabled ? null : () => Navigator.pop(ctx, p),
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
    final id = picked.userIdHelper.getId();
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
      final bowlerOverBalls = currentOverBallsForBowler(
        overs,
        cs.currentInnings,
        bId,
      );
      final bowlerOverRuns = _runsConcededInOver(bowlerOverBalls);

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.groups_rounded,
                  size: 20,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Lineup',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(AppColors.textColor),
                  ),
                ),
                if (busy) ...[
                  const SizedBox(width: 10),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
            if (sId == null ||
                sId.isEmpty ||
                nId == null ||
                nId.isEmpty ||
                bId == null ||
                bId.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Select striker, non-striker and bowler from your squads.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _BatsmanCard(
                    label: 'Striker',
                    labelIcon: Icons.flash_on_rounded,
                    player: announcedPlayerForUserId(m, sId),
                    fallbackUserField: cs.strikerUserId,
                    runs: strikerFigures.runs,
                    balls: strikerFigures.balls,
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
                const SizedBox(width: 10),
                Expanded(
                  child: _BatsmanCard(
                    label: 'Non-striker',
                    labelIcon: Icons.pause_circle_outline_rounded,
                    player: announcedPlayerForUserId(m, nId),
                    fallbackUserField: cs.nonStrikerUserId,
                    runs: nonStrikerFigures.runs,
                    balls: nonStrikerFigures.balls,
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
            const SizedBox(height: 10),
            _BowlerCard(
              player: announcedPlayerForUserId(m, bId),
              fallbackUserField: cs.bowlerUserId,
              overBalls: bowlerOverBalls,
              overRuns: bowlerOverRuns,
              busy: busy,
              onTap: busy
                  ? null
                  : () => _openPicker(
                      context: context,
                      match: m,
                      cs: cs,
                      role: _LineupRole.bowler,
                      dismissed: dismissed,
                    ),
            ),
          ],
        ),
      );
    });
  }
}

class _RoleLabel extends StatelessWidget {
  const _RoleLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _BatsmanCard extends StatelessWidget {
  const _BatsmanCard({
    required this.label,
    required this.labelIcon,
    required this.player,
    required this.fallbackUserField,
    required this.runs,
    required this.balls,
    required this.busy,
    required this.onTap,
  });

  final String label;
  final IconData labelIcon;
  final AnnouncedPlayerModel? player;
  final dynamic fallbackUserField;
  final int runs;
  final int balls;
  final bool busy;
  final VoidCallback? onTap;

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
      color: const Color(AppColors.backgroundColor),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 40, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RoleLabel(icon: labelIcon, label: label),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(
                          AppColors.primaryColor,
                        ).withValues(alpha: 0.12),
                        backgroundImage:
                            avatarUrl != null && avatarUrl.isNotEmpty
                            ? NetworkImage(avatarUrl)
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
                              softWrap: true,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                height: 1.25,
                                color: placeholder
                                    ? Colors.grey.shade500
                                    : const Color(AppColors.textColor),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$runs ($balls)',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(AppColors.textSecondaryColor),
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
            Positioned(
              top: 4,
              right: 4,
              child: _LineupSwitchButton(onTap: onTap, busy: busy),
            ),
          ],
        ),
      ),
    );
  }
}

class _BowlerCard extends StatelessWidget {
  const _BowlerCard({
    required this.player,
    required this.fallbackUserField,
    required this.overBalls,
    required this.overRuns,
    required this.busy,
    required this.onTap,
  });

  final AnnouncedPlayerModel? player;
  final dynamic fallbackUserField;
  final List<CricketBallEvent> overBalls;
  final int overRuns;
  final bool busy;
  final VoidCallback? onTap;

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
      color: const Color(AppColors.backgroundColor),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 40, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _RoleLabel(
                    icon: Icons.sports_baseball_rounded,
                    label: 'Bowler',
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(
                          AppColors.primaryColor,
                        ).withValues(alpha: 0.12),
                        backgroundImage:
                            avatarUrl != null && avatarUrl.isNotEmpty
                            ? NetworkImage(avatarUrl)
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
                              softWrap: true,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                height: 1.25,
                                color: placeholder
                                    ? Colors.grey.shade500
                                    : const Color(AppColors.textColor),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$overRuns (${overBalls.length})',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(AppColors.textSecondaryColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (overBalls.isEmpty)
                    Text(
                      'No balls bowled yet.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        for (final ball in overBalls)
                          _DeliveryChip(
                            label: _ballDeliveryLabel(ball),
                            isWicket: ball.isWicket,
                            isExtra: !ball.isLegalDelivery,
                          ),
                      ],
                    ),
                ],
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: _LineupSwitchButton(onTap: onTap, busy: busy),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineupSwitchButton extends StatelessWidget {
  const _LineupSwitchButton({required this.onTap, required this.busy});

  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !busy;

    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            Icons.swap_horiz_rounded,
            size: 18,
            color: enabled
                ? const Color(AppColors.primaryColor)
                : Colors.grey.shade400,
          ),
        ),
      ),
    );
  }
}

class _DeliveryChip extends StatelessWidget {
  const _DeliveryChip({
    required this.label,
    required this.isWicket,
    required this.isExtra,
  });

  final String label;
  final bool isWicket;
  final bool isExtra;

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color foreground;
    if (isWicket) {
      background = const Color(0xFFFFE8E8);
      foreground = const Color(0xFFB42318);
    } else if (isExtra) {
      background = const Color(0xFFFFF4E5);
      foreground = const Color(0xFFB54708);
    } else {
      background = Colors.white;
      foreground = const Color(AppColors.textColor);
    }

    return Container(
      constraints: const BoxConstraints(minWidth: 28),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: foreground.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}
