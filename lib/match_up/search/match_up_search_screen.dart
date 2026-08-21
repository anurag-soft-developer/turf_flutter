import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../components/match_up/team_logo.dart';
import '../../components/match_up/team_stats_row.dart';
import '../../core/config/constants.dart';
import '../../core/models/paginated_response.dart';
import '../../core/query/query_keys.dart';
import '../../core/query/query_retry.dart';
import '../../core/components/search/app_search_screen.dart';
import '../../core/services/search/search_history_store.dart';
import '../../rankings/widgets/rank_sport_filter.dart';
import '../../team/model/team_model.dart';
import '../../team/team_service.dart';
import '../match_up_controller.dart';

class MatchUpSearchScreen extends StatelessWidget {
  const MatchUpSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MatchUpController>();

    return AppSearchScreen(
      historyScope: SearchHistoryScope.matchUp,
      hintText: 'Search teams by name',
      headerBuilder: (context, query) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Obx(
            () => SportFilterPicker(
              value: controller.selectedSport.value,
              sports: TeamSportType.values,
              sheetTitle: 'Filter by sport',
              searchable: true,
              onChanged: controller.switchSport,
            ),
          ),
        );
      },
      resultsBuilder: (context, query) => _MatchUpSearchResults(
        query: query,
        controller: controller,
      ),
    );
  }
}

class _MatchUpSearchResults extends HookWidget {
  const _MatchUpSearchResults({
    required this.query,
    required this.controller,
  });

  final String query;
  final MatchUpController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final sport = controller.selectedSport.value;
      final fromTeamId = controller.selectedTeam.value?.id;
      final hasTeams = controller.hasTeamForSport;

      if (!hasTeams) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Join a ${sport.name} team to search and challenge opponents.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Color(AppColors.textSecondaryColor),
              ),
            ),
          ),
        );
      }

      return _MatchUpSearchFeed(
        key: ValueKey('${sport.name}|${fromTeamId ?? ''}|$query'),
        sport: sport,
        fromTeamId: fromTeamId,
        search: query,
        controller: controller,
      );
    });
  }
}

class _MatchUpSearchFeed extends HookWidget {
  const _MatchUpSearchFeed({
    super.key,
    required this.sport,
    required this.fromTeamId,
    required this.search,
    required this.controller,
  });

  final TeamSportType sport;
  final String? fromTeamId;
  final String search;
  final MatchUpController controller;

  @override
  Widget build(BuildContext context) {
    final queryKey = QueryKeys.matchUpOpponents(
      sport: sport.name,
      fromTeamId: fromTeamId,
      search: search,
    );

    final opponentsQuery =
        useInfiniteQuery<PaginatedResponse<TeamModel>, Object, int>(
      queryKey,
      (ctx) async {
        final result = await TeamService().findMany(
          TeamFilterQuery(
            sportType: sport,
            teamOpenForMatch: true,
            status: TeamStatus.active,
            visibility: TeamVisibility.public,
            page: ctx.pageParam,
            limit: 10,
            skipTeamsWithSentRequest: fromTeamId != null,
            fromTeamId: fromTeamId,
            search: search,
          ),
        );
        final selectedTeamId = fromTeamId;
        final items = (result?.data ?? const <TeamModel>[])
            .where((team) => team.id != null && team.id != selectedTeamId)
            .toList();
        return PaginatedResponse<TeamModel>(
          data: items,
          totalDocuments: result?.totalDocuments ?? items.length,
          page: result?.page ?? ctx.pageParam,
          limit: result?.limit ?? 10,
          totalPages: result?.totalPages ?? 1,
        );
      },
      initialPageParam: 1,
      retry: noRetry,
      nextPageParamBuilder: (data) {
        final last = data.pages.isNotEmpty ? data.pages.last : null;
        if (last == null || !last.hasNextPage) return null;
        return last.page + 1;
      },
    );

    final items =
        opponentsQuery.data?.pages.expand((p) => p.data).toList() ??
        const <TeamModel>[];

    if (opponentsQuery.isLoading ||
        (opponentsQuery.isFetching && items.isEmpty)) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Color(AppColors.primaryColor),
          ),
        ),
      );
    }

    if (opponentsQuery.isError && items.isEmpty) {
      return Center(
        child: ElevatedButton(
          onPressed: () => opponentsQuery.refetch(),
          child: const Text('Retry'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => opponentsQuery.refetch(),
      child: items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_off_outlined,
                        size: 48,
                        color: Color(AppColors.textSecondaryColor),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No teams found',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(AppColors.textColor),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Try another keyword.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(AppColors.textSecondaryColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification.metrics.pixels >=
                    notification.metrics.maxScrollExtent - 200) {
                  if (opponentsQuery.hasNextPage &&
                      !opponentsQuery.isFetchingNextPage) {
                    opponentsQuery.fetchNextPage();
                  }
                }
                return false;
              },
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount:
                    items.length + (opponentsQuery.isFetchingNextPage ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == items.length) {
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

                  final team = items[index];
                  return Obx(() {
                    final isSent = controller.isTeamChallenged(team.id);
                    return _SearchOpponentCard(
                      team: team,
                      isSent: isSent,
                      onChallenge: isSent
                          ? null
                          : () => _confirmChallenge(context, controller, team),
                    );
                  });
                },
              ),
            ),
    );
  }

  Future<void> _confirmChallenge(
    BuildContext context,
    MatchUpController controller,
    TeamModel opponent,
  ) async {
    final myTeam = controller.selectedTeam.value;
    if (myTeam == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send challenge?'),
        content: Text(
          'Challenge ${opponent.name} with ${myTeam.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Challenge'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await controller.sendChallenge(opponent);
    }
  }
}

class _SearchOpponentCard extends StatelessWidget {
  const _SearchOpponentCard({
    required this.team,
    required this.isSent,
    required this.onChallenge,
  });

  final TeamModel team;
  final bool isSent;
  final VoidCallback? onChallenge;

  @override
  Widget build(BuildContext context) {
    final enabled = !isSent && onChallenge != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(AppColors.dividerColor).withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          final id = team.id;
          if (id != null && id.isNotEmpty) {
            Get.toNamed(
              AppConstants.routes.teamProfile,
              arguments: {'teamId': id},
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  TeamLogo(url: team.logo, size: 48, teamId: team.id),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          team.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(AppColors.textColor),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (team.location != null) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 13,
                                color: Color(AppColors.textSecondaryColor),
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  team.location!.address,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(AppColors.textSecondaryColor),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TeamStatsRow.fromTeam(team)),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: enabled ? onChallenge : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: enabled
                          ? const Color(AppColors.primaryColor)
                          : const Color(AppColors.dividerColor),
                      foregroundColor: enabled
                          ? Colors.white
                          : const Color(AppColors.textSecondaryColor),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(isSent ? 'Sent' : 'Challenge'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
