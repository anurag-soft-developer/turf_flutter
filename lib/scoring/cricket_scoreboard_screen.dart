import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../components/scoring/cricket/cricket_components.dart';
import '../core/config/constants.dart';
import '../core/utils/app_snackbar.dart';
import '../match_up/matchmaking_service.dart';
import '../match_up/model/team_match_model.dart';
import '../team/members/model/team_member_model.dart';
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

  final List<TeamMemberModel> _fromTeamPlayers = const [];
  final List<TeamMemberModel> _toTeamPlayers = const [];

  /// Empty until the user picks who bats first (start-only flow).
  String _battingTeamId = '';
  TeamMemberModel? _striker;
  TeamMemberModel? _nonStriker;
  TeamMemberModel? _bowler;

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

  List<TeamMemberModel> get _battingPlayers =>
      _battingTeamId == _fromTeamId ? _fromTeamPlayers : _toTeamPlayers;
  List<TeamMemberModel> get _bowlingPlayers =>
      _battingTeamId == _fromTeamId ? _toTeamPlayers : _fromTeamPlayers;

  String get _bowlingTeamIdResolved =>
      _battingTeamId == _fromTeamId ? _toTeamId : _fromTeamId;

  // bool get _rosterReady {
  //   final s = _striker?.userHelper.getId() ?? '';
  //   final n = _nonStriker?.userHelper.getId() ?? '';
  //   final b = _bowler?.userHelper.getId() ?? '';
  //   return s.isNotEmpty && n.isNotEmpty && b.isNotEmpty;
  // }

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
    final strikerId = _striker?.userHelper.getId() ?? '';
    final nonStrikerId = _nonStriker?.userHelper.getId() ?? '';
    final bowlerId = _bowler?.userHelper.getId() ?? '';
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
    final candidates = _battingPlayers
        .where((p) => p.userHelper.getId() != dismissedUserId)
        .toList();
    if (candidates.isEmpty) {
      AppSnackbar.info(
        title: 'No substitute',
        message: 'No other batsman available on roster.',
      );
      return null;
    }
    final picked = await showModalBottomSheet<TeamMemberModel>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: candidates.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  'Incoming batsman',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              );
            }
            final player = candidates[index - 1];
            return ListTile(
              title: Text(player.userHelper.getDisplayName()),
              onTap: () => Navigator.pop(ctx, player),
            );
          },
        ),
      ),
    );
    return picked?.userHelper.getId();
  }

  Future<void> _sendDismissal(
    CricketOutcome outcome, {
    required String dismissedUserId,
  }) async {
    final incoming = await _pickIncomingBatsman(dismissedUserId);
    if (!mounted || incoming == null) return;
    await _send(outcome, incomingBatsmanUserId: incoming);
  }

  Future<TeamMemberModel?> _pickBowlingPlayer(String title) async {
    if (_bowlingPlayers.isEmpty) {
      AppSnackbar.info(
        title: 'No fielders',
        message: 'Bowling side roster is empty.',
      );
      return null;
    }
    return showModalBottomSheet<TeamMemberModel>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _bowlingPlayers.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              );
            }
            final player = _bowlingPlayers[index - 1];
            return ListTile(
              title: Text(player.userHelper.getDisplayName()),
              onTap: () => Navigator.pop(ctx, player),
            );
          },
        ),
      ),
    );
  }

  Future<void> _showWicketFlow() async {
    final strikerId = _striker?.userHelper.getId() ?? '';
    final nonStrikerId = _nonStriker?.userHelper.getId() ?? '';
    if (strikerId.isEmpty || nonStrikerId.isEmpty) {
      AppSnackbar.info(
        title: 'Select players',
        message: 'Set striker and non-striker first.',
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
        final fielder = await _pickBowlingPlayer('Fielder (catcher)');
        if (!mounted || fielder == null) return;
        final fielderId = fielder.userHelper.getId();
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
                  title: Text(
                    'Striker (${_striker?.userHelper.getDisplayName() ?? '—'})',
                  ),
                  onTap: () => Navigator.pop(ctx, strikerId),
                ),
                ListTile(
                  title: Text(
                    'Non-striker (${_nonStriker?.userHelper.getDisplayName() ?? '—'})',
                  ),
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
          final f = await _pickBowlingPlayer('Throwing fielder');
          if (!mounted) return;
          fielderId = f?.userHelper.getId();
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
        final keeper = await _pickBowlingPlayer('Wicket-keeper');
        if (!mounted || keeper == null) return;
        final keeperId = keeper.userHelper.getId();
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
          if (metaPending) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Who bats first?',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(AppColors.textColor),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Bowling is set to the other team automatically.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(AppColors.textSecondaryColor),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          ChoiceChip(
                            label: Text(
                              _fromTeamName.isNotEmpty
                                  ? _fromTeamName
                                  : 'Team 1',
                            ),
                            selected:
                                _battingTeamId.isNotEmpty &&
                                _battingTeamId == _fromTeamId,
                            onSelected: _fromTeamId.isEmpty
                                ? null
                                : (v) {
                                    if (!v) return;
                                    setState(
                                      () => _battingTeamId = _fromTeamId,
                                    );
                                  },
                          ),
                          ChoiceChip(
                            label: Text(
                              _toTeamName.isNotEmpty ? _toTeamName : 'Team 2',
                            ),
                            selected:
                                _battingTeamId.isNotEmpty &&
                                _battingTeamId == _toTeamId,
                            onSelected: _toTeamId.isEmpty
                                ? null
                                : (v) {
                                    if (!v) return;
                                    setState(() => _battingTeamId = _toTeamId);
                                  },
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Overs (per innings)',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(AppColors.textColor),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _maxOversController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'e.g. 20',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(AppColors.primaryColor),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Between $_minOvers and $_maxOversLimit overs.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(AppColors.textSecondaryColor),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              CricketStartOnlyBody(
                isStarting: _scoringController.isCreatingCricketSession.value,
                canStart: _canSubmitStart,
                errorText: err,
                onStart: _startCricketSession,
              ),
            ],
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
                  // CricketPlayerSelector(
                  //   striker: _striker,
                  //   nonStriker: _nonStriker,
                  //   bowler: _bowler,
                  //   onTapStriker: () => _pickPlayer(
                  //     'Select Striker',
                  //     _battingPlayers,
                  //     _striker,
                  //     (p) => _striker = p,
                  //   ),
                  //   onTapNonStriker: () => _pickPlayer(
                  //     'Select Non-striker',
                  //     _battingPlayers,
                  //     _nonStriker,
                  //     (p) => _nonStriker = p,
                  //   ),
                  //   onTapBowler: () => _pickPlayer(
                  //     'Select Bowler',
                  //     _bowlingPlayers,
                  //     _bowler,
                  //     (p) => _bowler = p,
                  //   ),
                  // ),
                  // const SizedBox(height: 10),
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
                  child: CricketActionButtons(
                    controller: _scoringController,
                    onDot: () => _send(const DotOutcome()),
                    onRun: _showRunPicker,
                    onWide: _showWidePicker,
                    onNoBall: _showNoBallPicker,
                    onWicket: _showWicketFlow,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
