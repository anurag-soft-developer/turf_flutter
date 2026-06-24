import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../components/match_up/team_logo.dart';
import '../../components/match_up/team_stats_row.dart';
import '../../components/rankings/leaderboard_podium.dart';
import '../../components/shared/app_segmented_tabs/segmented_tab_cache_controller.dart';
import '../../core/config/constants.dart';
import '../../team/feed/teams_ranking_controller.dart';
import '../../team/model/team_leaderboard_model.dart';
import '../../team/model/team_model.dart';

class TeamsRankingList extends StatelessWidget {
  const TeamsRankingList({
    super.key,
    required this.controller,
    required this.sport,
  });

  final TeamsRankingController controller;
  final TeamSportType sport;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = controller.stateForSport(sport);
      return _TeamsRankingListBody(
        controller: controller,
        sport: sport,
        state: state,
      );
    });
  }
}

class _TeamsRankingListBody extends StatelessWidget {
  const _TeamsRankingListBody({
    required this.controller,
    required this.sport,
    required this.state,
  });

  final TeamsRankingController controller;
  final TeamSportType sport;
  final SegmentedTabDataState<TeamLeaderboardRow> state;

  @override
  Widget build(BuildContext context) {
    final isFirstLoad = !state.hasInitialized && state.items.isEmpty;
    if (isFirstLoad || (state.isFetching && state.items.isEmpty)) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Color(AppColors.primaryColor),
          ),
        ),
      );
    }

    if (state.error != null && state.items.isEmpty) {
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
              onPressed: () => controller.reloadSport(sport),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'No teams ranked yet.',
              style: TextStyle(
                color: Color(AppColors.textSecondaryColor),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    final entries = state.items;
    final restEntries = entries.where((e) => e.rank > 3).toList();

    return RefreshIndicator(
      onRefresh: () => controller.reloadSport(sport),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.pixels >=
              notification.metrics.maxScrollExtent - 200) {
            controller.loadMore(sport);
          }
          return false;
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            const SizedBox(height: 20),
            _TeamsPodiumSection(entries: entries),
            if (restEntries.isNotEmpty) ...[
              const SizedBox(height: 24),
              ...restEntries.map((entry) => _RankCard(entry: entry)),
            ],
            if (state.isLoadingMore)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(AppColors.primaryColor),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

TeamLeaderboardRow? _entryForRank(List<TeamLeaderboardRow> entries, int rank) {
  for (final entry in entries) {
    if (entry.rank == rank) return entry;
  }
  return null;
}

class _TeamsPodiumSection extends StatelessWidget {
  const _TeamsPodiumSection({required this.entries});

  final List<TeamLeaderboardRow> entries;

  @override
  Widget build(BuildContext context) {
    final first = _entryForRank(entries, 1);
    final second = _entryForRank(entries, 2);
    final third = _entryForRank(entries, 3);

    if (first == null && second == null && third == null) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(AppColors.surfaceColor),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(AppColors.dividerColor).withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(AppColors.primaryColor).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: LeaderboardPodium(
        first: first == null ? null : LeaderboardPodiumEntry.fromTeam(first),
        second:
            second == null ? null : LeaderboardPodiumEntry.fromTeam(second),
        third: third == null ? null : LeaderboardPodiumEntry.fromTeam(third),
        avatarBuilder: (entry, size) => TeamLogo(
          url: entry.avatarUrl ?? '',
          size: size,
          teamId: entry.id ?? '',
        ),
        onSlotTap: (entry) {
          final id = entry.id;
          if (id == null || id.isEmpty) return;
          Get.toNamed(
            AppConstants.routes.teamProfile,
            arguments: {'teamId': id},
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Rest of list — uniform cards (rank 4+)
// ---------------------------------------------------------------------------

class _RankCard extends StatelessWidget {
  const _RankCard({required this.entry});

  final TeamLeaderboardRow entry;

  @override
  Widget build(BuildContext context) {
    final id = entry.id;
    final logo = entry.avatar ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: id.isEmpty
              ? null
              : () => Get.toNamed(
                  AppConstants.routes.teamProfile,
                  arguments: {'teamId': id},
                ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(
                  AppColors.dividerColor,
                ).withValues(alpha: 0.5),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Text(
                    '#${entry.rank}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(AppColors.textSecondaryColor),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                TeamLogo(url: logo, size: 44, teamId: id),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(AppColors.textColor),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      TeamStatsRow.fromLeaderboard(entry, compact: true),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${entry.points}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(AppColors.primaryColor),
                      ),
                    ),
                    const Text(
                      'pts',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(AppColors.textSecondaryColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Color(AppColors.textSecondaryColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
