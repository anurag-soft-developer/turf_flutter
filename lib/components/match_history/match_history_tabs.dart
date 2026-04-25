import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/config/constants.dart';
import '../../match_up/match_history/match_history_controller.dart';
import '../shared/app_segmented_tabs/app_segmented_tabs.dart';
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
      tab: MatchHistoryTab.completed,
      isHistory: true,
      emptyIcon: Icons.history,
      emptyTitle: 'No match history',
      emptySubtitle:
          'Completed matches will appear here once your team finishes a game.',
    ),
    MatchList(
      controller: widget.controller,
      tab: MatchHistoryTab.upcoming,
      isHistory: false,
      emptyIcon: Icons.event_available,
      emptyTitle: 'No upcoming matches',
      emptySubtitle: 'Scheduled and accepted matches will show up here.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.controller.selectedHistoryTab.value.index;
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: initialIndex,
    );
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      final idx = _tabController.index;
      if (idx >= 0 && idx < MatchHistoryTab.values.length) {
        widget.controller.switchHistoryTab(MatchHistoryTab.values[idx]);
      }
    });
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
    required this.tab,
    required this.isHistory,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  final MatchHistoryController controller;
  final MatchHistoryTab tab;
  final bool isHistory;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = controller.tabStateFor(tab);
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
                onPressed: () => controller.refreshTab(tab),
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
        onRefresh: () => controller.refreshTab(tab),
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
