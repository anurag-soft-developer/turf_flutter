import 'package:flutter/material.dart';
import 'package:flutter_application_1/components/shared/user_avatar_app_bar_action.dart';
import 'package:get/get.dart';

import '../components/shared/app_segmented_tabs/app_segmented_tabs.dart';
import '../core/config/constants.dart';
import '../team/feed/teams_ranking_controller.dart';
import 'player_ranking_controller.dart';
import 'rank_controller.dart';
import 'widgets/player_ranking_list.dart';
import 'widgets/rank_sport_filter.dart';
import 'widgets/teams_ranking_list.dart';

class RankScreen extends StatefulWidget {
  const RankScreen({super.key});

  @override
  State<RankScreen> createState() => _RankScreenState();
}

class _RankScreenState extends State<RankScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = RankTab.values;

  @override
  void initState() {
    super.initState();
    final rankController = Get.find<RankController>();
    final initialIndex = _tabs.indexOf(rankController.selectedTab.value);
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: initialIndex < 0 ? 0 : initialIndex,
    );
    _tabController.addListener(_onTabChanged);
    rankController.ensureActiveTabLoaded();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final idx = _tabController.index;
    if (idx >= 0 && idx < _tabs.length) {
      Get.find<RankController>().switchTab(_tabs[idx]);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rankController = Get.find<RankController>();
    final teamsController = Get.find<TeamsRankingController>();
    final playerController = Get.find<PlayerRankingController>();

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const UserAvatarAppBarAction(),
        title: const Text('Rank'),
      ),
      body: Obx(() {
        final currentIndex = _tabs.indexOf(rankController.selectedTab.value);
        final safeIndex = currentIndex < 0 ? 0 : currentIndex;
        if (_tabController.index != safeIndex) {
          _tabController.animateTo(safeIndex);
        }

        final sport = rankController.selectedSport.value;
        final playerSport = rankController.playerSport;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Expanded(
                    child: RankSportFilter(
                      value: sport,
                      onChanged: rankController.switchSport,
                      sheetTitle: 'Show rankings for',
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: AppSegmentedTabs(
                controller: _tabController,
                onTap: (index) => rankController.switchTab(_tabs[index]),
                padding: EdgeInsets.zero,
                items: const [
                  AppTabItem(label: 'Teams', icon: Icons.groups_outlined),
                  AppTabItem(label: 'Players', icon: Icons.person_outline),
                ],
              ),
            ),
            Expanded(
              child: AppSegmentedTabView(
                controller: _tabController,
                children: [
                  TeamsRankingList(
                    controller: teamsController,
                    sport: sport,
                  ),
                  PlayerRankingList(
                    controller: playerController,
                    sport: playerSport,
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
