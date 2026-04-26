import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../components/challenges/match_challenge_respond_actions.dart';
import '../../components/match_history/match_card.dart';
import '../../components/match_history/match_history_placeholders.dart';
import '../../components/match_up/my_team_selector.dart';
import '../../components/shared/app_segmented_tabs/app_segmented_tabs.dart';
import '../../core/config/constants.dart';
import '../../team/utils/team_ui.dart';
import '../model/team_match_model.dart';
import 'match_challenge_detail_screen.dart';
import 'match_challenges_controller.dart';

class MatchChallengesScreen extends StatefulWidget {
  const MatchChallengesScreen({super.key});

  @override
  State<MatchChallengesScreen> createState() => _MatchChallengesScreenState();
}

class _MatchChallengesScreenState extends State<MatchChallengesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  List<AppTabItem> _tabs = const [
    AppTabItem(label: 'Received'),
    AppTabItem(label: 'Sent'),
    AppTabItem(label: 'Completed'),
    AppTabItem(label: 'Upcoming'),
    AppTabItem(label: 'Archive'),
  ];

  @override
  void initState() {
    super.initState();
    final c = Get.find<MatchChallengesController>();
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: c.selectedTab.value.index,
    );
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      c.switchTab(_tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MatchChallengesController c = Get.find();

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(title: const Text('Challenges')),
      body: Obx(() {
        if (c.isLoadingMemberships.value && c.memberships.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Color(AppColors.primaryColor),
              ),
            ),
          );
        }
        if (c.myTeams.isEmpty) {
          return const _NoMembershipsMessage();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                // spacing: 4,
                children: [
                  Expanded(
                    child: Obx(
                      () => MyTeamSelector(
                        teams: c.myTeams,
                        allowToSelectAll: true,
                        allTeamsSelected: c.filterAllTeams.value,
                        selectedTeam: c.selectedMembershipTeam.value,
                        sheetTitle: 'Show challenges for',
                        onTeamSelected: c.selectTeamForFilter,
                        onAllTeamsSelected: c.selectAllTeamsFilter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: AppSegmentedTabs(
                controller: _tabController,
                onTap: c.switchTab,
                padding: EdgeInsets.zero,
                items: _tabs,
              ),
            ),
            Expanded(
              child: AppSegmentedTabView(
                controller: _tabController,
                children: [
                  Obx(() {
                    final state = c.tabStateFor(MatchChallengesTab.received);
                    return _ChallengesTabView(
                      state: state,
                      emptyMessage: 'No challenges received yet.',
                      itemBuilder: (m) =>
                          _ReceivedChallengeCard(match: m, controller: c),
                      onRefresh: c.refreshCurrentTab,
                    );
                  }),
                  Obx(() {
                    final state = c.tabStateFor(MatchChallengesTab.sent);
                    return _ChallengesTabView(
                      state: state,
                      emptyMessage: 'No challenges sent yet.',
                      itemBuilder: (m) =>
                          _SentChallengeCard(match: m, controller: c),
                      onRefresh: c.refreshCurrentTab,
                    );
                  }),
                  const _HistoryListPane(
                    tab: MatchChallengesTab.completed,
                    isHistory: true,
                    emptyIcon: Icons.history,
                    emptyTitle: 'No match history',
                    emptySubtitle:
                        'Completed matches will appear here once your team finishes a game.',
                  ),
                  const _HistoryListPane(
                    tab: MatchChallengesTab.upcoming,
                    isHistory: false,
                    emptyIcon: Icons.event_available,
                    emptyTitle: 'No upcoming matches',
                    emptySubtitle:
                        'Scheduled or live matches show up here once a time is set.',
                  ),
                  const _HistoryListPane(
                    tab: MatchChallengesTab.archive,
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
      }),
    );
  }
}

class _HistoryListPane extends StatelessWidget {
  const _HistoryListPane({
    required this.tab,
    required this.isHistory,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  final MatchChallengesTab tab;
  final bool isHistory;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<MatchChallengesController>();

    return Obx(() {
      final state = c.tabStateFor(tab);
      final selectedTeamId = c.filterAllTeams.value
          ? null
          : c.selectedMembershipTeam.value?.id;
      final matches = state.items;
      if ((state.isFetching && matches.isEmpty) ||
          (!state.hasInitialized && matches.isEmpty)) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Color(AppColors.primaryColor),
            ),
          ),
        );
      }

      if (state.error != null && matches.isEmpty) {
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
              Text(
                state.error!,
                style: const TextStyle(
                  color: Color(AppColors.textSecondaryColor),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => c.resetAndRefetch(tab),
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
        onRefresh: c.refreshCurrentTab,
        color: const Color(AppColors.primaryColor),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: matches.length,
          itemBuilder: (context, index) {
            final m = matches[index];
            return MatchCard(
              match: m,
              selectedTeamId: selectedTeamId,
              isHistory: isHistory,
              onTap: () async {
                await Get.to(
                  () => MatchChallengeDetailScreen(
                    match: m,
                    isIncoming: _isIncomingForMatch(m, c),
                  ),
                );
              },
            );
          },
        ),
      );
    });
  }
}

class _ChallengesTabView extends StatelessWidget {
  const _ChallengesTabView({
    required this.state,
    required this.emptyMessage,
    required this.itemBuilder,
    required this.onRefresh,
  });

  final SegmentedTabDataState<TeamMatchModel> state;
  final String emptyMessage;
  final Widget Function(TeamMatchModel match) itemBuilder;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final list = state.items;
    if ((state.isFetching && list.isEmpty) ||
        (!state.hasInitialized && list.isEmpty)) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Color(AppColors.primaryColor),
          ),
        ),
      );
    }

    if (state.error != null && list.isEmpty) {
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
                  Text(
                    state.error!,
                    style: const TextStyle(
                      color: Color(AppColors.textSecondaryColor),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: onRefresh,
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
      onRefresh: onRefresh,
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
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => itemBuilder(list[i]),
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
            await Get.to(
              () => MatchChallengeDetailScreen(match: match, isIncoming: true),
            );
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
            await Get.to(
              () => MatchChallengeDetailScreen(match: match, isIncoming: false),
            );
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

/// Backend [expired], or [expiresAt] passed while still negotiating.
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

/// Aligns with [MatchChallengeDetailScreen.isIncoming]: [to] is the side that received the request.
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
