import 'package:flutter_application_1/bindings/main_screen_wrapper_binding.dart';
import 'package:flutter_application_1/bindings/player_ranking_binding.dart';
import 'package:flutter_application_1/bindings/turf_list_binding.dart';
import 'package:flutter_application_1/core/components/bottom_navigation_panel/main_screen_wrapper.dart';
import 'package:flutter_application_1/core/config/constants.dart';
import 'package:flutter_application_1/core/guards/auth_guard.dart';
import 'package:flutter_application_1/core/views/access_denied_screen.dart';
import 'package:flutter_application_1/core/views/splash_screen.dart';
import 'package:flutter_application_1/dashboard/dashboard_screen.dart';
import 'package:flutter_application_1/rankings/player_ranking_screen.dart';
import 'package:get/get.dart';

import 'about_help_legal_routes.dart';
import 'auth_routes.dart';
import 'booking_routes.dart';
import 'match_up_routes.dart';
import 'profile_routes.dart';
import 'settings_routes.dart';
import 'team_routes.dart';
import 'turf_routes.dart';

class AppRoutes {
  static const String splashRoute = '/';
  static const String mainRoute = '/main';

  static final routes = [
    GetPage(name: splashRoute, page: () => const AuthWrapper()),
    GetPage(
      name: AppConstants.routes.accessDenied,
      page: () => const AccessDeniedScreen(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: mainRoute,
      page: () => const MainScreenWrapper(),
      binding: NavigationBinding(),
      transition: Transition.cupertino,
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: AppConstants.routes.dashboard,
      page: () => const DashboardScreen(),
      transition: Transition.cupertino,
      binding: TurfListBinding(),
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: AppConstants.routes.playerRanking,
      page: () => const PlayerRankingScreen(),
      binding: PlayerRankingBinding(),
      transition: Transition.cupertino,
      middlewares: [AuthGuard()],
    ),
    ...authRoutes,
    ...profileRoutes,
    ...settingsRoutes,
    ...turfRoutes,
    ...bookingRoutes,
    ...teamRoutes,
    ...aboutHelpLegalRoutes,
    ...matchUpRoutes,
  ];
}
