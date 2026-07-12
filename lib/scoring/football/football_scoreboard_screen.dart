import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../components/scoring/cricket/match_stats_error_card.dart';
import '../../components/scoring/cricket/vs_app_bar_title.dart';
import '../../core/config/constants.dart';
import '../../core/query/query_keys.dart';
import '../../core/query/query_retry.dart';
import '../../core/utils/app_snackbar.dart';
import '../../match_up/matchmaking_service.dart';
import '../../match_up/model/team_match_model.dart';
import 'football_scoring_api_service.dart';
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

  late final String _teamMatchId;
  String _fromTeamName = '';
  String _toTeamName = '';
  String _fromTeamId = '';
  String _toTeamId = '';

  final TextEditingController _matchMinuteController =
      TextEditingController(text: '90');

  static const int _minMatchMinutes = 5;
  static const int _maxMatchMinutes = 90;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<FootballScoringController>();
    final args = (Get.arguments as Map?)?.cast<String, dynamic>() ?? const {};
    _teamMatchId = args['matchId']?.toString() ?? '';
    _controller.currentSessionId.value = _teamMatchId;
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

  int? _parsedMatchMinute() {
    final t = _matchMinuteController.text.trim();
    if (t.isEmpty) return null;
    final n = int.tryParse(t);
    if (n == null || n < _minMatchMinutes || n > _maxMatchMinutes) {
      return null;
    }
    return n;
  }

  bool get _canStartSession => _parsedMatchMinute() != null;

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
      AppendFootballEventRequest(payload: payload),
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
    if (minute == null) {
      AppSnackbar.info(
        title: 'Match length',
        message:
            'Enter total minutes between $_minMatchMinutes and $_maxMatchMinutes.',
      );
      return;
    }
    await _controller.createFootballSession(
      CreateFootballSessionRequest(matchMinute: minute),
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

  Future<void> _changeInning() async {
    final fs = _controller.footballMatch.value?.footballState;
    if (fs == null) return;

    MatchFootballPeriod? nextPeriod;
    if (fs.currentInnings < fs.inningsSummaries.length) {
      nextPeriod = switch (fs.currentInnings + 1) {
        2 => MatchFootballPeriod.secondHalf,
        3 => MatchFootballPeriod.extraFirst,
        4 => MatchFootballPeriod.extraSecond,
        _ => MatchFootballPeriod.penalties,
      };
    }

    final ok = await _controller.changeFootballInning(
      ChangeFootballInningRequest(period: nextPeriod),
    );
    if (!mounted || ok) return;
    AppSnackbar.error(
      title: 'Could not change innings',
      message: _controller.errorMessage.value ?? 'Could not start next innings.',
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
      body: HookBuilder(
        builder: (context) {
          final hasMatchId = _teamMatchId.isNotEmpty;
          final footballApi = useMemoized(() => FootballScoringApiService());
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
            QueryKeys.footballSession(_teamMatchId),
            (_) async {
              final loaded =
                  await footballApi.getFootballSession(_teamMatchId);
              if (loaded == null) {
                throw Exception('Could not load match.');
              }
              return loaded;
            },
            enabled: hasMatchId,
            retry: noRetry,
          );

          final sessionHasState =
              sessionQuery.data?.footballState != null;
          final eventsQuery = useQuery<List<FootballMatchEvent>, Object>(
            QueryKeys.footballEvents(_teamMatchId),
            (_) async {
              final events = await footballApi.listFootballEvents(
                teamMatchId: _teamMatchId,
              );
              return List<FootballMatchEvent>.from(events)
                ..sort((a, b) => a.sequence.compareTo(b.sequence));
            },
            enabled: hasMatchId && sessionHasState,
            retry: noRetry,
          );

          useEffect(() {
            final m = metaQuery.data ?? sessionQuery.data;
            if (m == null) return null;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() => _applyTeamLabelsFromMatch(m));
            });
            return null;
          }, [metaQuery.data, sessionQuery.data]);

          useEffect(() {
            final fs = sessionQuery.data?.footballState;
            if (fs?.matchMinute != null &&
                _matchMinuteController.text.isEmpty) {
              _matchMinuteController.text = '${fs!.matchMinute}';
            }
            return null;
          }, [sessionQuery.data]);

          useEffect(() {
            _controller.seedFromQuery(
              match: sessionQuery.data,
              events: eventsQuery.data,
            );
            return null;
          }, [sessionQuery.data, eventsQuery.data]);

          void retryColdLoad() {
            metaQuery.refetch();
            sessionQuery.refetch();
            if (sessionHasState) eventsQuery.refetch();
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
                  (eventsQuery.isLoading ||
                      (eventsQuery.isFetching && eventsQuery.data == null)));

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

          final metaPending = (metaQuery.isLoading ||
                  (metaQuery.isFetching && metaQuery.data == null)) &&
              _fromTeamId.isEmpty &&
              _toTeamId.isEmpty;

          return Obx(() {
            final match = _controller.footballMatch.value;
            final err = _controller.errorMessage.value;

            if (match == null) {
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

            if (match.footballState == null) {
              return FootballStartSessionPanel(
                metaPending: metaPending,
                matchMinuteController: _matchMinuteController,
                isStarting: _controller.isCreatingFootballSession.value,
                canStart: _canStartSession,
                errorText: err,
                onStart: _startFootballSession,
                onMinuteChanged: () => setState(() {}),
                minMinutes: _minMatchMinutes,
                maxMinutes: _maxMatchMinutes,
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
                        onRetry: retryColdLoad,
                      ),
                      const SizedBox(height: 10),
                      FootballMatchTimer(
                        controller: _controller,
                        enabled: !completed,
                      ),
                      const SizedBox(height: 10),
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
                          onChangeInning: _changeInning,
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
          });
        },
      ),
    );
  }
}
