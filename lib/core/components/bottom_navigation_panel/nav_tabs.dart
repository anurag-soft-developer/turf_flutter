import 'package:flutter/material.dart';
import 'package:flutter_application_1/bindings/explore_binding.dart';
import 'package:flutter_application_1/explore/explore_screen.dart';
import 'package:flutter_application_1/match_up/match_up_controller.dart';
import 'package:flutter_application_1/match_up/match_up_screen.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../../dashboard/dashboard_screen.dart';
import '../../../dashboard/player/player_dashboard_controller.dart';
import '../../../rankings/rank_controller.dart';
import '../../../rankings/rank_screen.dart';
import '../../../turf/feed/turf_list_controller.dart';
import '../../../turf/feed/turf_list_screen.dart';
import '../../query/query_keys.dart';

class NavTab {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Widget Function() screenBuilder;
  final void Function()? loadController;
  final void Function()? disposeController;

  /// Called when the user taps the already-selected tab (pull-to-refresh style).
  final Future<void> Function()? onRetap;

  const NavTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.screenBuilder,
    this.loadController,
    this.disposeController,
    this.onRetap,
  });
}

Future<void> _invalidate(List queryKey) async {
  if (!Get.isRegistered<QueryClient>()) return;
  await Get.find<QueryClient>().invalidateQueries(queryKey: queryKey);
}

final List<NavTab> kNavTabs = [
  NavTab(
    icon: Icons.dashboard_outlined,
    activeIcon: Icons.dashboard,
    label: 'Dashboard',
    screenBuilder: () => const DashboardScreen(),
    loadController: () => _ensure<PlayerDashboardController>(
      () => PlayerDashboardController(),
      permanent: true,
    ),
    // Keep alive so the bell badge unread count survives tab switches.
    onRetap: () async {
      await Future.wait([
        _invalidate(QueryKeys.playerDashboardPrefix),
        _invalidate(QueryKeys.dashboardLeaderboard),
      ]);
    },
  ),
  NavTab(
    icon: Icons.grass_outlined,
    activeIcon: Icons.grass,
    label: 'Turves',
    screenBuilder: () => const TurfListScreen(),
    loadController: () =>
        _ensure<TurfListController>(() => TurfListController()),
    disposeController: () => _dispose<TurfListController>(),
    onRetap: () => _invalidate(QueryKeys.turfSearchPrefix),
  ),
  NavTab(
    icon: Icons.explore_outlined,
    activeIcon: Icons.explore,
    label: 'Explore',
    screenBuilder: () => const ExploreScreen(),
    loadController: () => ExploreBinding().dependencies(),
    onRetap: () => _invalidate(QueryKeys.explorePrefix),
  ),
  NavTab(
    icon: Icons.sports_soccer_outlined,
    activeIcon: Icons.sports_soccer,
    label: 'Match Up',
    screenBuilder: () => const MatchUpScreen(),
    loadController: () => _ensure<MatchUpController>(() => MatchUpController()),
    disposeController: () => _dispose<MatchUpController>(),
    onRetap: () async {
      await Future.wait([
        _invalidate(QueryKeys.myMemberships),
        _invalidate(QueryKeys.matchUpOpponentsPrefix),
        _invalidate(QueryKeys.matchChallengesPrefix),
      ]);
    },
  ),
  NavTab(
    icon: Icons.emoji_events_outlined,
    activeIcon: Icons.emoji_events,
    label: 'Rank',
    screenBuilder: () => const RankScreen(),
    loadController: () => _ensure<RankController>(() => RankController()),
    disposeController: () => _dispose<RankController>(),
    onRetap: () async {
      await Future.wait([
        _invalidate(QueryKeys.playerLeaderboardPrefix),
        _invalidate(QueryKeys.teamLeaderboardPrefix),
      ]);
    },
  ),
];

void _ensure<T extends GetxController>(
  T Function() factory, {
  bool permanent = false,
}) {
  if (!Get.isRegistered<T>()) {
    Get.put<T>(factory(), permanent: permanent);
  }
}

void _dispose<T extends GetxController>() {
  if (Get.isRegistered<T>()) {
    Get.delete<T>();
  }
}
