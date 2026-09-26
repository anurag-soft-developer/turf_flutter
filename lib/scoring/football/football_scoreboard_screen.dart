import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../components/scoring/cricket/match_stats_error_card.dart';
import '../../components/scoring/cricket/vs_app_bar_title.dart';
import '../../components/scoring/football/football_components.dart';
import '../../components/scoring/football/football_event_player_sheet.dart';
import '../../core/components/app_bar/app_bar_background.dart';
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
import 'util/football_scoring_helpers.dart';

class FootballScoreboardScreen extends StatefulWidget {
  const FootballScoreboardScreen({super.key});

  @override
  State<FootballScoreboardScreen> createState() =>
      _FootballScoreboardScreenState();
}

class _FootballScoreboardScreenState extends State<FootballScoreboardScreen> {
  late final FootballScoringController _controller;

  late final String _teamMatchId;

  final TextEditingController _matchMinuteController =
      TextEditingController(text: '90');

  static const int _minMatchMinutes = 2;
  static const int _maxMatchMinutes = 90;

  bool _eventFlowInProgress = false;

  /// API failures already toast from [ApiService]. Snackbar only for local checks.
  void _showLocalError(String title) {
    final message = _controller.errorMessage.value;
    if (message == null || message.isEmpty) return;
    AppSnackbar.error(title: title, message: message);
  }

  @override
  void initState() {
    super.initState();
    _controller = Get.find<FootballScoringController>();
    final args = (Get.arguments as Map?)?.cast<String, dynamic>() ?? const {};
    _teamMatchId = args['matchId']?.toString() ?? '';
    _controller.currentSessionId.value = _teamMatchId;
    if (_teamMatchId.isNotEmpty) {
      unawaited(_controller.joinLiveSession(_teamMatchId));
    }
  }

  @override
  void dispose() {
    unawaited(_controller.leaveLiveSession());
    _matchMinuteController.dispose();
    super.dispose();
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

  Future<void> _onEventTap(
    FootballEventKind kind, {
    required BuildContext modalContext,
  }) async {
    if (_eventFlowInProgress) return;
    final match = _controller.footballMatch.value;
    if (match == null) return;

    _eventFlowInProgress = true;
    final payload = await FootballEventPlayerSheet.show(
      context: modalContext,
      kind: kind,
      match: match,
      fromTeamId: _controller.fromTeamId,
      toTeamId: _controller.toTeamId,
      teamLabelForId: _controller.teamLabelForId,
    );
    try {
      if (!mounted || payload == null) return;

      final event = await _controller.appendFootballEvent(
        AppendFootballEventRequest(payload: payload),
      );
      if (!mounted) return;
      if (event == null) _showLocalError('Update failed');
    } finally {
      _eventFlowInProgress = false;
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
      _showLocalError('Could not start');
    }
  }

  Future<void> _undo() async {
    final ok = await _controller.undoLastFootballEvent();
    if (!mounted || ok) return;
    _showLocalError('Undo failed');
  }

  Future<void> _redo() async {
    final ok = await _controller.redoLastFootballEvent();
    if (!mounted || ok) return;
    _showLocalError('Redo failed');
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
    _showLocalError('Could not change innings');
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
    _showLocalError('Could not end match');
  }

  Future<void> _onPeriodFooterAction(FootballStateModel fs) async {
    final hasNextInning = fs.currentInnings < fs.inningsSummaries.length;
    if (hasNextInning && shouldShowFootballStartNextInning(fs)) {
      await _changeInning();
    } else {
      await _completeMatch();
    }
  }

  Widget? _buildStatusFooter(TeamMatchModel match) {
    final fs = match.footballState;
    if (fs == null) return null;

    if (match.status == TeamMatchStatus.completed ||
        match.status == TeamMatchStatus.draw) {
      return _buildMatchCompletedFooter();
    }

    if (shouldShowFootballStartNextInning(fs)) {
      return _buildPeriodTransitionFooter(fs);
    }

    if (shouldShowFootballEndMatchFooter(fs)) {
      return _buildPeriodTransitionFooter(fs);
    }

    return null;
  }

  Widget _buildPeriodTransitionFooter(FootballStateModel fs) {
    final hasNextInning = fs.currentInnings < fs.inningsSummaries.length;
    final busy = hasNextInning
        ? _controller.isChangingInning.value
        : _controller.isCompletingFootballMatch.value;
    final buttonLabel =
        hasNextInning ? 'Start next innings' : 'End match';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Period complete',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Color(AppColors.textColor),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          hasNextInning
              ? 'Start the next period when both teams are ready.'
              : 'Confirm to finish the match.',
          style: const TextStyle(
            fontSize: 13,
            height: 1.35,
            color: Color(AppColors.textSecondaryColor),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: busy ? null : () => _onPeriodFooterAction(fs),
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

  void _openScoringSheet() {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: false,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
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
                          'Record event',
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
                  child: FootballActionButtons(
                    controller: _controller,
                    onEventTap: (kind) {
                      unawaited(_onEventTap(kind, modalContext: ctx));
                    },
                    onUndo: _undo,
                    onRedo: _redo,
                    onComplete: _completeMatch,
                    onChangeInning: _changeInning,
                    showPeriodActions: false,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openEventsSheet() {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: false,
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
                          'Events',
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
                    child: FootballEventsTimeline(controller: _controller),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        centerTitle: true,
        titleSpacing: 8,
        title: Obx(() {
          final match = _controller.footballMatch.value;
          if (match == null || match.footballState == null) {
            return const Text('Start match');
          }
          final leftLogo = match.fromTeamHelper.getSubsetModel()?.logo;
          final rightLogo = match.toTeamHelper.getSubsetModel()?.logo;
          return VsAppBarTitle(
            leftName: _controller.fromTeamName.isNotEmpty
                ? _controller.fromTeamName
                : '?',
            rightName: _controller.toTeamName.isNotEmpty
                ? _controller.toTeamName
                : '?',
            leftLogoUrl: leftLogo,
            rightLogoUrl: rightLogo,
          );
        }),
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
            final fs = sessionQuery.data?.footballState;
            if (fs?.matchMinute != null &&
                _matchMinuteController.text.isEmpty) {
              _matchMinuteController.text = '${fs!.matchMinute}';
            }
            return null;
          }, [sessionQuery.data]);

          useEffect(() {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _controller.seedFromQuery(
                match: sessionQuery.data ?? metaQuery.data,
                events: eventsQuery.data,
              );
            });
            return null;
          }, [sessionQuery.data, metaQuery.data, eventsQuery.data]);

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

          final queryMatch = metaQuery.data ?? sessionQuery.data;
          final metaPending = (metaQuery.isLoading ||
                  (metaQuery.isFetching && metaQuery.data == null)) &&
              queryMatch == null;

          return Obx(() {
            final live = _controller.footballMatch.value;
            final err = _controller.errorMessage.value;
            final hasLiveState = live?.footballState != null;

            if (hasLiveState) {
              final match = live!;
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
                          FootballMatchStatsPanel(
                            controller: _controller,
                            fromTeamName: _controller.fromTeamName,
                            toTeamName: _controller.toTeamName,
                            onRetry: retryColdLoad,
                          ),
                          const SizedBox(height: 24),
                          FootballMatchTimer(
                            controller: _controller,
                            enabled: canScore,
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
                  ScoreboardFabShell(
                    onOpenControls: _openScoringSheet,
                    onOpenSecondary: _openEventsSheet,
                    secondaryTooltip: 'Events',
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

            if (startMatch.footballState == null) {
              return FootballStartSessionPanel(
                metaPending: false,
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

            return const SizedBox.shrink();
          });
        },
      ),
    );
  }
}
