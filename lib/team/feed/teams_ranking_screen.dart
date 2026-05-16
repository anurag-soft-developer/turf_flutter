import 'package:flutter/material.dart';
import 'package:flutter_application_1/components/shared/app_drawer.dart';
import 'package:get/get.dart';

import '../../components/match_up/team_logo.dart';
import '../../components/match_up/team_stats_row.dart';
import '../../components/shared/app_segmented_tabs/app_segmented_tabs.dart';
import '../../core/config/constants.dart';
import '../model/team_leaderboard_model.dart';
import '../model/team_model.dart';
import 'teams_ranking_controller.dart';

class TeamsRankingScreen extends StatefulWidget {
  const TeamsRankingScreen({super.key});

  @override
  State<TeamsRankingScreen> createState() => _TeamsRankingScreenState();
}

class _TeamsRankingScreenState extends State<TeamsRankingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    final controller = Get.find<TeamsRankingController>();
    final sports = TeamSportType.values;
    final selected = sports.indexOf(controller.selectedSport.value);
    _tabController = TabController(
      length: sports.length,
      vsync: this,
      initialIndex: selected < 0 ? 0 : selected,
    );
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      final idx = _tabController.index;
      if (idx >= 0 && idx < sports.length) {
        controller.switchSport(sports[idx]);
      }
    });
    controller.ensureSportLoaded(controller.selectedSport.value);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TeamsRankingController controller = Get.find();

    return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(title: const Text('Team Rankings')),
      body: Obx(() {
        final sports = TeamSportType.values;
        final currentIndex = sports.indexOf(controller.selectedSport.value);
        final safeIndex = currentIndex < 0 ? 0 : currentIndex;
        if (_tabController.index != safeIndex) {
          _tabController.animateTo(safeIndex);
        }
        return Column(
          children: [
            AppSegmentedTabs(
              controller: _tabController,
              onTap: (index) => controller.switchSport(sports[index]),
              items: sports
                  .map(
                    (sport) => AppTabItem(
                      label: sport == TeamSportType.cricket
                          ? 'Cricket'
                          : 'Football',
                      icon: sport == TeamSportType.cricket
                          ? Icons.sports_cricket
                          : Icons.sports_soccer,
                    ),
                  )
                  .toList(),
            ),
            Expanded(
              child: AppSegmentedTabView(
                controller: _tabController,
                children: sports
                    .map(
                      (sport) => _RankingTabContent(
                        controller: controller,
                        sport: sport,
                        state: controller.stateForSport(sport),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _RankingTabContent extends StatelessWidget {
  const _RankingTabContent({
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
    final topEntries = entries.take(3).toList();
    final restEntries =
        entries.length > 3 ? entries.sublist(3) : <TeamLeaderboardRow>[];

    return RefreshIndicator(
      onRefresh: () => controller.reloadSport(sport),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 20),
          _PodiumSection(entries: topEntries),
          if (restEntries.isNotEmpty) ...[
            const SizedBox(height: 24),
            ...restEntries.map((entry) => _RankCard(entry: entry)),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Podium — top 3 teams
// ---------------------------------------------------------------------------

class _PodiumSection extends StatelessWidget {
  const _PodiumSection({required this.entries});

  final List<TeamLeaderboardRow> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    if (entries.length == 1) {
      return _PodiumCard(entry: entries[0]);
    }

    if (entries.length == 2) {
      return Column(
        children: [
          _PodiumCard(entry: entries[0]),
          const SizedBox(height: 12),
          _PodiumCard(entry: entries[1]),
        ],
      );
    }

    return Column(
      children: [
        _PodiumCard(entry: entries[0]),
        const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _PodiumCard(entry: entries[1])),
              const SizedBox(width: 10),
              Expanded(child: _PodiumCard(entry: entries[2])),
            ],
          ),
        ),
      ],
    );
  }
}

class _PodiumCard extends StatelessWidget {
  const _PodiumCard({required this.entry});

  final TeamLeaderboardRow entry;

  static const _rankConfigs = <int, _RankStyle>{
    1: _RankStyle(
      gradient: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
      rankLabel: '1st',
      logoSize: 64,
      ringWidth: 3,
      nameFontSize: 17,
      pointsFontSize: 15,
      borderRadius: 20,
      shadowBlur: 14,
      shadowOffset: 6,
      stripHeight: 5,
      contentPadding: EdgeInsets.fromLTRB(16, 18, 16, 16),
      showMatchesPlayed: true,
    ),
    2: _RankStyle(
      gradient: [Color(0xFFCFD8DC), Color(0xFF607D8B)],
      rankLabel: '2nd',
      logoSize: 48,
      ringWidth: 2.5,
      nameFontSize: 14,
      pointsFontSize: 13,
      borderRadius: 16,
      shadowBlur: 8,
      shadowOffset: 4,
      stripHeight: 4,
      contentPadding: EdgeInsets.fromLTRB(12, 14, 12, 14),
      showMatchesPlayed: false,
    ),
    3: _RankStyle(
      gradient: [Color(0xFFD7A86E), Color(0xFF8D5524)],
      rankLabel: '3rd',
      logoSize: 48,
      ringWidth: 2.5,
      nameFontSize: 14,
      pointsFontSize: 13,
      borderRadius: 16,
      shadowBlur: 6,
      shadowOffset: 3,
      stripHeight: 4,
      contentPadding: EdgeInsets.fromLTRB(12, 14, 12, 14),
      showMatchesPlayed: false,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final rank = entry.rank;
    final style = _rankConfigs[rank] ?? _rankConfigs[3]!;
    final isFirst = rank == 1;
    final id = entry.id;
    final logo = entry.avatar ?? '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: id.isEmpty
            ? null
            : () => Get.toNamed(
                AppConstants.routes.teamProfile,
                arguments: {'teamId': id},
              ),
        borderRadius: BorderRadius.circular(style.borderRadius),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(style.borderRadius),
            color: Colors.white,
            border: Border.all(
              color: style.gradient[0].withValues(alpha: isFirst ? 0.45 : 0.28),
              width: isFirst ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: style.gradient[1].withValues(alpha: isFirst ? 0.22 : 0.12),
                blurRadius: style.shadowBlur,
                offset: Offset(0, style.shadowOffset),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(style.borderRadius),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: style.stripHeight,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: style.gradient),
                      ),
                    ),
                    Padding(
                      padding: style.contentPadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _PodiumLogoFrame(
                                url: logo,
                                teamId: id,
                                style: style,
                              ),
                              SizedBox(width: isFirst ? 14 : 10),
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: isFirst ? 8 : 4,
                                    top: isFirst ? 4 : 2,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.name,
                                        style: TextStyle(
                                          fontSize: style.nameFontSize,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(
                                            AppColors.textColor,
                                          ),
                                          height: 1.25,
                                        ),
                                        maxLines: isFirst ? 2 : 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: isFirst ? 8 : 6),
                                      _PodiumPointsChip(
                                        points: entry.points,
                                        style: style,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isFirst ? 12 : 10),
                          _PodiumStatsBar(
                            entry: entry,
                            showMatchesPlayed: style.showMatchesPlayed,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: style.stripHeight - (isFirst ? 12 : 10),
                right: isFirst ? 12 : 8,
                child: _PodiumRankBadge(
                  style: style,
                  isFirst: isFirst,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PodiumRankBadge extends StatelessWidget {
  const _PodiumRankBadge({
    required this.style,
    required this.isFirst,
  });

  final _RankStyle style;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isFirst ? 10 : 8,
        vertical: isFirst ? 5 : 4,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: style.gradient),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: style.gradient[1].withValues(alpha: 0.35),
            blurRadius: isFirst ? 6 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFirst ? Icons.workspace_premium_rounded : Icons.emoji_events_rounded,
            size: isFirst ? 16 : 13,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            style.rankLabel,
            style: TextStyle(
              fontSize: isFirst ? 13 : 11,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumLogoFrame extends StatelessWidget {
  const _PodiumLogoFrame({
    required this.url,
    required this.teamId,
    required this.style,
  });

  final String url;
  final String teamId;
  final _RankStyle style;

  @override
  Widget build(BuildContext context) {
    final outer = style.logoSize + style.ringWidth * 2 + 8;

    return Container(
      width: outer,
      height: outer,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: style.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: style.gradient[0].withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: style.logoSize + style.ringWidth * 2,
          height: style.logoSize + style.ringWidth * 2,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: Center(
            child: TeamLogo(url: url, size: style.logoSize, teamId: teamId),
          ),
        ),
      ),
    );
  }
}

class _PodiumPointsChip extends StatelessWidget {
  const _PodiumPointsChip({
    required this.points,
    required this.style,
  });

  final int points;
  final _RankStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: style.gradient[0].withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: style.gradient[0].withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$points',
            style: TextStyle(
              fontSize: style.pointsFontSize,
              fontWeight: FontWeight.w800,
              color: style.gradient[1],
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'pts',
            style: TextStyle(
              fontSize: style.pointsFontSize - 2,
              fontWeight: FontWeight.w600,
              color: style.gradient[1].withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumStatsBar extends StatelessWidget {
  const _PodiumStatsBar({
    required this.entry,
    required this.showMatchesPlayed,
  });

  final TeamLeaderboardRow entry;
  final bool showMatchesPlayed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(AppColors.backgroundColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TeamStatsRow.fromLeaderboard(
        entry,
        compact: !showMatchesPlayed,
      ),
    );
  }
}

class _RankStyle {
  final List<Color> gradient;
  final String rankLabel;
  final double logoSize;
  final double ringWidth;
  final double nameFontSize;
  final double pointsFontSize;
  final double borderRadius;
  final double shadowBlur;
  final double shadowOffset;
  final double stripHeight;
  final EdgeInsets contentPadding;
  final bool showMatchesPlayed;

  const _RankStyle({
    required this.gradient,
    required this.rankLabel,
    required this.logoSize,
    required this.ringWidth,
    required this.nameFontSize,
    required this.pointsFontSize,
    required this.borderRadius,
    required this.shadowBlur,
    required this.shadowOffset,
    required this.stripHeight,
    required this.contentPadding,
    required this.showMatchesPlayed,
  });
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
