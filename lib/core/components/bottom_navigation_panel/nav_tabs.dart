import 'package:flutter/material.dart';
import 'package:flutter_application_1/match_up/match_up_controller.dart';
import 'package:flutter_application_1/match_up/match_up_screen.dart';
import 'package:flutter_application_1/match_up/matches/matches_controller.dart';
import 'package:flutter_application_1/match_up/matches/matches_screen.dart';
import 'package:get/get.dart';
import '../../../dashboard/dashboard_screen.dart';
import '../../../dashboard/player/player_dashboard_controller.dart';
import '../../../turf/feed/turf_list_screen.dart';
import '../../../rankings/rank_screen.dart';
import '../../../rankings/rank_controller.dart';
import '../../../turf/feed/turf_list_controller.dart';

class NavTab {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Widget Function() screenBuilder;
  final void Function()? loadController;
  final void Function()? disposeController;

  const NavTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.screenBuilder,
    this.loadController,
    this.disposeController,
  });
}

final List<NavTab> kNavTabs = [
  NavTab(
    icon: Icons.dashboard_outlined,
    activeIcon: Icons.dashboard,
    label: 'Dashboard',
    screenBuilder: () => const DashboardScreen(),
    loadController: () =>
        _ensure<PlayerDashboardController>(() => PlayerDashboardController()),
    disposeController: () => _dispose<PlayerDashboardController>(),
  ),
  NavTab(
    icon: Icons.grass_outlined,
    activeIcon: Icons.grass,
    label: 'Turves',
    screenBuilder: () => const TurfListScreen(),
    loadController: () =>
        _ensure<TurfListController>(() => TurfListController()),
    disposeController: () => _dispose<TurfListController>(),
  ),
  NavTab(
    icon: Icons.sports_score_outlined,
    activeIcon: Icons.sports_score,
    label: 'Matches',
    screenBuilder: () => const MatchesScreen(),
    loadController: () =>
        _ensure<MatchesController>(() => MatchesController()),
    disposeController: () => _dispose<MatchesController>(),
  ),
  NavTab(
    icon: Icons.sports_soccer_outlined,
    activeIcon: Icons.sports_soccer,
    label: 'Match Up',
    screenBuilder: () => const MatchUpScreen(),
    loadController: () => _ensure<MatchUpController>(() => MatchUpController()),
    disposeController: () => _dispose<MatchUpController>(),
  ),
  NavTab(
    icon: Icons.emoji_events_outlined,
    activeIcon: Icons.emoji_events,
    label: 'Rank',
    screenBuilder: () => const RankScreen(),
    loadController: () => _ensure<RankController>(() => RankController()),
    disposeController: () => _dispose<RankController>(),
  ),
];

void _ensure<T extends GetxController>(T Function() factory) {
  if (!Get.isRegistered<T>()) {
    Get.put<T>(factory(), permanent: false);
  }
}

void _dispose<T extends GetxController>() {
  if (Get.isRegistered<T>()) {
    Get.delete<T>();
  }
}
