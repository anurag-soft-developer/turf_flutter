import 'package:flutter/material.dart';
import 'package:flutter_application_1/match_up/match_up_controller.dart';
import 'package:flutter_application_1/match_up/match_up_screen.dart';
import 'package:get/get.dart';
import '../../../dashboard/dashboard_screen.dart';
import '../../../settings/settings_controller.dart';
import '../../../turf/my_turves/my_turfs_screen.dart';
import '../../../turf/my_turves/turf_management_controller.dart';
import '../../../turf_booking/bookings_screen.dart';
import '../../../turf_booking/turf_booking_controller.dart';
import '../../../turf/feed/turf_list_screen.dart';
import '../../../team/feed/teams_ranking_screen.dart';
import '../../../rankings/player_ranking_screen.dart';
import '../../../profile/profile_screen.dart';
import '../../../turf/feed/turf_list_controller.dart';
import '../../../team/feed/teams_ranking_controller.dart';
import '../../../profile/profile_controller.dart';

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
    loadController: () {
      _ensure<SettingsController>(() => SettingsController());
      // Player dashboard uses FeaturedTurfsSection → Get.find<TurfListController>()
      _ensure<TurfListController>(() => TurfListController());
    },
    disposeController: () {
      _dispose<SettingsController>();
      _dispose<TurfListController>();
    },
  ),
  NavTab(
    icon: Icons.grass_outlined,
    activeIcon: Icons.grass,
    label: 'Turfs',
    screenBuilder: () => const TurfListScreen(),
    loadController: () =>
        _ensure<TurfListController>(() => TurfListController()),
    disposeController: () => _dispose<TurfListController>(),
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
    icon: Icons.groups_outlined,
    activeIcon: Icons.groups,
    label: 'Teams',
    screenBuilder: () => const TeamsRankingScreen(),
    loadController: () =>
        _ensure<TeamsRankingController>(() => TeamsRankingController()),
    disposeController: () => _dispose<TeamsRankingController>(),
  ),
  NavTab(
    icon: Icons.emoji_events_outlined,
    activeIcon: Icons.emoji_events,
    label: 'Players',
    screenBuilder: () => const PlayerRankingScreen(),
  ),
  NavTab(
    icon: Icons.person_outline,
    activeIcon: Icons.person,
    label: 'Profile',
    screenBuilder: () => const ProfileScreen(),
    loadController: () => _ensure<ProfileController>(() => ProfileController()),
    disposeController: () => _dispose<ProfileController>(),
  ),
];

final List<NavTab> kProprietorNavTabs = [
  NavTab(
    icon: Icons.dashboard_outlined,
    activeIcon: Icons.dashboard,
    label: 'Dashboard',
    screenBuilder: () => const DashboardScreen(),
    loadController: () =>
        _ensure<SettingsController>(() => SettingsController()),
    disposeController: () => _dispose<SettingsController>(),
  ),
  NavTab(
    icon: Icons.grass_outlined,
    activeIcon: Icons.grass,
    label: 'My Turfs',
    screenBuilder: () => const MyTurfsScreen(),
    loadController: () =>
        _ensure<TurfManagementController>(() => TurfManagementController()),
    disposeController: () => _dispose<TurfManagementController>(),
  ),
  NavTab(
    icon: Icons.calendar_today_outlined,
    activeIcon: Icons.calendar_today,
    label: 'Bookings',
    screenBuilder: () => const BookingsScreen(),
    loadController: () =>
        _ensure<TurfBookingController>(() => TurfBookingController()),
    disposeController: () => _dispose<TurfBookingController>(),
  ),
];

List<NavTab> navTabsForMode(UserMode mode) {
  return mode == UserMode.proprietor ? kProprietorNavTabs : kNavTabs;
}

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
