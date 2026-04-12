import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/config/constants.dart';
import '../../match_up/match_history_controller.dart';
import '../../match_up/model/team_match_model.dart';
import 'match_card.dart';
import 'match_history_placeholders.dart';

class MatchHistoryTabs extends StatelessWidget {
  const MatchHistoryTabs({super.key, required this.controller});

  final MatchHistoryController controller;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(AppColors.dividerColor)
                    .withValues(alpha: 0.5),
              ),
            ),
            child: TabBar(
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: const Color(AppColors.primaryColor),
                borderRadius: BorderRadius.circular(11),
              ),
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: const Color(AppColors.textSecondaryColor),
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(text: 'Completed'),
                Tab(text: 'Upcoming'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              children: [
                MatchList(
                  controller: controller,
                  matches: controller.completedMatches,
                  isHistory: true,
                  emptyIcon: Icons.history,
                  emptyTitle: 'No match history',
                  emptySubtitle:
                      'Completed matches will appear here once your team finishes a game.',
                ),
                MatchList(
                  controller: controller,
                  matches: controller.upcomingMatches,
                  isHistory: false,
                  emptyIcon: Icons.event_available,
                  emptyTitle: 'No upcoming matches',
                  emptySubtitle:
                      'Scheduled and accepted matches will show up here.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MatchList extends StatelessWidget {
  const MatchList({
    super.key,
    required this.controller,
    required this.matches,
    required this.isHistory,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  final MatchHistoryController controller;
  final RxList<TeamMatchModel> matches;
  final bool isHistory;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingMatches.value && matches.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Color(AppColors.primaryColor),
            ),
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
        onRefresh: controller.reload,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          itemCount: matches.length,
          itemBuilder: (context, index) {
            return MatchCard(
              match: matches[index],
              selectedTeamId: controller.selectedTeam.value?.id,
              isHistory: isHistory,
            );
          },
        ),
      );
    });
  }
}
