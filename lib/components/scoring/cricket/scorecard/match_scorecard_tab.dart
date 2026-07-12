import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';

import '../../../../components/shared/app_segmented_tabs/app_segmented_tabs.dart';
import '../../../../core/config/constants.dart';
import '../../../../core/query/query_keys.dart';
import '../../../../match_up/model/team_match_model.dart';
import '../../../../scoring/cricket/cricket_scoring_api_service.dart';
import '../../../../scoring/cricket/model/cricket_ball_event_model.dart';
import '../../../../scoring/football/football_scoring_api_service.dart';
import '../../../../scoring/football/model/football_match_event_model.dart';
import '../../../../scoring/football/widgets/football_scorecard.dart';
import '../../../../team/model/team_model.dart';
import 'cricket_scorecard.dart';

Duration? _noRetry(int count, Object error) => null;

class MatchScorecardTab extends HookWidget {
  const MatchScorecardTab({
    super.key,
    required this.match,
    this.parentTabController,
  });

  final TeamMatchModel match;
  final TabController? parentTabController;

  @override
  Widget build(BuildContext context) {
    final matchId = match.id ?? '';
    final isCricket = match.sportType == TeamSportType.cricket;
    final isFootball = match.sportType == TeamSportType.football;
    final supported = isCricket || isFootball;
    final hasMatchId = matchId.isNotEmpty;

    final cricketApi = useMemoized(() => CricketScoringApiService());
    final footballApi = useMemoized(() => FootballScoringApiService());

    final cricketSessionQuery = useQuery<TeamMatchModel, Object>(
      QueryKeys.cricketSession(matchId),
      (_) async {
        final loaded = await cricketApi.getCricketSession(matchId);
        if (loaded == null) throw Exception('Could not load scorecard.');
        return loaded;
      },
      enabled: supported && isCricket && hasMatchId,
      retry: _noRetry,
    );

    final cricketOversQuery = useQuery<List<CricketOverEvent>, Object>(
      QueryKeys.cricketOvers(matchId),
      (_) async {
        final overs = await cricketApi.listCricketOvers(teamMatchId: matchId);
        return List<CricketOverEvent>.from(overs)
          ..sort((a, b) => a.sequence.compareTo(b.sequence));
      },
      enabled: supported &&
          isCricket &&
          hasMatchId &&
          cricketSessionQuery.data?.cricketState != null,
      retry: _noRetry,
    );

    final footballSessionQuery = useQuery<TeamMatchModel, Object>(
      QueryKeys.footballSession(matchId),
      (_) async {
        final loaded = await footballApi.getFootballSession(matchId);
        if (loaded == null) throw Exception('Could not load scorecard.');
        return loaded;
      },
      enabled: supported && isFootball && hasMatchId,
      retry: _noRetry,
    );

    final footballEventsQuery = useQuery<List<FootballMatchEvent>, Object>(
      QueryKeys.footballEvents(matchId),
      (_) async {
        final events =
            await footballApi.listFootballEvents(teamMatchId: matchId);
        return List<FootballMatchEvent>.from(events)
          ..sort((a, b) => a.sequence.compareTo(b.sequence));
      },
      enabled: supported &&
          isFootball &&
          hasMatchId &&
          footballSessionQuery.data?.footballState != null,
      retry: _noRetry,
    );

    if (!supported) {
      return _wrapParentSwipe(const _SportPlaceholder());
    }

    if (!hasMatchId) {
      return _wrapParentSwipe(
        _ErrorState(
          message: 'Missing match id.',
          onRetry: () {},
        ),
      );
    }

    if (isFootball) {
      final session = footballSessionQuery.data ?? match;
      final sessionError = footballSessionQuery.isError &&
          footballSessionQuery.data == null;
      final eventsError = footballEventsQuery.isError &&
          footballSessionQuery.data?.footballState != null &&
          footballEventsQuery.data == null;
      final loading = footballSessionQuery.isLoading ||
          (footballSessionQuery.isFetching &&
              footballSessionQuery.data == null) ||
          (footballSessionQuery.data?.footballState != null &&
              (footballEventsQuery.isLoading ||
                  (footballEventsQuery.isFetching &&
                      footballEventsQuery.data == null)));

      if ((sessionError || eventsError) && session.footballState == null) {
        return _wrapParentSwipe(
          _ErrorState(
            message: (footballSessionQuery.error ?? footballEventsQuery.error)
                    ?.toString() ??
                'Could not load scorecard.',
            onRetry: () {
              footballSessionQuery.refetch();
              footballEventsQuery.refetch();
            },
          ),
        );
      }

      return FootballScorecard(
        match: session,
        events: footballEventsQuery.data ?? const [],
        parentTabController: parentTabController,
        isLoading: loading,
        onRetry: () {
          footballSessionQuery.refetch();
          footballEventsQuery.refetch();
        },
      );
    }

    final session = cricketSessionQuery.data ?? match;
    final sessionError =
        cricketSessionQuery.isError && cricketSessionQuery.data == null;
    final oversError = cricketOversQuery.isError &&
        cricketSessionQuery.data?.cricketState != null &&
        cricketOversQuery.data == null;
    final loading = cricketSessionQuery.isLoading ||
        (cricketSessionQuery.isFetching && cricketSessionQuery.data == null) ||
        (cricketSessionQuery.data?.cricketState != null &&
            (cricketOversQuery.isLoading ||
                (cricketOversQuery.isFetching &&
                    cricketOversQuery.data == null)));

    if ((sessionError || oversError) && session.cricketState == null) {
      return _wrapParentSwipe(
        _ErrorState(
          message: (cricketSessionQuery.error ?? cricketOversQuery.error)
                  ?.toString() ??
              'Could not load scorecard.',
          onRetry: () {
            cricketSessionQuery.refetch();
            cricketOversQuery.refetch();
          },
        ),
      );
    }

    return CricketScorecard(
      match: session,
      overs: cricketOversQuery.data ?? const [],
      parentTabController: parentTabController,
      isLoading: loading,
      onRetry: () {
        cricketSessionQuery.refetch();
        cricketOversQuery.refetch();
      },
    );
  }

  Widget _wrapParentSwipe(Widget child) {
    final parent = parentTabController;
    if (parent == null) return child;
    return ParentLinkedHorizontalSwipe(
      parentController: parent,
      child: child,
    );
  }
}

class _SportPlaceholder extends StatelessWidget {
  const _SportPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(AppColors.surfaceColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text(
        'coming soon for this sport',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(AppColors.textSecondaryColor),
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(AppColors.surfaceColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            message,
            style: const TextStyle(
              color: Color(AppColors.textSecondaryColor),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
