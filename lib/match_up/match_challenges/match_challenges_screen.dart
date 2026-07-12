import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../components/challenges/match_challenge_respond_actions.dart';
import '../../components/match_history/match_card.dart';
import '../../components/match_history/match_history_placeholders.dart';
import '../../components/match_up/my_team_selector.dart';
import '../../components/shared/app_segmented_tabs/app_segmented_tabs.dart';
import '../../core/config/constants.dart';
import '../../core/models/paginated_response.dart';
import '../../core/query/query_keys.dart';
import '../../core/query/query_retry.dart';
import '../../team/members/model/team_member_model.dart';
import '../../team/team_service.dart';
import '../../team/utils/team_ui.dart';
import '../matchmaking_service.dart';
import '../model/team_match_model.dart';
import 'match_challenge_detail_screen.dart';
import 'match_challenges_controller.dart';

class MatchChallengesScreen extends HookWidget {
  const MatchChallengesScreen({super.key});

  static const _tabs = [
    AppTabItem(label: 'Received'),
    AppTabItem(label: 'Sent'),
    AppTabItem(label: 'Live'),
    AppTabItem(label: 'Upcoming'),
    AppTabItem(label: 'Completed'),
    AppTabItem(label: 'Archive'),
  ];

  @override
  Widget build(BuildContext context) {
    final MatchChallengesController c = Get.find();
    final teamService = TeamService();
    final ticker = useSingleTickerProvider();

    final membershipsQuery = useQuery<List<TeamMemberModel>, Object>(
      QueryKeys.myMemberships,
      (_) async {
        final res = await teamService.memberService.myMemberships(
          const MyTeamMembershipsFilterQuery(
            status: TeamMemberStatus.active,
            limit: 50,
          ),
        );
        return res?.data ?? const <TeamMemberModel>[];
      },
      retry: noRetry,
    );

    useEffect(() {
      final data = membershipsQuery.data;
      if (data != null) {
        c.syncMemberships(data);
      }
      return null;
    }, [membershipsQuery.data]);

    final tabController = useMemoized(
      () => TabController(
        length: _tabs.length,
        vsync: ticker,
        initialIndex: c.selectedTab.value.index,
      ),
      [ticker],
    );

    useEffect(() {
      void listener() {
        if (tabController.indexIsChanging) return;
        c.switchTab(tabController.index);
      }

      tabController.addListener(listener);
      return () {
        tabController.removeListener(listener);
        tabController.dispose();
      };
    }, [tabController]);

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(title: const Text('Challenges')),
      body: _buildBody(
        c: c,
        membershipsQuery: membershipsQuery,
        tabController: tabController,
      ),
    );
  }

  Widget _buildBody({
    required MatchChallengesController c,
    required QueryResult<List<TeamMemberModel>, Object> membershipsQuery,
    required TabController tabController,
  }) {
    if (membershipsQuery.isLoading ||
        (membershipsQuery.isFetching && membershipsQuery.data == null)) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Color(AppColors.primaryColor),
          ),
        ),
      );
    }

    if (membershipsQuery.isError && membershipsQuery.data == null) {
      return Center(
        child: ElevatedButton(
          onPressed: () => membershipsQuery.refetch(),
          child: const Text('Retry'),
        ),
      );
    }

    return Obx(() {
      if (c.myTeams.isEmpty) {
        return const _NoMembershipsMessage();
      }

      final filterKey = c.teamFilterKey;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  child: MyTeamSelector(
                    teams: c.myTeams,
                    allowToSelectAll: true,
                    allTeamsSelected: c.filterAllTeams.value,
                    selectedTeam: c.selectedMembershipTeam.value,
                    sheetTitle: 'Show challenges for',
                    onTeamSelected: c.selectTeamForFilter,
                    onAllTeamsSelected: c.selectAllTeamsFilter,
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: AppSegmentedTabs(
              controller: tabController,
              onTap: c.switchTab,
              padding: EdgeInsets.zero,
              items: _tabs,
            ),
          ),
          Expanded(
            child: AppSegmentedTabView(
              controller: tabController,
              children: [
                _ChallengesQueryPane(
                  key: ValueKey('received|$filterKey'),
                  tab: MatchChallengesTab.received,
                  teamFilter: filterKey,
                  emptyMessage: 'No challenges received yet.',
                  itemBuilder: (m) =>
                      _ReceivedChallengeCard(match: m, controller: c),
                ),
                _ChallengesQueryPane(
                  key: ValueKey('sent|$filterKey'),
                  tab: MatchChallengesTab.sent,
                  teamFilter: filterKey,
                  emptyMessage: 'No challenges sent yet.',
                  itemBuilder: (m) =>
                      _SentChallengeCard(match: m, controller: c),
                ),
                _HistoryQueryPane(
                  key: ValueKey('live|$filterKey'),
                  tab: MatchChallengesTab.live,
                  teamFilter: filterKey,
                  isHistory: false,
                  emptyIcon: Icons.sensors,
                  emptyTitle: 'No live matches',
                  emptySubtitle:
                      'Matches that are currently ongoing will appear here.',
                ),
                _HistoryQueryPane(
                  key: ValueKey('upcoming|$filterKey'),
                  tab: MatchChallengesTab.upcoming,
                  teamFilter: filterKey,
                  isHistory: false,
                  emptyIcon: Icons.event_available,
                  emptyTitle: 'No upcoming matches',
                  emptySubtitle:
                      'Scheduled matches show up here once a time is set.',
                ),
                _HistoryQueryPane(
                  key: ValueKey('completed|$filterKey'),
                  tab: MatchChallengesTab.completed,
                  teamFilter: filterKey,
                  isHistory: true,
                  emptyIcon: Icons.history,
                  emptyTitle: 'No match history',
                  emptySubtitle:
                      'Completed matches will appear here once your team finishes a game.',
                ),
                _HistoryQueryPane(
                  key: ValueKey('archive|$filterKey'),
                  tab: MatchChallengesTab.archive,
                  teamFilter: filterKey,
                  isHistory: true,
                  emptyIcon: Icons.inventory_2_outlined,
                  emptyTitle: 'Nothing archived',
                  emptySubtitle:
                      'Rejected, cancelled, and expired requests appear here.',
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}

Future<PaginatedResponse<TeamMatchModel>> _fetchChallengesPage({
  required MatchChallengesTab tab,
  required List<String> teamIds,
  required int page,
}) async {
  if (teamIds.isEmpty) {
    return EmptyPaginatedResponse<TeamMatchModel>();
  }

  const pageSize = 20;
  final service = MatchmakingService();

  switch (tab) {
    case MatchChallengesTab.received:
    case MatchChallengesTab.sent:
      final type = tab == MatchChallengesTab.received
          ? NegotiationListType.incoming
          : NegotiationListType.outgoing;
      final inbox = await service.listInbox(
        ListPreMatchInboxFilterQuery(
          type: type,
          teamIds: teamIds,
          page: page,
          limit: pageSize,
          sort: 'createdAt:desc',
        ),
      );
      return inbox ?? EmptyPaginatedResponse<TeamMatchModel>();
    case MatchChallengesTab.completed:
      final completed = await service.listRequests(
        ListNegotiationsFilterQuery(
          teamIds: teamIds,
          type: NegotiationListType.all,
          statuses: const [TeamMatchStatus.completed, TeamMatchStatus.draw],
          page: page,
          limit: pageSize,
          sort: 'updatedAt:desc',
        ),
      );
      return completed ?? EmptyPaginatedResponse<TeamMatchModel>();
    case MatchChallengesTab.live:
      final live = await service.listRequests(
        ListNegotiationsFilterQuery(
          teamIds: teamIds,
          type: NegotiationListType.all,
          statuses: const [TeamMatchStatus.ongoing],
          page: page,
          limit: pageSize,
          sort: 'updatedAt:desc',
        ),
      );
      return live ?? EmptyPaginatedResponse<TeamMatchModel>();
    case MatchChallengesTab.upcoming:
      final upcoming = await service.listRequests(
        ListNegotiationsFilterQuery(
          teamIds: teamIds,
          type: NegotiationListType.all,
          statuses: const [TeamMatchStatus.scheduleFinalized],
          page: page,
          limit: pageSize,
          sort: 'createdAt:asc',
        ),
      );
      return upcoming ?? EmptyPaginatedResponse<TeamMatchModel>();
    case MatchChallengesTab.archive:
      final archive = await service.listRequests(
        ListNegotiationsFilterQuery(
          teamIds: teamIds,
          type: NegotiationListType.all,
          statuses: const [
            TeamMatchStatus.rejected,
            TeamMatchStatus.cancelled,
            TeamMatchStatus.expired,
          ],
          page: page,
          limit: pageSize,
          sort: 'updatedAt:desc',
        ),
      );
      return archive ?? EmptyPaginatedResponse<TeamMatchModel>();
  }
}

class _ChallengesQueryPane extends HookWidget {
  const _ChallengesQueryPane({
    super.key,
    required this.tab,
    required this.teamFilter,
    required this.emptyMessage,
    required this.itemBuilder,
  });

  final MatchChallengesTab tab;
  final String teamFilter;
  final String emptyMessage;
  final Widget Function(TeamMatchModel match) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<MatchChallengesController>();
    final teamIds = c.activeTeamIdsForList();

    final query =
        useInfiniteQuery<PaginatedResponse<TeamMatchModel>, Object, int>(
      QueryKeys.matchChallenges(tab: tab.name, teamFilter: teamFilter),
      (ctx) => _fetchChallengesPage(
        tab: tab,
        teamIds: teamIds,
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

    final list =
        query.data?.pages.expand((p) => p.data).toList() ??
        const <TeamMatchModel>[];

    if (query.isLoading || (query.isFetching && list.isEmpty)) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Color(AppColors.primaryColor),
          ),
        ),
      );
    }

    if (query.isError && list.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.35,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 42,
                    color: Color(AppColors.textSecondaryColor),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Failed to load',
                    style: TextStyle(
                      color: Color(AppColors.textSecondaryColor),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => query.refetch(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: () => query.refetch(),
      color: const Color(AppColors.primaryColor),
      child: list.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.35,
                  child: Center(
                    child: Text(
                      emptyMessage,
                      style: const TextStyle(
                        color: Color(AppColors.textSecondaryColor),
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : NotificationListener<ScrollNotification>(
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
                itemCount: list.length + (query.isFetchingNextPage ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i == list.length) {
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
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: i < list.length - 1 ? 12 : 0,
                    ),
                    child: itemBuilder(list[i]),
                  );
                },
              ),
            ),
    );
  }
}

class _HistoryQueryPane extends HookWidget {
  const _HistoryQueryPane({
    super.key,
    required this.tab,
    required this.teamFilter,
    required this.isHistory,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  final MatchChallengesTab tab;
  final String teamFilter;
  final bool isHistory;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<MatchChallengesController>();
    final teamIds = c.activeTeamIdsForList();
    final selectedTeamId = c.filterAllTeams.value
        ? null
        : c.selectedMembershipTeam.value?.id;

    final query =
        useInfiniteQuery<PaginatedResponse<TeamMatchModel>, Object, int>(
      QueryKeys.matchChallenges(tab: tab.name, teamFilter: teamFilter),
      (ctx) => _fetchChallengesPage(
        tab: tab,
        teamIds: teamIds,
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
              'Failed to load',
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
      return MatchHistoryEmptyPlaceholder(
        icon: emptyIcon,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }

    return RefreshIndicator(
      onRefresh: () => query.refetch(),
      color: const Color(AppColors.primaryColor),
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
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: matches.length + (query.isFetchingNextPage ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == matches.length) {
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
            final m = matches[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < matches.length - 1 ? 12 : 0,
              ),
              child: MatchCard(
                match: m,
                selectedTeamId: selectedTeamId,
                isHistory: isHistory,
                personalizeForTeam: true,
                onTap: () async {
                  await openMatchChallengeDetail(
                    match: m,
                    isIncoming: _isIncomingForMatch(m, c),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ReceivedChallengeCard extends StatelessWidget {
  const _ReceivedChallengeCard({required this.match, required this.controller});

  final TeamMatchModel match;
  final MatchChallengesController controller;

  @override
  Widget build(BuildContext context) {
    final fromName = match.fromTeamHelper.getDisplayName();
    final canRespond =
        match.status == TeamMatchStatus.requested &&
        !_matchShowsAsExpired(match);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await openMatchChallengeDetail(match: match, isIncoming: true);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        fromName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(AppColors.textColor),
                        ),
                      ),
                    ),
                    _StatusChip(match: match),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  teamSportLabel(match.sportType),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(AppColors.textSecondaryColor),
                  ),
                ),
                Obx(() {
                  if (!controller.filterAllTeams.value) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Receiving as: ${match.toTeamHelper.getDisplayName()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }),
                if (match.createdAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(match.createdAt!),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
                if (canRespond) ...[
                  const SizedBox(height: 14),
                  Obx(() {
                    final id = match.id;
                    final accepting =
                        id != null && controller.acceptingMatchId.value == id;
                    final rejecting =
                        id != null && controller.rejectingMatchId.value == id;
                    return MatchChallengeRespondActions(
                      isRejecting: rejecting,
                      isAccepting: accepting,
                      onReject: () => controller.rejectChallenge(match),
                      onAccept: () => controller.acceptChallenge(match),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SentChallengeCard extends StatelessWidget {
  const _SentChallengeCard({required this.match, required this.controller});

  final TeamMatchModel match;
  final MatchChallengesController controller;

  @override
  Widget build(BuildContext context) {
    final toName = match.toTeamHelper.getDisplayName();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await openMatchChallengeDetail(match: match, isIncoming: false);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        toName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(AppColors.textColor),
                        ),
                      ),
                    ),
                    _StatusChip(match: match),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  teamSportLabel(match.sportType),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(AppColors.textSecondaryColor),
                  ),
                ),
                Obx(() {
                  if (!controller.filterAllTeams.value) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Sent as: ${match.fromTeamHelper.getDisplayName()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }),
                if (match.createdAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(match.createdAt!),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.match});

  final TeamMatchModel match;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(AppColors.primaryColor).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusDisplayForMatch(match),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(AppColors.primaryColor),
        ),
      ),
    );
  }
}

class _NoMembershipsMessage extends StatelessWidget {
  const _NoMembershipsMessage();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.groups_outlined,
              size: 56,
              color: const Color(
                AppColors.primaryColor,
              ).withValues(alpha: 0.35),
            ),
            const SizedBox(height: 16),
            const Text(
              'No teams yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(AppColors.textColor),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Join or create a team to send and receive match challenges.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(AppColors.textSecondaryColor),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _statusLabel(TeamMatchStatus s) {
  return switch (s) {
    TeamMatchStatus.requested => 'Pending',
    TeamMatchStatus.scheduleFinalized => 'Scheduled',
    TeamMatchStatus.expired => 'EXPIRED',
    _ => s.name.capitalizeFirst!,
  };
}

bool _matchShowsAsExpired(TeamMatchModel m) {
  if (m.status == TeamMatchStatus.expired) return true;
  final ex = m.expiresAt;
  if (ex == null) return false;
  if (!DateTime.now().isAfter(ex.toLocal())) return false;
  return switch (m.status) {
    TeamMatchStatus.requested => true,
    TeamMatchStatus.accepted => true,
    TeamMatchStatus.negotiating => true,
    _ => false,
  };
}

String _statusDisplayForMatch(TeamMatchModel m) {
  if (_matchShowsAsExpired(m)) return 'EXPIRED';
  return _statusLabel(m.status);
}

String _formatDate(DateTime d) {
  final local = d.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

bool _isIncomingForMatch(TeamMatchModel match, MatchChallengesController c) {
  final toId = match.toTeamHelper.getId();
  final fromId = match.fromTeamHelper.getId();
  if (!c.filterAllTeams.value) {
    final sel = c.selectedMembershipTeam.value?.id;
    if (sel != null) {
      if (sel == toId) return true;
      if (sel == fromId) return false;
    }
  }
  final myIds = <String>{};
  for (final t in c.myTeams) {
    if (t.id != null && t.id!.isNotEmpty) myIds.add(t.id!);
  }
  final onTo = toId != null && myIds.contains(toId);
  final onFrom = fromId != null && myIds.contains(fromId);
  if (onTo && !onFrom) return true;
  if (onFrom && !onTo) return false;
  if (onTo) return true;
  return false;
}
