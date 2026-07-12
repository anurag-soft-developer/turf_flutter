import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../core/auth/auth_state_controller.dart';
import '../../core/components/bottom_navigation_panel/navigation_controller.dart';
import '../../core/config/constants.dart';
import '../../core/models/user/player_stats_models.dart';
import '../../core/query/query_keys.dart';
import '../../core/services/user_service.dart';
import '../../rankings/model/player_leaderboard_model.dart';
import '../rankings/leaderboard_podium.dart';
import '../rankings/player_avatar.dart';
import '../shared/breathing_skeleton.dart';

Duration? _noRetry(int count, Object error) => null;

class _DashboardLeaderboardData {
  const _DashboardLeaderboardData({
    required this.topThree,
    required this.currentUserRow,
  });

  final List<PlayerLeaderboardRow> topThree;
  final PlayerLeaderboardRow? currentUserRow;

  PlayerLeaderboardRow? entryForRank(int rank) {
    for (final entry in topThree) {
      if (entry.rank == rank) return entry;
    }
    return null;
  }
}

class DashboardLeaderboardSection extends HookWidget {
  const DashboardLeaderboardSection({super.key});

  void _openRank() {
    if (Get.isRegistered<NavigationController>()) {
      Get.find<NavigationController>().changeTab(3);
      return;
    }
    Get.toNamed(AppConstants.routes.rank);
  }

  PlayerLeaderboardRow _buildCurrentUserFallback(AuthStateController auth) {
    const sport = SportType.cricket;
    final user = auth.user;
    final points = user?.sportRankingPoints
            .where((e) => e.sportType == sport.name)
            .map((e) => e.points)
            .firstOrNull ??
        0;

    return PlayerLeaderboardRow(
      rank: 0,
      id: user?.id ?? '',
      name: user?.displayName ?? 'You',
      points: points,
      avatar: user?.avatar,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthStateController>();

    final leaderboardQuery = useQuery<_DashboardLeaderboardData, Object>(
      QueryKeys.dashboardLeaderboard,
      (_) async {
        final result = await UserService().getLeaderboard(
          PlayerLeaderboardQuery(
            sportType: SportType.cricket,
            page: 1,
            limit: 50,
          ),
        );
        final items = result?.data ?? <PlayerLeaderboardRow>[];
        final topThree = items.where((e) => e.rank >= 1 && e.rank <= 3).toList()
          ..sort((a, b) => a.rank.compareTo(b.rank));

        final userId = auth.user?.id;
        PlayerLeaderboardRow? me;
        if (userId != null && userId.isNotEmpty) {
          for (final row in items) {
            if (row.id == userId) {
              me = row;
              break;
            }
          }
        }
        me ??= _buildCurrentUserFallback(auth);
        final isInTopThree = me.rank >= 1 && me.rank <= 3;

        return _DashboardLeaderboardData(
          topThree: topThree,
          currentUserRow: isInTopThree ? null : me,
        );
      },
      retry: _noRetry,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Leaderboard',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(AppColors.textColor),
                ),
              ),
            ),
            TextButton(
              onPressed: _openRank,
              style: TextButton.styleFrom(
                foregroundColor: const Color(AppColors.primaryColor),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'View all',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (leaderboardQuery.isLoading ||
            (leaderboardQuery.isFetching && leaderboardQuery.data == null))
          const _LeaderboardSkeleton()
        else if (leaderboardQuery.isError && leaderboardQuery.data == null)
          Center(
            child: TextButton(
              onPressed: () => leaderboardQuery.refetch(),
              child: const Text('Retry leaderboard'),
            ),
          )
        else
          _LeaderboardCard(
            second: leaderboardQuery.data?.entryForRank(2),
            first: leaderboardQuery.data?.entryForRank(1),
            third: leaderboardQuery.data?.entryForRank(3),
            currentUser: leaderboardQuery.data?.currentUserRow,
          ),
      ],
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  const _LeaderboardCard({
    required this.second,
    required this.first,
    required this.third,
    required this.currentUser,
  });

  final PlayerLeaderboardRow? second;
  final PlayerLeaderboardRow? first;
  final PlayerLeaderboardRow? third;
  final PlayerLeaderboardRow? currentUser;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
      child: Column(
        children: [
          LeaderboardPodium(
            first: first == null
                ? null
                : LeaderboardPodiumEntry.fromPlayer(first!),
            second: second == null
                ? null
                : LeaderboardPodiumEntry.fromPlayer(second!),
            third:
                third == null ? null : LeaderboardPodiumEntry.fromPlayer(third!),
            avatarBuilder: (entry, size) => PlayerAvatar(
              url: entry.avatarUrl ?? '',
              name: entry.name,
              size: size,
              userId: entry.id,
            ),
            onSlotTap: (entry) {
              final id = entry.id;
              if (id == null || id.isEmpty) return;
              Get.toNamed(
                AppConstants.routes.teamMemberProfile,
                arguments: {'userId': id},
              );
            },
          ),
          if (currentUser != null) _CurrentUserRow(entry: currentUser!),
        ],
      ),
    );
  }
}

class _CurrentUserRow extends StatelessWidget {
  const _CurrentUserRow({required this.entry});

  final PlayerLeaderboardRow entry;

  @override
  Widget build(BuildContext context) {
    final rankLabel = entry.rank > 0 ? '${entry.rank}' : '—';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(AppColors.backgroundColor),
        border: Border(
          top: BorderSide(
            color: const Color(AppColors.dividerColor).withValues(alpha: 0.6),
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              rankLabel,
              style: const TextStyle(
                color: Color(AppColors.textSecondaryColor),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          PlayerAvatar(
            url: entry.avatar ?? '',
            name: entry.name,
            size: 36,
            userId: entry.id,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'You',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(AppColors.textColor),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '${entry.points}',
            style: const TextStyle(
              color: Color(AppColors.primaryColor),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardSkeleton extends StatelessWidget {
  const _LeaderboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return BreathingSkeleton(
      builder: (opacity) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(AppColors.surfaceColor),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(AppColors.dividerColor).withValues(alpha: 0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(AppColors.primaryColor)
                    .withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                child: SizedBox(
                  height: 176,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: _PodiumSlotSkeleton(
                          opacity: opacity,
                          badgeSize: 24,
                          avatarSize: 52,
                        ),
                      ),
                      Expanded(
                        child: Transform.translate(
                          offset: const Offset(0, -12),
                          child: _PodiumSlotSkeleton(
                            opacity: opacity,
                            badgeSize: 28,
                            avatarSize: 64,
                          ),
                        ),
                      ),
                      Expanded(
                        child: _PodiumSlotSkeleton(
                          opacity: opacity,
                          badgeSize: 24,
                          avatarSize: 52,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(AppColors.backgroundColor),
                  border: Border(
                    top: BorderSide(
                      color: const Color(AppColors.dividerColor)
                          .withValues(alpha: 0.6),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    BreathingBlock(
                      opacity: opacity,
                      width: 20,
                      height: 15,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(width: 8),
                    BreathingCircle(opacity: opacity, size: 36),
                    const SizedBox(width: 12),
                    Expanded(
                      child: BreathingBlock(
                        opacity: opacity,
                        height: 15,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    BreathingBlock(
                      opacity: opacity,
                      width: 36,
                      height: 15,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PodiumSlotSkeleton extends StatelessWidget {
  const _PodiumSlotSkeleton({
    required this.opacity,
    required this.badgeSize,
    required this.avatarSize,
  });

  final double opacity;
  final double badgeSize;
  final double avatarSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        BreathingCircle(opacity: opacity, size: badgeSize),
        const SizedBox(height: 6),
        BreathingCircle(opacity: opacity, size: avatarSize),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: BreathingBlock(
            opacity: opacity,
            height: 12,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}
