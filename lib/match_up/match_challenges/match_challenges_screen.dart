import 'package:flutter/material.dart';
import 'package:get/get.dart';

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

  @override
  void initState() {
    super.initState();
    final c = Get.find<MatchChallengesController>();
    _tabController = TabController(
      length: 2,
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
                items: const [
                  AppTabItem(label: 'Received'),
                  AppTabItem(label: 'Sent'),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                final receivedState = c.tabStateFor(MatchChallengesTab.received);
                final sentState = c.tabStateFor(MatchChallengesTab.sent);
                return AppSegmentedTabView(
                  controller: _tabController,
                  children: [
                    _ChallengesTabView(
                      state: receivedState,
                      emptyMessage: 'No challenges received yet.',
                      itemBuilder: (m) =>
                          _ReceivedChallengeCard(match: m, controller: c),
                      onRefresh: c.refreshCurrentTab,
                    ),
                    _ChallengesTabView(
                      state: sentState,
                      emptyMessage: 'No challenges sent yet.',
                      itemBuilder: (m) =>
                          _SentChallengeCard(match: m, controller: c),
                      onRefresh: c.refreshCurrentTab,
                    ),
                  ],
                );
              }),
            ),
          ],
        );
      }),
    );
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
    final canAccept = match.status == TeamMatchStatus.requested;

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
          onTap: () => Get.to(
            () => MatchChallengeDetailScreen(match: match, isIncoming: true),
          ),
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
                    _StatusChip(status: match.status),
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
                if (canAccept) ...[
                  const SizedBox(height: 14),
                  Obx(() {
                    final busy = controller.acceptingMatchId.value == match.id;
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: busy
                            ? null
                            : () => controller.acceptChallenge(match),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(AppColors.primaryColor),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: busy
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Accept challenge',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                      ),
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
          onTap: () => Get.to(
            () => MatchChallengeDetailScreen(match: match, isIncoming: false),
          ),
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
                    _StatusChip(status: match.status),
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
  const _StatusChip({required this.status});

  final TeamMatchStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(AppColors.primaryColor).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusLabel(status),
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
    _ => s.name.capitalizeFirst!,
  };
}

String _formatDate(DateTime d) {
  final local = d.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}
