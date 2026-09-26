import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../components/scoring/cricket/cricket_components.dart';
import '../../core/components/app_bar/app_bar_background.dart';
import '../../core/config/constants.dart';
import '../../core/query/query_keys.dart';
import '../../core/query/query_retry.dart';
import '../../core/utils/app_snackbar.dart';
import '../../match_up/matchmaking_service.dart';
import '../../match_up/announced_players/model/announced_player_model.dart';
import '../../match_up/model/team_match_model.dart';
import 'cricket_scoring_api_service.dart';
import 'cricket_scoring_controller.dart';
import 'model/cricket_over_event_model.dart';
import 'model/cricket_scoring_models.dart';

enum _WicketUiKind { bowled, caught, lbw, runOut, stumped, hitWicket }

class CricketScoreBoardScreen extends StatefulWidget {
  const CricketScoreBoardScreen({super.key});

  @override
  State<CricketScoreBoardScreen> createState() =>
      _CricketScoreBoardScreenState();
}

class _CricketScoreBoardScreenState extends State<CricketScoreBoardScreen> {
  late final CricketScoringController _scoringController;

  late final String _teamMatchId;

  /// Context of the open scoring keypad sheet (if any).
  BuildContext? _controlsSheetContext;

  /// API failures already toast from [ApiService]. Snackbar only for local checks.
  void _showLocalError(String title) {
    final message = _scoringController.errorMessage.value;
    if (message == null || message.isEmpty) return;
    AppSnackbar.error(title: title, message: message);
  }

  @override
  void initState() {
    super.initState();
    _scoringController = Get.find<CricketScoringController>();
    final args = (Get.arguments as Map?)?.cast<String, dynamic>() ?? const {};
    _teamMatchId = args['matchId']?.toString() ?? '';
    _scoringController.bindScoreboard(_teamMatchId);
    if (_teamMatchId.isNotEmpty) {
      unawaited(_scoringController.joinLiveSession(_teamMatchId));
    }
  }

  @override
  void dispose() {
    unawaited(_scoringController.leaveLiveSession());
    super.dispose();
  }

  void _closeControlsSheetIfNeeded() {
    final sheetContext = _controlsSheetContext;
    if (sheetContext == null || !sheetContext.mounted) return;

    final match = _scoringController.cricketMatch.value;
    final cs = match?.cricketState;
    if (cs == null) return;

    final overs = _scoringController.cricketOvers.toList();
    final shouldClose =
        isCricketInningsComplete(cs) || isAwaitingNextOverBowler(cs, overs);
    if (!shouldClose) return;

    Navigator.pop(sheetContext);
  }

  Future<void> _send(
    CricketOutcome outcome, {
    String? incomingBatsmanUserId,
  }) async {
    final cs = _scoringController.cricketMatch.value?.cricketState;
    final strikerId = cs?.strikerUserHelper.getId() ?? '';
    final nonStrikerId = cs?.nonStrikerUserHelper.getId() ?? '';
    final bowlerId = cs?.bowlerUserHelper.getId() ?? '';
    debugPrint(
      '[CricketScoreBoardScreen] _send: $strikerId, $nonStrikerId, $bowlerId',
    );
    if (strikerId.isEmpty || nonStrikerId.isEmpty || bowlerId.isEmpty) {
      AppSnackbar.info(
        title: 'Select players',
        message: 'Please select striker, non-striker and bowler first.',
      );
      return;
    }

    final over = await _scoringController.appendCricketBall(
      AppendCricketBallRequest(
        strikerUserId: strikerId,
        nonStrikerUserId: nonStrikerId,
        bowlerUserId: bowlerId,
        outcome: outcome,
        incomingBatsmanUserId: incomingBatsmanUserId,
      ),
    );
    if (!mounted) return;
    if (over == null) {
      _showLocalError('Update failed');
      return;
    }
    _closeControlsSheetIfNeeded();
  }

  Future<void> _undoLastBall() async {
    final ok = await _scoringController.undoLastCricketBall();
    if (!mounted || ok) return;
    _showLocalError('Undo failed');
  }

  Future<void> _redoLastBall() async {
    final ok = await _scoringController.redoLastCricketBall();
    if (!mounted || ok) return;
    _showLocalError('Redo failed');
  }

  Future<void> _showSubstitution() async {
    final match = _scoringController.cricketMatch.value;
    if (match == null || match.cricketState == null) return;

    final fromId = _scoringController.fromTeamId;
    final toId = _scoringController.toTeamId;
    if (fromId.isEmpty || toId.isEmpty) {
      AppSnackbar.info(
        title: 'Teams needed',
        message: 'Match teams are not available yet.',
      );
      return;
    }

    final cs = match.cricketState!;
    final prevStriker = cs.strikerUserHelper.getId() ?? '';
    final prevNon = cs.nonStrikerUserHelper.getId() ?? '';
    final prevBowler = cs.bowlerUserHelper.getId() ?? '';

    final result = await CricketSubstitutionSheet.show(
      context: context,
      match: match,
      fromTeamId: fromId,
      toTeamId: toId,
      teamLabelForId: _scoringController.teamLabelForId,
    );
    if (!mounted || result == null) return;

    final over = await _scoringController.appendCricketSubstitution(
      teamId: result.teamId,
      playerOffParticipantId: result.playerOffParticipantId,
      playerOnParticipantId: result.playerOnParticipantId,
    );
    if (!mounted) return;
    if (over == null) {
      _showLocalError('Substitution failed');
      return;
    }

    // If the player off held a live role, put the player on into that role.
    final off = result.playerOffParticipantId;
    final on = result.playerOnParticipantId;
    final UpdateCricketStateRequest? rolePatch;
    if (off == prevStriker && prevStriker.isNotEmpty) {
      rolePatch = UpdateCricketStateRequest(strikerUserId: on);
    } else if (off == prevNon && prevNon.isNotEmpty) {
      rolePatch = UpdateCricketStateRequest(nonStrikerUserId: on);
    } else if (off == prevBowler && prevBowler.isNotEmpty) {
      rolePatch = UpdateCricketStateRequest(bowlerUserId: on);
    } else {
      rolePatch = null;
    }

    if (rolePatch != null) {
      final ok = await _scoringController.updateCricketState(rolePatch);
      if (!mounted) return;
      if (!ok) {
        AppSnackbar.info(
          title: 'Update lineup',
          message:
              'Substitution recorded. Please set the vacant '
              'striker / non-striker / bowler role.',
        );
      }
    }
  }

  Future<void> _startNextInning() async {
    final ok = await _scoringController.changeCricketInning();
    if (!mounted || ok) return;
    _showLocalError('Could not start next innings');
  }

  Future<void> _completeMatch() async {
    final ok = await _scoringController.completeCricketMatch();
    if (!mounted || ok) return;
    _showLocalError('Could not end match');
  }

  Future<void> _onInningsCompletedAction(CricketStateModel cs) async {
    final hasNextInnings = cs.currentInnings < cs.inningsSummaries.length;
    if (hasNextInnings) {
      await _startNextInning();
    } else {
      await _completeMatch();
    }
  }

  Widget _buildInningsCompletedFooter(CricketStateModel cs) {
    final hasNextInnings = cs.currentInnings < cs.inningsSummaries.length;
    final busy = hasNextInnings
        ? _scoringController.isChangingCricketInning.value
        : _scoringController.isCompletingCricketMatch.value;
    final buttonLabel = hasNextInnings ? 'Start next innings' : 'End match';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Innings completed',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Color(AppColors.textColor),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          hasNextInnings
              ? 'Set the lineup for the next innings, then start scoring.'
              : 'Confirm to finish the match.',
          style: const TextStyle(
            fontSize: 13,
            height: 1.35,
            color: Color(AppColors.textSecondaryColor),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: busy ? null : () => _onInningsCompletedAction(cs),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            backgroundColor: const Color(AppColors.primaryColor),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(buttonLabel),
        ),
      ],
    );
  }

  Widget _buildMatchCompletedFooter() {
    return const Row(
      children: [
        Icon(
          Icons.emoji_events_rounded,
          color: Color(AppColors.primaryColor),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Match completed',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(AppColors.textColor),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _sendRuns(int runs) async {
    if (runs <= 0) {
      await _send(const DotOutcome());
      return;
    }
    await _send(RunsOutcome(offBat: runs));
  }

  void _openControlsSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        _controlsSheetContext = ctx;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Text(
                          'Score ball',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                            color: Color(AppColors.textColor),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8, top: 4),
                  child: _buildKeypad(),
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      _controlsSheetContext = null;
    });
  }

  void _openOversSheet(int innings) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final height = MediaQuery.sizeOf(ctx).height * 0.65;
        return SafeArea(
          child: SizedBox(
            height: height,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Overs',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                            color: Color(AppColors.textColor),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: CricketOversTable(
                      controller: _scoringController,
                      innings: innings,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Active keypad only — innings/match footers are handled separately.
  Widget _buildKeypad() {
    return CricketActionButtons(
      controller: _scoringController,
      onRuns: _sendRuns,
      onWide: _showWidePicker,
      onNoBall: _showNoBallPicker,
      onWicket: _showWicketFlow,
      onSubstitute: _showSubstitution,
      onUndo: _undoLastBall,
      onRedo: _redoLastBall,
    );
  }

  Widget? _buildStatusFooter(TeamMatchModel match) {
    final cs = match.cricketState!;
    if (match.status == TeamMatchStatus.completed ||
        match.status == TeamMatchStatus.draw) {
      return _buildMatchCompletedFooter();
    }
    if (isCricketInningsComplete(cs)) {
      return _buildInningsCompletedFooter(cs);
    }
    final overs = _scoringController.cricketOvers.toList();
    if (isAwaitingNextOverBowler(cs, overs)) {
      return _buildOverCompletedFooter(match, cs, overs);
    }
    return null;
  }

  Widget _buildOverCompletedFooter(
    TeamMatchModel match,
    CricketStateModel cs,
    List<CricketOverEvent> overs,
  ) {
    final busy = _scoringController.isUpdatingCricketLineup.value;
    final overNumber = (currentInningsSummary(cs)?.legalBalls ?? 0) ~/ 6;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Over $overNumber complete',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Color(AppColors.textColor),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Select a new bowler to start the next over.',
          style: TextStyle(
            fontSize: 13,
            height: 1.35,
            color: Color(AppColors.textSecondaryColor),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: busy
              ? null
              : () => _startNextOver(match, cs, overs),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            backgroundColor: const Color(AppColors.primaryColor),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Next over'),
        ),
      ],
    );
  }

  Future<void> _startNextOver(
    TeamMatchModel match,
    CricketStateModel cs,
    List<CricketOverEvent> overs,
  ) async {
    final previousBowlerId = completedOverBowlerId(cs, overs) ?? '';
    final bowlingId = cs.bowlingTeamHelper.getId() ?? '';
    final candidates = playingXiForTeam(match, bowlingId).where((p) {
      final id = p.participantId ?? '';
      return id.isNotEmpty && id != previousBowlerId;
    }).toList();

    if (candidates.isEmpty) {
      AppSnackbar.info(
        title: 'No bowler available',
        message: previousBowlerId.isEmpty
            ? 'No eligible players in the bowling XI.'
            : 'Need another bowler — previous bowler cannot continue.',
      );
      return;
    }

    final picked = await showModalBottomSheet<AnnouncedPlayerModel>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  'Select bowler for next over',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(AppColors.textColor),
                  ),
                ),
              ),
              for (final p in candidates)
                AnnouncedPlayerListTile.fromPlayer(
                  p,
                  onTap: () => Navigator.pop(ctx, p),
                ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || picked == null) return;
    final id = picked.participantId;
    if (id == null || id.isEmpty || id == previousBowlerId) return;

    final ok = await _scoringController.updateCricketState(
      UpdateCricketStateRequest(bowlerUserId: id),
    );
    if (!mounted) return;
    if (!ok) _showLocalError('Could not set bowler');
  }

  Future<int?> _pickRunsGrid({
    required String title,
    required int min,
    required int max,
  }) {
    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Color(AppColors.textColor),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (var i = min; i <= max; i++)
                    SizedBox(
                      width: 52,
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, i),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(AppColors.textColor),
                          side: const BorderSide(
                            color: Color(AppColors.dividerColor),
                          ),
                        ),
                        child: Text(
                          '$i',
                          style: const TextStyle(
                            color: Color(AppColors.textColor),
                          ),
                        ),
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

  Future<void> _showWidePicker() async {
    final extra = await _pickRunsGrid(
      title: 'Wide — extra runs (0–5)',
      min: 0,
      max: 5,
    );
    if (!mounted || extra == null) return;
    await _send(WideOutcome(additionalRuns: extra));
  }

  Future<void> _showNoBallPicker() async {
    final offBat = await _pickRunsGrid(
      title: 'No ball — runs off bat (0–6)',
      min: 0,
      max: 6,
    );
    if (!mounted || offBat == null) return;
    await _send(NoBallOutcome(offBat: offBat));
  }

  Future<String?> _pickIncomingBatsman(String dismissedUserId) async {
    final match = _scoringController.cricketMatch.value;
    final cs = match?.cricketState;
    if (match == null || cs == null) return null;
    final battingId = cs.battingTeamHelper.getId() ?? '';
    final dismissed = dismissedBatsmanUserIds(
      _scoringController.cricketOvers.toList(),
      cs.currentInnings,
    );
    final candidates = playingXiForTeam(match, battingId).where((p) {
      final id = p.participantId ?? '';
      return id.isNotEmpty && id != dismissedUserId && !dismissed.contains(id);
    }).toList();
    if (candidates.isEmpty) {
      AppSnackbar.info(
        title: 'No batsman available',
        message: 'No eligible players left in the batting XI.',
      );
      return null;
    }
    final picked = await showModalBottomSheet<AnnouncedPlayerModel>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  'Incoming batsman',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(AppColors.textColor),
                  ),
                ),
              ),
              for (final player in candidates)
                AnnouncedPlayerListTile.fromPlayer(
                  player,
                  onTap: () => Navigator.pop(ctx, player),
                ),
            ],
          ),
        ),
      ),
    );
    return picked?.participantId;
  }

  Future<void> _sendDismissal(
    CricketOutcome outcome, {
    required String dismissedUserId,
  }) async {
    final incoming = await _pickIncomingBatsman(dismissedUserId);
    if (!mounted || incoming == null) return;
    await _send(outcome, incomingBatsmanUserId: incoming);
  }

  Future<AnnouncedPlayerModel?> _pickBowlingSquadPlayer(String title) async {
    final match = _scoringController.cricketMatch.value;
    final cs = match?.cricketState;
    if (match == null || cs == null) return null;
    final bowlingId = cs.bowlingTeamHelper.getId() ?? '';
    final candidates = playingXiForTeam(match, bowlingId);
    if (candidates.isEmpty) {
      AppSnackbar.info(
        title: 'No fielders',
        message: 'Bowling side playing XI is empty.',
      );
      return null;
    }
    return showModalBottomSheet<AnnouncedPlayerModel>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(AppColors.textColor),
                  ),
                ),
              ),
              for (final player in candidates)
                AnnouncedPlayerListTile.fromPlayer(
                  player,
                  onTap: () => Navigator.pop(ctx, player),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showWicketFlow() async {
    final match = _scoringController.cricketMatch.value;
    final cs = match?.cricketState;
    if (match == null || cs == null) return;
    final strikerId = cs.strikerUserHelper.getId() ?? '';
    final nonStrikerId = cs.nonStrikerUserHelper.getId() ?? '';
    if (strikerId.isEmpty || nonStrikerId.isEmpty) {
      AppSnackbar.info(
        title: 'Select players',
        message: 'Set striker and non-striker in Players above.',
      );
      return;
    }

    final kind = await showModalBottomSheet<_WicketUiKind>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              const Text(
                'Wicket type',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Color(AppColors.textColor),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                title: const Text(
                  'Bowled',
                  style: TextStyle(color: Color(AppColors.textColor)),
                ),
                onTap: () => Navigator.pop(ctx, _WicketUiKind.bowled),
              ),
              ListTile(
                title: const Text(
                  'Caught',
                  style: TextStyle(color: Color(AppColors.textColor)),
                ),
                onTap: () => Navigator.pop(ctx, _WicketUiKind.caught),
              ),
              ListTile(
                title: const Text(
                  'LBW',
                  style: TextStyle(color: Color(AppColors.textColor)),
                ),
                onTap: () => Navigator.pop(ctx, _WicketUiKind.lbw),
              ),
              ListTile(
                title: const Text(
                  'Run out',
                  style: TextStyle(color: Color(AppColors.textColor)),
                ),
                onTap: () => Navigator.pop(ctx, _WicketUiKind.runOut),
              ),
              ListTile(
                title: const Text(
                  'Stumped',
                  style: TextStyle(color: Color(AppColors.textColor)),
                ),
                onTap: () => Navigator.pop(ctx, _WicketUiKind.stumped),
              ),
              ListTile(
                title: const Text(
                  'Hit wicket',
                  style: TextStyle(color: Color(AppColors.textColor)),
                ),
                onTap: () => Navigator.pop(ctx, _WicketUiKind.hitWicket),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || kind == null) return;

    switch (kind) {
      case _WicketUiKind.bowled:
        final offBat = await _pickRunsGrid(
          title: 'Runs off bat (if any)',
          min: 0,
          max: 6,
        );
        if (!mounted || offBat == null) return;
        await _sendDismissal(
          WicketBowledOutcome(offBat: offBat),
          dismissedUserId: strikerId,
        );
      case _WicketUiKind.caught:
        final fielder = await _pickBowlingSquadPlayer('Fielder (catcher)');
        if (!mounted || fielder == null) return;
        final fielderId = fielder.participantId;
        if (fielderId == null || fielderId.isEmpty) return;
        final offBat = await _pickRunsGrid(
          title: 'Runs off bat before catch',
          min: 0,
          max: 6,
        );
        if (!mounted || offBat == null) return;
        await _sendDismissal(
          WicketCaughtOutcome(offBat: offBat, fielderUserId: fielderId),
          dismissedUserId: strikerId,
        );
      case _WicketUiKind.lbw:
        final offBat = await _pickRunsGrid(
          title: 'Runs off bat (if any)',
          min: 0,
          max: 6,
        );
        if (!mounted || offBat == null) return;
        await _sendDismissal(
          WicketLbwOutcome(offBat: offBat),
          dismissedUserId: strikerId,
        );
      case _WicketUiKind.runOut:
        final strikerPlayer = announcedPlayerForUserId(match, strikerId);
        final nonPlayer = announcedPlayerForUserId(match, nonStrikerId);
        final strikerName = strikerPlayer?.name ?? 'Striker';
        final nonName = nonPlayer?.name ?? 'Non-striker';
        final dismissed = await showModalBottomSheet<String>(
          context: context,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                const Text(
                  'Who is out?',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(AppColors.textColor),
                  ),
                ),
                AnnouncedPlayerListTile(
                  name: strikerName,
                  avatarUrl: strikerPlayer?.avatar,
                  subtitle: 'Striker',
                  onTap: () => Navigator.pop(ctx, strikerId),
                ),
                AnnouncedPlayerListTile(
                  name: nonName,
                  avatarUrl: nonPlayer?.avatar,
                  subtitle: 'Non-striker',
                  onTap: () => Navigator.pop(ctx, nonStrikerId),
                ),
              ],
            ),
          ),
        );
        if (!mounted || dismissed == null || dismissed.isEmpty) return;
        final runsOff = await _pickRunsGrid(
          title: 'Runs off bat',
          min: 0,
          max: 6,
        );
        if (!mounted || runsOff == null) return;
        final addFielder = await showModalBottomSheet<bool>(
          context: context,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                const Text(
                  'Fielder assist?',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(AppColors.textColor),
                  ),
                ),
                ListTile(
                  title: const Text(
                    'Skip',
                    style: TextStyle(color: Color(AppColors.textColor)),
                  ),
                  onTap: () => Navigator.pop(ctx, false),
                ),
                ListTile(
                  title: const Text(
                    'Pick fielder',
                    style: TextStyle(color: Color(AppColors.textColor)),
                  ),
                  onTap: () => Navigator.pop(ctx, true),
                ),
              ],
            ),
          ),
        );
        if (!mounted) return;
        String? fielderId;
        if (addFielder == true) {
          final f = await _pickBowlingSquadPlayer('Throwing fielder');
          if (!mounted) return;
          fielderId = f?.participantId;
        }
        await _sendDismissal(
          WicketRunOutOutcome(
            runsOffBat: runsOff,
            dismissedUserId: dismissed,
            fielderUserId: fielderId,
          ),
          dismissedUserId: dismissed,
        );
      case _WicketUiKind.stumped:
        final keeper = await _pickBowlingSquadPlayer('Wicket-keeper');
        if (!mounted || keeper == null) return;
        final keeperId = keeper.participantId;
        if (keeperId == null || keeperId.isEmpty) return;
        final offBat = await _pickRunsGrid(
          title: 'Runs off bat (if any)',
          min: 0,
          max: 6,
        );
        if (!mounted || offBat == null) return;
        await _sendDismissal(
          WicketStumpedOutcome(offBat: offBat, wicketKeeperUserId: keeperId),
          dismissedUserId: strikerId,
        );
      case _WicketUiKind.hitWicket:
        final offBat = await _pickRunsGrid(
          title: 'Runs off bat (if any)',
          min: 0,
          max: 6,
        );
        if (!mounted || offBat == null) return;
        await _sendDismissal(
          WicketHitWicketOutcome(offBat: offBat),
          dismissedUserId: strikerId,
        );
    }
  }

  Future<void> _startCricketSession() async {
    final overs = _scoringController.parsedMaxOvers;
    if (_scoringController.battingTeamId.value.isEmpty ||
        _scoringController.bowlingTeamIdResolved.isEmpty ||
        _scoringController.fromTeamId.isEmpty ||
        _scoringController.toTeamId.isEmpty) {
      AppSnackbar.info(
        title: 'Choose batting side',
        message:
            'Select which team bats first. Bowling will be the other team.',
      );
      return;
    }
    if (overs == null) {
      AppSnackbar.info(
        title: 'Overs',
        message:
            'Enter overs per innings (${CricketScoringController.minOvers}–${CricketScoringController.maxOversLimit}).',
      );
      return;
    }

    await _scoringController.createCricketSession(
      CreateCricketSessionRequest(
        battingTeamId: _scoringController.battingTeamId.value,
        bowlingTeamId: _scoringController.bowlingTeamIdResolved,
        maxOvers: overs,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        centerTitle: true,
        titleSpacing: 8,
        title: Obx(() {
          final match = _scoringController.cricketMatch.value;
          if (match == null || match.cricketState == null) {
            return const Text('Start match');
          }
          final left = _scoringController.fromTeamName;
          final right = _scoringController.toTeamName;
          final leftLogo =
              match.fromTeamHelper.getSubsetModel()?.logo;
          final rightLogo = match.toTeamHelper.getSubsetModel()?.logo;
          return VsAppBarTitle(
            leftName: left.isNotEmpty ? left : '?',
            rightName: right.isNotEmpty ? right : '?',
            leftLogoUrl: leftLogo,
            rightLogoUrl: rightLogo,
          );
        }),
      ),
      backgroundColor: const Color(AppColors.backgroundColor),
      body: HookBuilder(
        builder: (context) {
          final hasMatchId = _teamMatchId.isNotEmpty;
          final cricketApi = useMemoized(() => CricketScoringApiService());
          final matchmaking = useMemoized(() => MatchmakingService());

          final metaQuery = useQuery<TeamMatchModel, Object>(
            QueryKeys.matchChallengeDetail(_teamMatchId),
            (_) async {
              final loaded =
                  await matchmaking.getTeamMatchById(_teamMatchId);
              if (loaded == null) {
                throw Exception('Could not load match.');
              }
              return loaded;
            },
            enabled: hasMatchId,
            retry: noRetry,
          );

          final sessionQuery = useQuery<TeamMatchModel, Object>(
            QueryKeys.cricketSession(_teamMatchId),
            (_) async {
              final loaded =
                  await cricketApi.getCricketSession(_teamMatchId);
              if (loaded == null) {
                throw Exception('Could not load match.');
              }
              return loaded;
            },
            enabled: hasMatchId,
            retry: noRetry,
          );

          final sessionHasState =
              sessionQuery.data?.cricketState != null;
          final oversQuery = useQuery<List<CricketOverEvent>, Object>(
            QueryKeys.cricketOvers(_teamMatchId),
            (_) async {
              final overs = await cricketApi.listCricketOvers(
                teamMatchId: _teamMatchId,
              );
              return List<CricketOverEvent>.from(overs)
                ..sort((a, b) => a.sequence.compareTo(b.sequence));
            },
            enabled: hasMatchId && sessionHasState,
            retry: noRetry,
          );

          useEffect(() {
            final session = sessionQuery.data;
            final meta = metaQuery.data;
            final matchForSeed = session?.cricketState != null
                ? session
                : (meta ?? session);
            final overs = oversQuery.data;
            // Defer Rx writes — seeding during HookBuilder build marks Obx dirty mid-frame.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _scoringController.seedFromQuery(
                match: matchForSeed,
                overs: overs,
              );
            });
            return null;
          }, [sessionQuery.data, metaQuery.data, oversQuery.data]);

          void retryColdLoad() {
            metaQuery.refetch();
            sessionQuery.refetch();
            if (sessionHasState) oversQuery.refetch();
          }

          if (!hasMatchId) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: MatchStatsErrorCard(
                  message: 'Missing match id.',
                  onRetry: () {},
                ),
              ),
            );
          }

          final coldLoading = sessionQuery.isLoading ||
              (sessionQuery.isFetching && sessionQuery.data == null) ||
              (sessionHasState &&
                  (oversQuery.isLoading ||
                      (oversQuery.isFetching && oversQuery.data == null)));

          if (coldLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (sessionQuery.isError && sessionQuery.data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: MatchStatsErrorCard(
                  message: sessionQuery.error?.toString() ??
                      'No match data loaded.',
                  onRetry: retryColdLoad,
                ),
              ),
            );
          }

          final queryMatch = metaQuery.data ?? sessionQuery.data;
          final metaPending = (metaQuery.isLoading ||
                  (metaQuery.isFetching && metaQuery.data == null)) &&
              queryMatch == null;

          return Obx(() {
            final live = _scoringController.cricketMatch.value;
            final err = _scoringController.errorMessage.value;
            final hasLiveState = live?.cricketState != null;

            if (hasLiveState) {
              final match = live!;
              final innings = match.cricketState!.currentInnings;
              final statusFooter = _buildStatusFooter(match);
              final canScore = statusFooter == null;

              return Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        12,
                        16,
                        canScore ? 96 : 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CricketMatchStatsPanel(
                            controller: _scoringController,
                            teamLabelForId: _scoringController.teamLabelForId,
                            onRetry: retryColdLoad,
                          ),
                          const SizedBox(height: 24),
                          CricketLineupCard(
                            controller: _scoringController,
                            onThisOverTap: () => _openOversSheet(innings),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (statusFooter != null)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            top: BorderSide(
                              color: const Color(
                                AppColors.dividerColor,
                              ).withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                        child: SafeArea(
                          top: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                            child: statusFooter,
                          ),
                        ),
                      ),
                    ),
                  // Overs FAB always; scoring FAB only while actively scoring.
                  ScoreboardFabShell(
                    onOpenControls: _openControlsSheet,
                    onOpenSecondary: () => _openOversSheet(innings),
                    secondaryTooltip: 'Overs',
                    showControlsFab: canScore,
                    showSecondaryFab: true,
                    fabBottomInset: statusFooter != null ? 120 : 16,
                  ),
                ],
              );
            }

            if (metaPending) {
              return const Center(child: CircularProgressIndicator());
            }

            final startMatch = queryMatch ?? live;
            if (startMatch == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: MatchStatsErrorCard(
                    message: (err != null && err.isNotEmpty)
                        ? err
                        : 'No match data loaded.',
                    onRetry: retryColdLoad,
                  ),
                ),
              );
            }

            // Touch start-session observables so Obx rebuilds on pick/overs.
            final battingId = _scoringController.battingTeamId.value;
            final canStart = _scoringController.canSubmitStart;
            final isStarting =
                _scoringController.isCreatingCricketSession.value;

            return CricketStartSessionPanel(
              match: startMatch,
              battingTeamId: battingId,
              onBattingTeamIdChanged: _scoringController.setBattingTeamId,
              maxOversController: _scoringController.maxOversController,
              onMaxOversChanged: _scoringController.onMaxOversChanged,
              minOvers: CricketScoringController.minOvers,
              maxOversLimit: CricketScoringController.maxOversLimit,
              isStarting: isStarting,
              canStart: canStart,
              errorText: err,
              onStart: _startCricketSession,
            );
          });
        },
      ),
    );
  }
}
