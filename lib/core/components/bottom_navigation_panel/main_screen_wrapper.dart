import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../dashboard/dashboard_screen.dart';
import '../../../turf/feed/turf_list_screen.dart';
import '../../../match_up/match_up_screen.dart';
import '../../../team/feed/teams_ranking_screen.dart';
import '../../../rankings/player_ranking_screen.dart';
import '../../../profile/profile_screen.dart';
import 'app_bottom_navigation_panel.dart';
import 'navigation_controller.dart';

class MainScreenWrapper extends StatelessWidget {
  const MainScreenWrapper({super.key});

  Widget _getCurrentScreen(int index) {
    switch (index) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const TurfListScreen();
      case 2:
        return const MatchUpScreen();
      case 3:
        return const TeamsRankingScreen();
      case 4:
        return const PlayerRankingScreen();
      case 5:
        return const ProfileScreen();
      default:
        return const DashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final NavigationController navController = Get.find<NavigationController>();

    return Scaffold(
      body: Obx(() => _getCurrentScreen(navController.currentIndex)),
      bottomNavigationBar: Obx(
        () => AppBottomNavigationPanel(
          currentIndex: navController.currentIndex,
          onTap: navController.changeTab,
        ),
      ),
    );
  }
}
