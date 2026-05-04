import 'package:flutter_application_1/bindings/team_player_bindings.dart';
import 'package:flutter_application_1/core/config/constants.dart';
import 'package:flutter_application_1/core/guards/auth_guard.dart';
import 'package:flutter_application_1/team/add/add_team_screen.dart';
import 'package:flutter_application_1/team/details/team_detail_screen.dart';
import 'package:flutter_application_1/team/feed/teams_ranking_screen.dart';
import 'package:flutter_application_1/team/join_status/my_join_requests_screen.dart';
import 'package:flutter_application_1/team/management/team_join_requests_screen.dart';
import 'package:flutter_application_1/team/management/team_roster_manage_screen.dart';
import 'package:flutter_application_1/team/members/player_profile_screen.dart';
import 'package:flutter_application_1/team/my_teams/my_teams_screen.dart';
import 'package:flutter_application_1/team/openings/team_openings_screen.dart';
import 'package:get/get.dart';

final List<GetPage<dynamic>> teamRoutes = [
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
];
