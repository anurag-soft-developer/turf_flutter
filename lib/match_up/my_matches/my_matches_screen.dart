import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../components/my_matches/my_matches_sub_filters.dart';
import '../../components/match_history/match_card.dart';
import '../../components/match_history/match_history_placeholders.dart';
import '../../components/shared/app_segmented_tabs/app_segmented_tabs.dart';
import '../../core/models/paginated_response.dart';
import '../../core/query/query_keys.dart';
import '../match_challenges/match_challenge_detail_screen.dart';
import '../matchmaking_service.dart';
import '../../team/model/team_model.dart';
import '../model/team_match_model.dart';
import '../shared/match_infinite_query_pane.dart';
import '../shared/match_list_scaffold.dart';
import 'my_matches_controller.dart';

class MyMatchesScreen extends StatelessWidget {
  const MyMatchesScreen({super.key});

  static const _tabs = [
    AppTabItem(label: 'All'),
    AppTabItem(label: 'Live'),
    AppTabItem(label: 'Upcoming'),
    AppTabItem(label: 'Others'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = Get.find<MyMatchesController>();

    return MatchListScaffold(
      title: 'Matches',
      teamSheetTitle: 'Show matches for',
      emptyTeamsMessage: 'Join or create a team to see your matches.',
      allowEmptyMemberships: true,
      controller: c,
      tabs: _tabs,
      initialTabIndex: c.selectedTab.value.index,
      onTabChanged: c.switchTab,
      belowTabs: const MyMatchesSubFilters(),
      buildPanes: (filterKey) {
        final type = c.typeFilter.value;
        final sport = c.sportFilter.value;
        return [
          for (final tab in MyMatchesTab.values)
            _MyMatchesPane(
              key: ValueKey(
                '${tab.name}|$filterKey|${type.name}|${sport?.name ?? 'all'}',
              ),
              tab: tab,
              teamFilter: filterKey,
              typeFilter: type,
              sportFilter: sport,
            ),
        ];
      },
    );
  }
}

Future<PaginatedResponse<TeamMatchModel>> _fetchMatchesPage({
  required MyMatchesTab tab,
  required List<String>? teamIds,
  required MyMatchesTypeFilter typeFilter,
  required TeamSportType? sportFilter,
  required int page,
}) async {
  if (teamIds != null && teamIds.isEmpty) {
    return EmptyPaginatedResponse<TeamMatchModel>();
  }

  final result = await MatchmakingService().listRequests(
    ListNegotiationsFilterQuery(
      teamIds: teamIds,
      type: NegotiationListType.all,
      statuses: tab.apiStatuses,
      source: typeFilter.apiSource,
      sportType: sportFilter,
      page: page,
      limit: 20,
      sort: tab.sort,
    ),
  );
  return result ?? EmptyPaginatedResponse<TeamMatchModel>();
}

class _MyMatchesPane extends StatelessWidget {
  const _MyMatchesPane({
    super.key,
    required this.tab,
    required this.teamFilter,
    required this.typeFilter,
    required this.sportFilter,
  });

  final MyMatchesTab tab;
  final String teamFilter;
  final MyMatchesTypeFilter typeFilter;
  final TeamSportType? sportFilter;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<MyMatchesController>();
    final teamIds = c.teamIdsForMyMatchesList();
    final empty = switch (tab) {
      MyMatchesTab.all => const MatchHistoryEmptyPlaceholder(
        icon: Icons.sports_score_outlined,
        title: 'No matches',
        subtitle: 'Live, upcoming, and past matches will appear here.',
      ),
      MyMatchesTab.live => const MatchHistoryEmptyPlaceholder(
        icon: Icons.sensors,
        title: 'No live matches',
        subtitle: 'Matches that are currently ongoing will appear here.',
      ),
      MyMatchesTab.upcoming => const MatchHistoryEmptyPlaceholder(
        icon: Icons.event_available,
        title: 'No upcoming matches',
        subtitle: 'Scheduled matches show up here once a time is set.',
      ),
      MyMatchesTab.others => const MatchHistoryEmptyPlaceholder(
        icon: Icons.inventory_2_outlined,
        title: 'No other matches',
        subtitle:
            'Completed, rejected, cancelled, abandoned, and expired matches appear here.',
      ),
    };

    return MatchInfiniteQueryPane(
      queryKey: QueryKeys.myMatches(
        tab: tab.name,
        teamFilter: teamFilter,
        source: typeFilter.apiSource?.name,
        sportType: sportFilter?.name,
      ),
      fetchPage: (page) => _fetchMatchesPage(
        tab: tab,
        teamIds: teamIds,
        typeFilter: typeFilter,
        sportFilter: sportFilter,
        page: page,
      ),
      empty: empty,
      itemBuilder: (match, _, _) => MatchCard(
        match: match,
        isHistory: tab.isHistoryFor(match),
        onTap: () async {
          await openMatchChallengeDetail(
            match: match,
            isIncoming: c.isIncomingForMatch(match),
          );
        },
      ),
    );
  }
}
