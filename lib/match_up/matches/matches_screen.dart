import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../components/match_history/match_card.dart';
import '../../components/match_history/match_history_placeholders.dart';
import '../../components/shared/app_search_field.dart';
import '../../core/config/constants.dart';
import '../../core/models/paginated_response.dart';
import '../../core/query/query_keys.dart';
import '../../core/query/query_retry.dart';
import '../match_challenges/match_challenge_detail_screen.dart';
import '../matchmaking_service.dart';
import '../model/team_match_model.dart';
import 'match_list_filters.dart';
import 'match_list_filters_bar.dart';
import 'matches_controller.dart';

class MatchesScreen extends HookWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final MatchesController c = Get.find();
    final searchController = useTextEditingController();
    final searchText = useState('');
    final debouncedSearch = useState('');
    final filters = useState(MatchListFilters.all);

    useEffect(() {
      void listener() {
        searchText.value = searchController.text;
      }

      searchController.addListener(listener);
      return () => searchController.removeListener(listener);
    }, [searchController]);

    useEffect(() {
      final timer = Timer(const Duration(milliseconds: 350), () {
        debouncedSearch.value = searchText.value.trim();
        c.setSearchQuery(searchText.value);
      });
      return timer.cancel;
    }, [searchText.value]);

    final activeFilters = filters.value;
    final search = debouncedSearch.value;

    final query =
        useInfiniteQuery<PaginatedResponse<TeamMatchModel>, Object, int>(
      QueryKeys.matches(
        scope: activeFilters.scope.name,
        status: activeFilters.status.name,
        search: search,
      ),
      (ctx) => _fetchMatchesPage(
        filters: activeFilters,
        search: search,
        page: ctx.pageParam,
      ),
      initialPageParam: 1,
      retry: noRetry,
      nextPageParamBuilder: (data) {
        final last = data.pages.isNotEmpty ? data.pages.last : null;
        if (last == null || !last.hasNextPage) return null;
        return last.page + 1;
      },
    );

    final matches =
        query.data?.pages.expand((p) => p.data).toList() ??
        const <TeamMatchModel>[];

    final emptyCopy = _emptyCopy(activeFilters);

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(title: const Text('Matches')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: AppSearchField(
              controller: searchController,
              hintText: 'Search by team name',
              onCleared: () {
                searchText.value = '';
                debouncedSearch.value = '';
                c.setSearchQuery('');
              },
            ),
          ),
          MatchListFiltersBar(
            filters: activeFilters,
            onChanged: (next) => filters.value = next,
          ),
          Expanded(
            child: _MatchesList(
              query: query,
              matches: matches,
              emptyTitle: emptyCopy.$1,
              emptySubtitle: emptyCopy.$2,
            ),
          ),
        ],
      ),
    );
  }
}

(String, String) _emptyCopy(MatchListFilters filters) {
  final isMy = filters.type == MatchTypeFilter.my;
  return switch (filters.status) {
    MatchStatusFilter.live => (
      isMy ? 'No live matches for your teams' : 'No live matches',
      'When a match is in progress, it will show up here.',
    ),
    MatchStatusFilter.upcoming => (
      isMy ? 'No upcoming matches for your teams' : 'No upcoming matches',
      'Scheduled fixtures appear here once a time is set.',
    ),
    MatchStatusFilter.completed => (
      isMy ? 'No completed matches for your teams' : 'No completed matches',
      'Finished games and draws will appear here.',
    ),
    MatchStatusFilter.all => (
      isMy ? 'No matches for your teams' : 'No matches yet',
      isMy
          ? 'When your teams play, live, upcoming, and completed fixtures appear here.'
          : 'Live, upcoming, and completed matches show up here.',
    ),
  };
}

Future<PaginatedResponse<TeamMatchModel>> _fetchMatchesPage({
  required MatchListFilters filters,
  required String search,
  required int page,
}) async {
  const pageSize = 20;
  final result = await MatchmakingService().listRequests(
    ListNegotiationsFilterQuery(
      type: NegotiationListType.all,
      scope: filters.scope,
      search: search.isEmpty ? null : search,
      statuses: filters.apiStatuses,
      page: page,
      limit: pageSize,
      sort: 'updatedAt:desc',
    ),
  );
  return result ?? EmptyPaginatedResponse<TeamMatchModel>();
}

class _MatchesList extends StatelessWidget {
  const _MatchesList({
    required this.query,
    required this.matches,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  final InfiniteQueryResult<PaginatedResponse<TeamMatchModel>, Object, int>
  query;
  final List<TeamMatchModel> matches;
  final String emptyTitle;
  final String emptySubtitle;

  @override
  Widget build(BuildContext context) {
    if (query.isLoading || (query.isFetching && matches.isEmpty)) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Color(AppColors.primaryColor),
          ),
        ),
      );
    }

    if (query.isError && matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 42,
              color: Color(AppColors.textSecondaryColor),
            ),
            const SizedBox(height: 10),
            const Text(
              'Failed to load matches',
              style: TextStyle(
                color: Color(AppColors.textSecondaryColor),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => query.refetch(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (matches.isEmpty) {
      return RefreshIndicator(
        color: const Color(AppColors.primaryColor),
        onRefresh: () async {
          await query.refetch();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.5,
              child: MatchHistoryEmptyPlaceholder(
                icon: Icons.sports_score_outlined,
                title: emptyTitle,
                subtitle: emptySubtitle,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(AppColors.primaryColor),
      onRefresh: () async {
        await query.refetch();
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.pixels >=
              notification.metrics.maxScrollExtent - 200) {
            if (query.hasNextPage && !query.isFetchingNextPage) {
              query.fetchNextPage();
            }
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: matches.length + (query.isFetchingNextPage ? 1 : 0),
          itemBuilder: (context, i) {
            if (i == matches.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(AppColors.primaryColor),
                    ),
                  ),
                ),
              );
            }
            final m = matches[i];
            final isHistory =
                m.status == TeamMatchStatus.completed ||
                m.status == TeamMatchStatus.draw;
            return MatchCard(
              match: m,
              selectedTeamId: null,
              isHistory: isHistory,
              onTap: () async {
                await openMatchChallengeDetail(match: m);
              },
            );
          },
        ),
      ),
    );
  }
}
