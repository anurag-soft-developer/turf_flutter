import 'package:flutter/material.dart';
import 'package:flutter_application_1/components/shared/app_drawer.dart';
import 'package:get/get.dart';

import '../../components/match_up/team_logo.dart';
import '../../components/match_up/team_stats_row.dart';
import '../../components/shared/app_segmented_tabs/app_segmented_tabs.dart';
import '../../core/config/constants.dart';
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
  final SegmentedTabDataState<TeamModel> state;

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

    final teams = state.items;
    final topTeams = teams.take(3).toList();
    final restTeams = teams.length > 3 ? teams.sublist(3) : <TeamModel>[];

    return RefreshIndicator(
      onRefresh: () => controller.reloadSport(sport),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 20),
          _PodiumSection(teams: topTeams),
          if (restTeams.isNotEmpty) ...[
            const SizedBox(height: 24),
            ...restTeams.asMap().entries.map(
              (e) => _RankCard(rank: e.key + 4, team: e.value),
            ),
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
  const _PodiumSection({required this.teams});

  final List<TeamModel> teams;

  @override
  Widget build(BuildContext context) {
    if (teams.isEmpty) return const SizedBox.shrink();

    if (teams.length == 1) {
      return _PodiumCard(rank: 1, team: teams[0]);
    }

    if (teams.length == 2) {
      return Column(
        children: [
          _PodiumCard(rank: 1, team: teams[0]),
          const SizedBox(height: 12),
          _PodiumCard(rank: 2, team: teams[1]),
        ],
      );
    }

    return Column(
      children: [
        _PodiumCard(rank: 1, team: teams[0]),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _PodiumCard(rank: 2, team: teams[1])),
            const SizedBox(width: 12),
            Expanded(child: _PodiumCard(rank: 3, team: teams[2])),
          ],
        ),
      ],
    );
  }
}

class _PodiumCard extends StatelessWidget {
  const _PodiumCard({required this.rank, required this.team});

  final int rank;
  final TeamModel team;

  static const _rankConfigs = <int, _RankStyle>{
    1: _RankStyle(
      gradient: [Color(0xFFFFD700), Color(0xFFFFA000)],
      medalIcon: Icons.emoji_events,
      elevation: 8,
      logoSize: 72,
      nameFontSize: 18,
    ),
    2: _RankStyle(
      gradient: [Color(0xFFB0BEC5), Color(0xFF78909C)],
      medalIcon: Icons.emoji_events,
      elevation: 4,
      logoSize: 56,
      nameFontSize: 15,
    ),
    3: _RankStyle(
      gradient: [Color(0xFFCD7F32), Color(0xFFA0522D)],
      medalIcon: Icons.emoji_events,
      elevation: 2,
      logoSize: 56,
      nameFontSize: 15,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final style = _rankConfigs[rank] ?? _rankConfigs[3]!;
    final id = team.id;

    return GestureDetector(
      onTap: id == null || id.isEmpty
          ? null
          : () => Get.toNamed(
              AppConstants.routes.teamProfile,
              arguments: {'teamId': id},
            ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              style.gradient[0].withValues(alpha: 0.15),
              style.gradient[1].withValues(alpha: 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: style.gradient[0].withValues(alpha: 0.3),
            width: rank == 1 ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: style.gradient[0].withValues(alpha: 0.15),
              blurRadius: style.elevation,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(
          vertical: rank == 1 ? 24 : 16,
          horizontal: 16,
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topRight,
              children: [
                TeamLogo(url: team.logo, size: style.logoSize, teamId: id),
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: style.gradient),
                      boxShadow: [
                        BoxShadow(
                          color: style.gradient[0].withValues(alpha: 0.4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Icon(
                      style.medalIcon,
                      size: rank == 1 ? 20 : 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '#$rank',
              style: TextStyle(
                fontSize: rank == 1 ? 28 : 22,
                fontWeight: FontWeight.w900,
                foreground: Paint()
                  ..shader = LinearGradient(
                    colors: style.gradient,
                  ).createShader(const Rect.fromLTWH(0, 0, 60, 30)),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              team.name,
              style: TextStyle(
                fontSize: style.nameFontSize,
                fontWeight: FontWeight.w700,
                color: const Color(AppColors.textColor),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TeamStatsRow(team: team, compact: rank != 1),
          ],
        ),
      ),
    );
  }
}

class _RankStyle {
  final List<Color> gradient;
  final IconData medalIcon;
  final double elevation;
  final double logoSize;
  final double nameFontSize;

  const _RankStyle({
    required this.gradient,
    required this.medalIcon,
    required this.elevation,
    required this.logoSize,
    required this.nameFontSize,
  });
}

// ---------------------------------------------------------------------------
// Rest of list — uniform cards (rank 4+)
// ---------------------------------------------------------------------------

class _RankCard extends StatelessWidget {
  const _RankCard({required this.rank, required this.team});

  final int rank;
  final TeamModel team;

  @override
  Widget build(BuildContext context) {
    final id = team.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: id == null || id.isEmpty
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
                    '#$rank',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(AppColors.textSecondaryColor),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                TeamLogo(url: team.logo, size: 44, teamId: id),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(AppColors.textColor),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      TeamStatsRow(team: team, compact: true),
                    ],
                  ),
                ),
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
