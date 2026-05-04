import 'package:flutter_application_1/core/config/constants.dart';
import 'package:flutter_application_1/core/guards/auth_guard.dart';
import 'package:flutter_application_1/notification/notifications_screen.dart';
import 'package:flutter_application_1/settings/change_password_screen.dart';
import 'package:flutter_application_1/settings/manage_notifications_screen.dart';
import 'package:flutter_application_1/settings/settings_screen.dart';
import 'package:flutter_application_1/settings/two_factor_screen.dart';
import 'package:get/get.dart';

final List<GetPage<dynamic>> settingsRoutes = [
  GetPage(
    name: AppConstants.routes.settings,
    page: () => const SettingsScreen(),
    transition: Transition.cupertino,
    middlewares: [AuthGuard()],
  ),
  GetPage(
    name: AppConstants.routes.notifications,
    page: () => const NotificationsScreen(),
    transition: Transition.cupertino,
    middlewares: [AuthGuard()],
  ),
  GetPage(
    name: AppConstants.routes.manageNotifications,
    page: () => const ManageNotificationsScreen(),
    transition: Transition.cupertino,
    middlewares: [AuthGuard()],
  ),
  GetPage(
    name: AppConstants.routes.changePassword,
    page: () => const ChangePasswordScreen(),
    transition: Transition.cupertino,
    middlewares: [AuthGuard()],
  ),
  GetPage(
    name: AppConstants.routes.twoFactorAuth,
    page: () => const TwoFactorScreen(),
    transition: Transition.cupertino,
    middlewares: [AuthGuard()],
  ),
];
