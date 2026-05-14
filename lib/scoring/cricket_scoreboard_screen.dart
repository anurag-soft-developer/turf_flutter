import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../components/scoring/cricket/cricket_components.dart';
import '../core/config/constants.dart';
import '../core/utils/app_snackbar.dart';
import '../match_up/matchmaking_service.dart';
import '../match_up/announced_players/model/announced_player_model.dart';
import '../match_up/model/team_match_model.dart';
import 'model/scoring_models.dart';
import 'scoring_controller.dart';

enum _WicketUiKind { bowled, caught, lbw, runOut, stumped, hitWicket }

class CricketScoreBoardScreen extends StatefulWidget {
  const CricketScoreBoardScreen({super.key});

  @override
  State<CricketScoreBoardScreen> createState() =>
      _CricketScoreBoardScreenState();
}

class _CricketScoreBoardScreenState extends State<CricketScoreBoardScreen> {
  late final ScoringController _scoringController;
  final MatchmakingService _matchmakingService = MatchmakingService();

  late final String _teamMatchId;
  String _fromTeamName = '';
  String _toTeamName = '';
  String _fromTeamId = '';
  String _toTeamId = '';

  /// Empty until the user picks who bats first (start-only flow).
  String _battingTeamId = '';

  bool _isLoadingMeta = true;

  /// Default matches backend `CreateCricketSessionSchema` default (20 overs).
  late final TextEditingController _maxOversController;

  static const int _minOvers = 1;
  static const int _maxOversLimit = 120;

  @override
  void initState() {
    super.initState();
    _maxOversController = TextEditingController(text: '20');
    _scoringController = Get.find<ScoringController>();
    final args = (Get.arguments as Map?)?.cast<String, dynamic>() ?? const {};
    _teamMatchId = args['matchId']?.toString() ?? '';
    _scoringController.currentSessionId.value = _teamMatchId;
    _initialize();
  }

  @override
  void dispose() {
    _maxOversController.dispose();
    super.dispose();
  }

  int? _parsedMaxOvers() {
    final t = _maxOversController.text.trim();
    if (t.isEmpty) return null;
    final n = int.tryParse(t);
    if (n == null) return null;
    if (n < _minOvers || n > _maxOversLimit) return null;
    return n;
  }

  bool get _canSubmitStart =>
      _battingTeamId.isNotEmpty &&
      _fromTeamId.isNotEmpty &&
      _toTeamId.isNotEmpty &&
      _parsedMaxOvers() != null;

  void _applyTeamLabelsFromMatch(TeamMatchModel m) {
    _fromTeamId = m.fromTeamHelper.getId() ?? '';
    _toTeamId = m.toTeamHelper.getId() ?? '';
    _fromTeamName = m.fromTeamHelper.getDisplayName();
    _toTeamName = m.toTeamHelper.getDisplayName();
  }

  Future<void> _loadTeamMatchMeta() async {
    if (_teamMatchId.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoadingMeta = false;
        });
      }
      return;
    }
    final m = await _matchmakingService.getTeamMatchById(_teamMatchId);
    if (!mounted) return;
    if (m != null) {
      setState(() {
        _applyTeamLabelsFromMatch(m);
        _isLoadingMeta = false;
      });
    } else {
      setState(() {
        _isLoadingMeta = false;
      });
    }
  }

  String get _bowlingTeamIdResolved =>
      _battingTeamId == _fromTeamId ? _toTeamId : _fromTeamId;

  /// Any match team id for scoring API `actorTeamId` (must be on the fixture).
  String get _actorTeamId =>
      _fromTeamId.isNotEmpty ? _fromTeamId : _toTeamId;

  Future<void> _initialize() async {
    await Future.wait([
      _loadTeamMatchMeta(),
      _scoringController.fetchCricketMatch(_teamMatchId),
    ]);
    if (!mounted) return;
    final cm = _scoringController.cricketMatch.value;
    if (_fromTeamId.isEmpty && cm != null) {
      setState(() => _applyTeamLabelsFromMatch(cm));
    }
    if (_teamMatchId.isNotEmpty &&
        _scoringController.cricketMatch.value?.cricketState != null) {
      await _scoringController.fetchCricketOvers(_teamMatchId);
    }
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
      AppSnackbar.error(
        title: 'Update failed',
        message:
            _scoringController.errorMessage.value ?? 'Could not send event.',
      );
    }
  }

  Future<void> _undoLastBall() async {
    final ok = await _scoringController.undoLastCricketBall();
    if (!mounted || ok) return;
    AppSnackbar.error(
      title: 'Undo failed',
      message: _scoringController.errorMessage.value ?? 'Could not undo ball.',
    );
  }

  Future<void> _redoLastBall() async {
    final ok = await _scoringController.redoLastCricketBall();
    if (!mounted || ok) return;
    AppSnackbar.error(
      title: 'Redo failed',
      message: _scoringController.errorMessage.value ?? 'Could not redo ball.',
    );
  }

  Future<void> _startNextInning() async {
    final ok = await _scoringController.changeCricketInning();
    if (!mounted || ok) return;
    AppSnackbar.error(
      title: 'Could not start next innings',
      message:
          _scoringController.errorMessage.value ?? 'Could not change innings.',
    );
  }

  Widget _buildInningsCompletedFooter(CricketStateModel cs) {
    final hasNextInnings = cs.currentInnings < cs.inningsSummaries.length;
    final busy = _scoringController.isChangingCricketInning.value;
    final buttonLabel =
        hasNextInnings ? 'Start next innings' : 'End match';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(AppColors.dividerColor).withValues(alpha: 0.85),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 3,
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.flag_rounded,
                      size: 22,
                      color: const Color(AppColors.primaryColor)
                          .withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Innings completed',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(AppColors.textColor),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  hasNextInnings
                      ? 'Set the lineup for the next innings, then start scoring.'
                      : 'Confirm to finish the match.',
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    color: Color(AppColors.textSecondaryColor),
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: busy ? null : _startNextInning,
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCompletedFooter() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(AppColors.dividerColor).withValues(alpha: 0.85),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: const Row(
        children: [
          Icon(Icons.emoji_events_rounded, color: Color(AppColors.primaryColor)),
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
      ),
    );
  }

  Widget _buildScoringFooter(TeamMatchModel match) {
    final cs = match.cricketState!;
    if (match.status == TeamMatchStatus.completed) {
      return _buildMatchCompletedFooter();
    }

    final inningsComplete = isCricketInningsComplete(cs);
    if (inningsComplete) {
      return _buildInningsCompletedFooter(cs);
    }

    return CricketActionButtons(
      controller: _scoringController,
      onDot: () => _send(const DotOutcome()),
      onRun: _showRunPicker,
      onWide: _showWidePicker,
      onNoBall: _showNoBallPicker,
      onWicket: _showWicketFlow,
      onUndo: _undoLastBall,
      onRedo: _redoLastBall,
    );
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
                        child: Text('$i'),
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

  Future<void> _showRunPicker() async {
    final runs = await _pickRunsGrid(title: 'Runs off bat', min: 1, max: 6);
    if (!mounted || runs == null) return;
    await _send(RunsOutcome(offBat: runs));
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
    final candidates = playingXiForTeam(match, battingId)
        .where((p) {
          final id = p.userIdHelper.getId() ?? '';
          return id.isNotEmpty &&
              id != dismissedUserId &&
              !dismissed.contains(id);
        })
        .toList();
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
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
              for (final player in candidates)
                ListTile(
                  leading: CircleAvatar(
                    backgroundImage: player.avatar != null &&
                            player.avatar!.isNotEmpty
                        ? NetworkImage(player.avatar!)
                        : null,
                    child: player.avatar == null || player.avatar!.isEmpty
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(player.name),
                  onTap: () => Navigator.pop(ctx, player),
                ),
            ],
          ),
        ),
      ),
    );
    return picked?.userIdHelper.getId();
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
                  ),
                ),
              ),
              for (final player in candidates)
                ListTile(
                  leading: CircleAvatar(
                    backgroundImage: player.avatar != null &&
                            player.avatar!.isNotEmpty
                        ? NetworkImage(player.avatar!)
                        : null,
                    child: player.avatar == null || player.avatar!.isEmpty
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(player.name),
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
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 8),
              ListTile(
                title: const Text('Bowled'),
                onTap: () => Navigator.pop(ctx, _WicketUiKind.bowled),
              ),
              ListTile(
                title: const Text('Caught'),
                onTap: () => Navigator.pop(ctx, _WicketUiKind.caught),
              ),
              ListTile(
                title: const Text('LBW'),
                onTap: () => Navigator.pop(ctx, _WicketUiKind.lbw),
              ),
              ListTile(
                title: const Text('Run out'),
                onTap: () => Navigator.pop(ctx, _WicketUiKind.runOut),
              ),
              ListTile(
                title: const Text('Stumped'),
                onTap: () => Navigator.pop(ctx, _WicketUiKind.stumped),
              ),
              ListTile(
                title: const Text('Hit wicket'),
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
        final fielderId = fielder.userIdHelper.getId();
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
        final strikerName =
            announcedPlayerForUserId(match, strikerId)?.name ?? 'Striker';
        final nonName =
            announcedPlayerForUserId(match, nonStrikerId)?.name ??
                'Non-striker';
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
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                ListTile(
                  title: Text('Striker ($strikerName)'),
                  onTap: () => Navigator.pop(ctx, strikerId),
                ),
                ListTile(
                  title: Text('Non-striker ($nonName)'),
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
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                ListTile(
                  title: const Text('Skip'),
                  onTap: () => Navigator.pop(ctx, false),
                ),
                ListTile(
                  title: const Text('Pick fielder'),
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
          fielderId = f?.userIdHelper.getId();
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
        final keeperId = keeper.userIdHelper.getId();
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
    final overs = _parsedMaxOvers();
    if (_battingTeamId.isEmpty ||
        _bowlingTeamIdResolved.isEmpty ||
        _fromTeamId.isEmpty ||
        _toTeamId.isEmpty) {
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
        message: 'Enter overs per innings ($_minOvers–$_maxOversLimit).',
      );
      return;
    }

    await _scoringController.createCricketSession(
      CreateCricketSessionRequest(
        actorTeamId: _battingTeamId,
        battingTeamId: _battingTeamId,
        bowlingTeamId: _bowlingTeamIdResolved,
        maxOvers: overs,
      ),
    );
  }

  String _teamLabelForId(String teamId) {
    if (teamId.isEmpty) return '—';
    if (teamId == _fromTeamId) return _fromTeamName;
    if (teamId == _toTeamId) return _toTeamName;
    return 'Team';
  }

  void _retryFetchMatch() => _scoringController.fetchCricketMatch(_teamMatchId);

  @override
  Widget build(BuildContext context) {
    final titleMax =
        (MediaQuery.sizeOf(context).width - 120).clamp(72.0, 160.0) / 2;
    final leftTitle = _fromTeamName.isNotEmpty ? _fromTeamName : 'Loading…';
    final rightTitle = _toTeamName.isNotEmpty ? _toTeamName : 'Loading…';
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        titleSpacing: 8,
        title: VsAppBarTitle(
          leftName: leftTitle,
          rightName: rightTitle,
          maxNameWidth: titleMax,
        ),
      ),
      backgroundColor: const Color(AppColors.backgroundColor),
      body: Obx(() {
        final loadingMatch = _scoringController.isFetchingCricketMatch.value;
        final match = _scoringController.cricketMatch.value;
        final err = _scoringController.errorMessage.value;

        if (loadingMatch && match == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (match == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: MatchStatsErrorCard(
                message: (err != null && err.isNotEmpty)
                    ? err
                    : 'No match data loaded.',
                onRetry: _retryFetchMatch,
              ),
            ),
          );
        }

        if (match.cricketState == null) {
          final metaPending =
              _isLoadingMeta && _fromTeamId.isEmpty && _toTeamId.isEmpty;
          return CricketStartSessionPanel(
            metaPending: metaPending,
            fromTeamName: _fromTeamName,
            toTeamName: _toTeamName,
            fromTeamId: _fromTeamId,
            toTeamId: _toTeamId,
            battingTeamId: _battingTeamId,
            onBattingTeamIdChanged: (id) => setState(() => _battingTeamId = id),
            maxOversController: _maxOversController,
            onMaxOversChanged: () => setState(() {}),
            minOvers: _minOvers,
            maxOversLimit: _maxOversLimit,
            isStarting: _scoringController.isCreatingCricketSession.value,
            canStart: _canSubmitStart,
            errorText: err,
            onStart: _startCricketSession,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                children: [
                  CricketMatchStatsPanel(
                    controller: _scoringController,
                    teamLabelForId: _teamLabelForId,
                    onRetry: _retryFetchMatch,
                  ),
                  const SizedBox(height: 10),
                  CricketLineupCard(
                    controller: _scoringController,
                    actorTeamId: _actorTeamId,
                  ),
                  const SizedBox(height: 10),
                  CricketOversTable(controller: _scoringController),
                ],
              ),
            ),
            Material(
              elevation: 10,
              shadowColor: Colors.black26,
              color: const Color(AppColors.backgroundColor),
              child: SafeArea(
                top: false,
                minimum: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: _buildScoringFooter(match),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
