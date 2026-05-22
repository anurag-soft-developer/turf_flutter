import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../components/scoring/cricket/match_stats_error_card.dart';
import '../../components/scoring/cricket/vs_app_bar_title.dart';
import '../../core/config/constants.dart';
import '../../core/utils/app_snackbar.dart';
import '../../match_up/matchmaking_service.dart';
import '../../match_up/model/team_match_model.dart';
import 'football_scoring_controller.dart';
import 'model/football_match_event_model.dart';
import 'model/football_scoring_models.dart';
import 'widgets/football_components.dart';
import 'widgets/football_event_player_sheet.dart';

class FootballScoreboardScreen extends StatefulWidget {
  const FootballScoreboardScreen({super.key});

  @override
  State<FootballScoreboardScreen> createState() =>
      _FootballScoreboardScreenState();
}

class _FootballScoreboardScreenState extends State<FootballScoreboardScreen> {
  late final FootballScoringController _controller;
  final MatchmakingService _matchmakingService = MatchmakingService();

  late final String _teamMatchId;
  String _fromTeamName = '';
  String _toTeamName = '';
  String _fromTeamId = '';
  String _toTeamId = '';
  bool _isLoadingMeta = true;

  MatchFootballPeriod _selectedPeriod = MatchFootballPeriod.firstHalf;
  final TextEditingController _matchMinuteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = Get.find<FootballScoringController>();
    final args = (Get.arguments as Map?)?.cast<String, dynamic>() ?? const {};
    _teamMatchId = args['matchId']?.toString() ?? '';
    _controller.currentSessionId.value = _teamMatchId;
    _initialize();
  }

  @override
  void dispose() {
    _matchMinuteController.dispose();
    super.dispose();
  }

  void _applyTeamLabelsFromMatch(TeamMatchModel m) {
    _fromTeamId = m.fromTeamHelper.getId() ?? '';
    _toTeamId = m.toTeamHelper.getId() ?? '';
    _fromTeamName = m.fromTeamHelper.getDisplayName();
    _toTeamName = m.toTeamHelper.getDisplayName();
  }

  Future<void> _loadTeamMatchMeta() async {
    if (_teamMatchId.isEmpty) {
      if (mounted) setState(() => _isLoadingMeta = false);
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
      setState(() => _isLoadingMeta = false);
    }
  }

  Future<void> _initialize() async {
    await Future.wait([
      _loadTeamMatchMeta(),
      _controller.fetchFootballMatch(_teamMatchId),
    ]);
    if (!mounted) return;
    final fm = _controller.footballMatch.value;
    if (_fromTeamId.isEmpty && fm != null) {
      setState(() => _applyTeamLabelsFromMatch(fm));
    }
    final fs = fm?.footballState;
    if (fs != null) {
      _selectedPeriod = fs.currentPeriod;
      if (fs.matchMinute != null) {
        _matchMinuteController.text = '${fs.matchMinute}';
      }
    }
    if (_teamMatchId.isNotEmpty && fs != null) {
      await _controller.fetchFootballEvents(_teamMatchId);
    }
  }

  int? _parsedMatchMinute() {
    final t = _matchMinuteController.text.trim();
    if (t.isEmpty) return null;
    final n = int.tryParse(t);
    if (n == null || n < 0 || n > 130) return null;
    return n;
  }

  AppendFootballEventRequest _buildEventRequest(FootballEventPayload payload) {
    return AppendFootballEventRequest(
      period: _selectedPeriod,
      matchMinute: _parsedMatchMinute(),
      payload: payload,
    );
  }

  Future<void> _onEventTap(FootballEventKind kind) async {
    final match = _controller.footballMatch.value;
    if (match == null) return;

    final payload = await FootballEventPlayerSheet.show(
      context: context,
      kind: kind,
      match: match,
      fromTeamId: _fromTeamId,
      toTeamId: _toTeamId,
      teamLabelForId: _teamLabelForId,
    );
    if (!mounted || payload == null) return;

    final event = await _controller.appendFootballEvent(
      _buildEventRequest(payload),
    );
    if (!mounted) return;
    if (event == null) {
      AppSnackbar.error(
        title: 'Update failed',
        message: _controller.errorMessage.value ?? 'Could not record event.',
      );
    }
  }

  Future<void> _startFootballSession() async {
    final minute = _parsedMatchMinute();
    await _controller.createFootballSession(
      CreateFootballSessionRequest(
        period: _selectedPeriod,
        matchMinute: minute,
      ),
    );
    if (!mounted) return;
    if (_controller.footballMatch.value?.footballState == null) {
      AppSnackbar.error(
        title: 'Could not start',
        message:
            _controller.errorMessage.value ?? 'Could not start football session.',
      );
    }
  }

  Future<void> _undo() async {
    final ok = await _controller.undoLastFootballEvent();
    if (!mounted || ok) return;
    AppSnackbar.error(
      title: 'Undo failed',
      message: _controller.errorMessage.value ?? 'Could not undo event.',
    );
  }

  Future<void> _redo() async {
    final ok = await _controller.redoLastFootballEvent();
    if (!mounted || ok) return;
    AppSnackbar.error(
      title: 'Redo failed',
      message: _controller.errorMessage.value ?? 'Could not redo event.',
    );
  }

  Future<void> _completeMatch() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End match?'),
        content: const Text(
          'This will finalize the score and apply ranking points.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('End match'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final ok = await _controller.completeFootballMatch();
    if (!mounted || ok) return;
    AppSnackbar.error(
      title: 'Could not end match',
      message: _controller.errorMessage.value ?? 'Could not complete match.',
    );
  }

  String _teamLabelForId(String teamId) {
    if (teamId.isEmpty) return '—';
    if (teamId == _fromTeamId) return _fromTeamName;
    if (teamId == _toTeamId) return _toTeamName;
    return 'Team';
  }

  void _retryFetchMatch() => _controller.fetchFootballMatch(_teamMatchId);

  Widget _buildPeriodToolbar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(AppColors.dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Current period & minute',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<MatchFootballPeriod>(
            value: _selectedPeriod,
            decoration: InputDecoration(
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            items: MatchFootballPeriod.values
                .map(
                  (p) => DropdownMenuItem(
                    value: p,
                    child: Text(periodLabel(p)),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _selectedPeriod = v);
            },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _matchMinuteController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              isDense: true,
              labelText: 'Minute (optional)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

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
        final loadingMatch = _controller.isFetchingFootballMatch.value;
        final match = _controller.footballMatch.value;
        final err = _controller.errorMessage.value;

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

        if (match.footballState == null) {
          final metaPending =
              _isLoadingMeta && _fromTeamId.isEmpty && _toTeamId.isEmpty;
          return FootballStartSessionPanel(
            metaPending: metaPending,
            fromTeamName: _fromTeamName,
            toTeamName: _toTeamName,
            selectedPeriod: _selectedPeriod,
            onPeriodChanged: (p) => setState(() => _selectedPeriod = p),
            matchMinuteController: _matchMinuteController,
            isStarting: _controller.isCreatingFootballSession.value,
            errorText: err,
            onStart: _startFootballSession,
          );
        }

        final completed = match.status == TeamMatchStatus.completed ||
            match.status == TeamMatchStatus.draw;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                children: [
                  FootballMatchStatsPanel(
                    controller: _controller,
                    fromTeamName: _fromTeamName,
                    toTeamName: _toTeamName,
                    onRetry: _retryFetchMatch,
                  ),
                  const SizedBox(height: 10),
                  if (!completed) ...[
                    _buildPeriodToolbar(),
                    const SizedBox(height: 10),
                  ],
                  FootballEventsTimeline(controller: _controller),
                ],
              ),
            ),
            if (!completed)
              Material(
                elevation: 10,
                shadowColor: Colors.black26,
                color: const Color(AppColors.backgroundColor),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    child: FootballActionButtons(
                      controller: _controller,
                      onEventTap: _onEventTap,
                      onUndo: _undo,
                      onRedo: _redo,
                      onComplete: _completeMatch,
                    ),
                  ),
                ),
              )
            else
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.emoji_events_rounded,
                          color: Color(AppColors.primaryColor),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Match completed',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
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
