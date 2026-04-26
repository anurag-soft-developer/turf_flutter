import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../components/match_up/team_logo.dart';
import '../../components/shared/app_segmented_tabs/app_segmented_tabs.dart';
import '../../core/config/constants.dart';
import '../model/team_model.dart';
import '../utils/team_ui.dart';
import 'team_openings_controller.dart';

class TeamOpeningsScreen extends StatefulWidget {
  const TeamOpeningsScreen({super.key});

  @override
  State<TeamOpeningsScreen> createState() => _TeamOpeningsScreenState();
}

class _TeamOpeningsScreenState extends State<TeamOpeningsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    final controller = Get.find<TeamOpeningsController>();
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
    final TeamOpeningsController controller = Get.find();

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: const Text('Openings'),
        actions: [
          IconButton(
            tooltip: 'My join requests',
            icon: const Icon(Icons.assignment_outlined),
            onPressed: () => Get.toNamed(AppConstants.routes.myJoinRequests),
          ),
        ],
      ),
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
                      label: teamSportLabel(sport),
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
                      (sport) => _OpeningsTabContent(
                        controller: controller,
                        sport: sport,
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

class _OpeningsTabContent extends StatelessWidget {
  const _OpeningsTabContent({required this.controller, required this.sport});

  final TeamOpeningsController controller;
  final TeamSportType sport;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = controller.stateForSport(sport);
      // Track membership and join button spinners
      controller.myMembershipsLoaded.value;
      controller.joiningTeamIds;

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
                Icons.group_add_outlined,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              const Text(
                'No teams are recruiting for this sport yet.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(AppColors.textSecondaryColor),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () async {
          await controller.reloadSport(sport);
          await controller.refreshMyMemberships();
        },
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          itemCount: state.items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final team = state.items[i];
            final id = team.id;
            if (id == null || id.isEmpty) return const SizedBox.shrink();
            return _RecruitingTeamCard(
              team: team,
              label: controller.joinButtonLabel(id) ?? 'Join',
              onJoin: controller.canTapJoin(id)
                  ? () => controller.requestJoin(id)
                  : null,
              isJoining: controller.joiningTeamIds.contains(id),
            );
          },
        ),
      );
    });
  }
}

class _RecruitingTeamCard extends StatelessWidget {
  const _RecruitingTeamCard({
    required this.team,
    required this.label,
    required this.onJoin,
    required this.isJoining,
  });

  final TeamModel team;
  final String label;
  final VoidCallback? onJoin;
  final bool isJoining;

  @override
  Widget build(BuildContext context) {
    final id = team.id;
    return Card(
      elevation: 0,
      color: const Color(AppColors.surfaceColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: id == null || id.isEmpty
            ? null
            : () => Get.toNamed(
                AppConstants.routes.teamProfile,
                arguments: {'teamId': id},
              ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TeamLogo(url: team.logo, size: 52, teamId: id),
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _Chip(text: teamJoinModeLabel(team.joinMode)),
                        if (team.lookingForMembers)
                          const _Chip(text: 'Recruiting', highlighted: true),
                      ],
                    ),
                    if (team.tagline != null && team.tagline!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        team.tagline!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(AppColors.textSecondaryColor),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: onJoin == null || isJoining ? null : () => onJoin!(),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(AppColors.primaryColor),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: const Size(0, 36),
                ),
                child: isJoining
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        label,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, this.highlighted = false});

  final String text;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: highlighted
            ? const Color(AppColors.primaryColor).withValues(alpha: 0.12)
            : const Color(AppColors.textSecondaryColor).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: highlighted
              ? const Color(AppColors.primaryColor)
              : const Color(AppColors.textSecondaryColor),
        ),
      ),
    );
  }
}
