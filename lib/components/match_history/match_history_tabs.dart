import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/config/constants.dart';
import '../../match_up/match_history/match_history_controller.dart';
import '../../match_up/model/team_match_model.dart';
import '../shared/app_segmented_tabs.dart';
import 'match_card.dart';
import 'match_history_placeholders.dart';

class MatchHistoryTabs extends StatefulWidget {
  const MatchHistoryTabs({super.key, required this.controller});

  final MatchHistoryController controller;

  @override
  State<MatchHistoryTabs> createState() => _MatchHistoryTabsState();
}

class _MatchHistoryTabsState extends State<MatchHistoryTabs>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  List<AppTabItem> get _tabs => [
    AppTabItem(label: 'Completed'),
    AppTabItem(label: 'Upcoming'),
  ];

  List<Widget> get _children => [
    MatchList(
      controller: widget.controller,
      matches: widget.controller.completedMatches,
      isHistory: true,
      emptyIcon: Icons.history,
      emptyTitle: 'No match history',
      emptySubtitle:
          'Completed matches will appear here once your team finishes a game.',
    ),
    MatchList(
      controller: widget.controller,
      matches: widget.controller.upcomingMatches,
      isHistory: false,
      emptyIcon: Icons.event_available,
      emptyTitle: 'No upcoming matches',
      emptySubtitle: 'Scheduled and accepted matches will show up here.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: AppSegmentedTabs(
            controller: _tabController,
            padding: EdgeInsets.zero,
            items: _tabs,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: AppSegmentedTabView(
            controller: _tabController,
            children: _children,
          ),
        ),
      ],
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
