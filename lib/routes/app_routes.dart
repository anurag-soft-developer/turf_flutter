import 'package:flutter_application_1/guards/auth_guard.dart';
import 'package:get/get.dart';
import '../views/auth/login_screen.dart';
import '../views/auth/signup_screen.dart';
import '../views/auth/forgot_password_screen.dart';
import '../views/home/dashboard_screen.dart';
import '../views/profile/profile_screen.dart';
import '../views/settings/settings_screen.dart';
import '../views/turf/turf_list_screen.dart';
import '../views/turf/turf_detail_screen.dart';
import '../views/turf/my_turfs_screen.dart';
import '../views/turf/create_turf_screen.dart';
import '../views/booking/player_bookings_screen.dart';
import '../views/booking/Owner_bookings_screen.dart';
import '../views/splash_screen.dart';
import '../views/access_denied_screen.dart';
import '../bindings/auth_binding.dart';
import '../bindings/profile_binding.dart';
import '../bindings/turf_list_binding.dart';
import '../bindings/turf_detail_binding.dart';
import '../bindings/turf_management_binding.dart';
import '../bindings/create_turf_binding.dart';
import '../bindings/turf_booking_binding.dart';
import '../config/constants.dart';

class AppRoutes {
  static const String splashRoute = '/';

  static final routes = [
    GetPage(name: splashRoute, page: () => const AuthWrapper()),
    GetPage(
      name: AppConstants.routes.accessDenied,
      page: () => const AccessDeniedScreen(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppConstants.routes.login,
      page: () => const LoginScreen(),
      binding: LoginBinding(),
      transition: Transition.cupertino,
      middlewares: [PublicGuard()],
    ),
    GetPage(
      name: AppConstants.routes.signup,
      page: () => const SignupScreen(),
      binding: SignupBinding(),
      transition: Transition.cupertino,
      middlewares: [PublicGuard()],
    ),
    GetPage(
      name: AppConstants.routes.forgotPassword,
      page: () => const ForgotPasswordScreen(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppConstants.routes.dashboard,
      page: () => const DashboardScreen(),
      transition: Transition.cupertino,
      binding: TurfListBinding(),
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: AppConstants.routes.profile,
      page: () => const ProfileScreen(),
      binding: ProfileBinding(),
      transition: Transition.cupertino,
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: AppConstants.routes.settings,
      page: () => const SettingsScreen(),
      transition: Transition.cupertino,
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: AppConstants.routes.turfList,
      page: () => const TurfListScreen(),
      binding: TurfListBinding(),
      transition: Transition.cupertino,
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: AppConstants.routes.turfDetail,
      page: () => const TurfDetailScreen(),
      binding: TurfDetailBinding(),
      transition: Transition.cupertino,
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: AppConstants.routes.myTurfs,
      page: () => const MyTurfsScreen(),
      binding: TurfManagementBinding(),
      transition: Transition.cupertino,
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: AppConstants.routes.createTurf,
      page: () => const CreateTurfScreen(),
      binding: CreateTurfBinding(),
      transition: Transition.cupertino,
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: AppConstants.routes.editTurf,
      page: () => const CreateTurfScreen(),
      binding: CreateTurfBinding(),
      transition: Transition.cupertino,
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: AppConstants.routes.myBookings,
      page: () => const PlayerBookingsScreen(),
      binding: TurfBookingBinding(),
      transition: Transition.cupertino,
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: AppConstants.routes.turfBookings,
      page: () => const OwnerBookingsScreen(),
      binding: TurfBookingBinding(),
      transition: Transition.cupertino,
      middlewares: [AuthGuard()],
    ),
  ];
}
