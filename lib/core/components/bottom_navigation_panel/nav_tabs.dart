import 'package:flutter/material.dart';
import 'package:flutter_application_1/bindings/explore_binding.dart';
import 'package:flutter_application_1/chat/chat_inbox_screen.dart';
import 'package:flutter_application_1/explore/explore_screen.dart';
import 'package:flutter_application_1/match_up/challenge/challenge_controller.dart';
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

  /// Called when the user taps the already-selected tab (pull-to-refresh style).
  final Future<void> Function()? onRetap;

  const NavTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.screenBuilder,
    this.loadController,
    this.onRetap,
  });
}

Future<void> _invalidate(List queryKey) async {
  if (!Get.isRegistered<QueryClient>()) return;
  await Get.find<QueryClient>().invalidateQueries(queryKey: queryKey);
}

final List<NavTab> kNavTabs = [
  NavTab(
    icon: Icons.explore_outlined,
    activeIcon: Icons.explore,
    label: 'Explore',
    screenBuilder: () => const ExploreScreen(),
    loadController: () => ExploreBinding().dependencies(),
    onRetap: () async {
      await _invalidate(QueryKeys.explorePrefix);
      await _invalidate(QueryKeys.activeOpponentIds);
      if (Get.isRegistered<ChallengeController>()) {
        await Get.find<ChallengeController>().loadActiveOpponentIds();
      }
    },
  ),
  NavTab(
    icon: Icons.grass_outlined,
    activeIcon: Icons.grass,
    label: 'Turfs',
    screenBuilder: () => const TurfListScreen(),
    loadController: () =>
        _ensure<TurfListController>(() => TurfListController()),
    onRetap: () => _invalidate(QueryKeys.turfSearchPrefix),
  ),
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
    icon: Icons.chat_bubble_outline,
    activeIcon: Icons.chat_bubble,
    label: 'Messages',
    screenBuilder: () => const ChatInboxScreen(),
    onRetap: () => _invalidate(QueryKeys.chatInbox),
  ),
  NavTab(
    icon: Icons.emoji_events_outlined,
    activeIcon: Icons.emoji_events,
    label: 'Rank',
    screenBuilder: () => const RankScreen(),
    loadController: () => _ensure<RankController>(() => RankController()),
    onRetap: () async {
      await Future.wait([
        _invalidate(QueryKeys.playerLeaderboardPrefix),
        _invalidate(QueryKeys.teamLeaderboardPrefix),
      ]);
    },
  ),
];

int navTabIndex(String label, {int fallback = -1}) {
  final index = kNavTabs.indexWhere((tab) => tab.label == label);
  return index < 0 ? fallback : index;
}

int get kDefaultNavTabIndex => navTabIndex('Dashboard', fallback: 0);

void _ensure<T extends GetxController>(
  T Function() factory, {
  bool permanent = false,
}) {
  if (!Get.isRegistered<T>()) {
    Get.put<T>(factory(), permanent: permanent);
  }
}
