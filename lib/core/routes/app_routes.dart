import 'package:flutter_application_1/core/guards/auth_guard.dart';
import 'package:get/get.dart';
import '../auth/login/login_screen.dart';
import '../auth/signup/signup_screen.dart';
import '../auth/forgot_password/forgot_password_screen.dart';
import '../../dashboard/dashboard_screen.dart';
import '../../profile/profile_screen.dart';
import '../../settings/settings_screen.dart';
import '../../notification/notifications_screen.dart';
import '../../settings/manage_notifications_screen.dart';
import '../../settings/change_password_screen.dart';
import '../../settings/two_factor_screen.dart';
import '../../turf/feed/turf_list_screen.dart';
import '../../turf/details/turf_detail_screen.dart';
import '../../turf/my_turves/my_turfs_screen.dart';
import '../../turf/my_turves/manage_turf_screen.dart';
import '../../turf/create/create_turf_screen.dart';
import '../../turf_booking/bookings_screen.dart';
import '../../components/booking/booking_details_screen.dart';
import '../../components/booking/booking_ticket_screen.dart';
import '../views/splash_screen.dart';
import '../views/access_denied_screen.dart';
import '../binding/auth_binding.dart';
import '../../bindings/profile_binding.dart';
import '../../bindings/edit_profile_binding.dart';
import '../../profile/edit_profile_screen.dart';
import '../../bindings/turf_list_binding.dart';
import '../../bindings/turf_detail_binding.dart';
import '../../bindings/manage_turf_binding.dart';
import '../../bindings/turf_reviews_full_binding.dart';
import '../../turf/reviews/turf_reviews_full_screen.dart';
import '../../bindings/turf_management_binding.dart';
import '../../bindings/create_turf_binding.dart';
import '../../bindings/turf_booking_binding.dart';
import '../../bindings/team_player_bindings.dart';
import '../../bindings/match_challenges_binding.dart';
import '../../bindings/match_up_binding.dart';
import '../../bindings/player_ranking_binding.dart';
import '../../bindings/main_screen_wrapper_binding.dart';
import '../../team/add/add_team_screen.dart';
import '../../team/my_teams/my_teams_screen.dart';
import '../../team/members/player_profile_screen.dart';
import '../../team/details/team_detail_screen.dart';
import '../../team/management/team_join_requests_screen.dart';
import '../../team/management/team_roster_manage_screen.dart';
import '../../team/feed/teams_ranking_screen.dart';
import '../../team/join_status/my_join_requests_screen.dart';
import '../../team/openings/team_openings_screen.dart';
import '../../match_up/match_challenges/match_challenges_screen.dart';
import '../../match_up/match_up_screen.dart';
import '../../rankings/player_ranking_screen.dart';
import '../components/bottom_navigation_panel/main_screen_wrapper.dart';
import '../config/constants.dart';
import 'about_help_legal_routes.dart';

class AppRoutes {
  static const String splashRoute = '/';
  static const String mainRoute = '/main';

  static final routes = [
    ...aboutHelpLegalRoutes,
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
      name: AppConstants.routes.matchUp,
      page: () => const MatchUpScreen(),
      binding: MatchUpBinding(),
      transition: Transition.cupertino,
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: AppConstants.routes.matchUpChallenges,
      page: () => const MatchChallengesScreen(),
      binding: MatchChallengesBinding(),
      transition: Transition.cupertino,
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: AppConstants.routes.playerRanking,
      page: () => const PlayerRankingScreen(),
      binding: PlayerRankingBinding(),
      transition: Transition.cupertino,
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
      name: AppConstants.routes.editProfile,
      page: () => const EditProfileScreen(),
      binding: EditProfileBinding(),
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
      name: AppConstants.routes.manageTurf,
      page: () => const ManageTurfScreen(),
      binding: ManageTurfBinding(),
      transition: Transition.cupertino,
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: AppConstants.routes.turfReviews,
      page: () => const TurfReviewsFullScreen(),
      binding: TurfReviewsFullBinding(),
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
      page: () => const BookingsScreen(),
      binding: TurfBookingBinding(),
      transition: Transition.cupertino,
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: AppConstants.routes.bookingDetails,
      page: () => const BookingDetailsScreen(),
      transition: Transition.cupertino,
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: AppConstants.routes.bookingTicket,
      page: () => const BookingTicketScreen(),
      transition: Transition.cupertino,
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: AppConstants.routes.myTeams,
      page: () => const MyTeamsScreen(),
      binding: MyTeamsBinding(),
      transition: Transition.cupertino,
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: AppConstants.routes.myTeam,
      page: () => const TeamDetailScreen(),
      binding: MyTeamBinding(),
      transition: Transition.cupertino,
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: AppConstants.routes.teamsRanking,
      page: () => const TeamsRankingScreen(),
      binding: TeamsRankingBinding(),
      transition: Transition.cupertino,
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: AppConstants.routes.teamOpenings,
      page: () => const TeamOpeningsScreen(),
      binding: TeamOpeningsBinding(),
      transition: Transition.cupertino,
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: AppConstants.routes.myJoinRequests,
      page: () => const MyJoinRequestsScreen(),
      binding: MyJoinRequestsBinding(),
      transition: Transition.cupertino,
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: AppConstants.routes.addTeam,
      page: () => const AddTeamScreen(),
      binding: AddTeamBinding(),
      transition: Transition.cupertino,
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: AppConstants.routes.editTeam,
      page: () => const AddTeamScreen(),
      binding: AddTeamBinding(),
      transition: Transition.cupertino,
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: AppConstants.routes.teamProfile,
      page: () => const TeamDetailScreen(),
      binding: TeamProfileBinding(),
      transition: Transition.cupertino,
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: AppConstants.routes.teamJoinRequests,
      page: () => const TeamJoinRequestsScreen(),
      binding: TeamJoinRequestsBinding(),
      transition: Transition.cupertino,
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: AppConstants.routes.teamRosterManage,
      page: () => const TeamRosterManageScreen(),
      binding: TeamRosterManageBinding(),
      transition: Transition.cupertino,
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: AppConstants.routes.teamMemberProfile,
      page: () => const PlayerProfileScreen(),
      transition: Transition.cupertino,
      middlewares: [AuthGuard()],
    ),
    // GetPage(
    //   name: AppConstants.routes.turfBookings,
    //   page: () => const OwnerBookingsScreen(),
    //   binding: TurfBookingBinding(),
    //   transition: Transition.cupertino,
    //   middlewares: [AuthGuard()],
    // ),
  ];
}
