import 'package:flutter_application_1/bindings/tournament_list_binding.dart';
import 'package:flutter_application_1/core/config/constants.dart';
import 'package:flutter_application_1/core/guards/auth_guard.dart';
import 'package:flutter_application_1/tournament/create/create_tournament_controller.dart';
import 'package:flutter_application_1/tournament/create/create_tournament_screen.dart';
import 'package:flutter_application_1/tournament/create/edit_tournament_screen.dart';
import 'package:flutter_application_1/tournament/detail/tournament_detail_controller.dart';
import 'package:flutter_application_1/tournament/detail/tournament_detail_screen.dart';
import 'package:flutter_application_1/tournament/detail/tournament_entries_screen.dart';
import 'package:flutter_application_1/tournament/detail/tournament_organizers_screen.dart';
import 'package:flutter_application_1/tournament/list/tournament_list_screen.dart';
import 'package:get/get.dart';

final List<GetPage<dynamic>> tournamentRoutes = [
  GetPage(
    name: AppConstants.routes.tournaments,
    page: () => const TournamentListScreen(),
    binding: TournamentListBinding(),
    transition: Transition.cupertino,
    middlewares: [AuthGuard()],
  ),
  GetPage(
    name: AppConstants.routes.createTournament,
    page: () => const CreateTournamentScreen(),
    binding: BindingsBuilder(() {
      Get.lazyPut(CreateTournamentController.new);
    }),
    transition: Transition.cupertino,
    middlewares: [AuthGuard()],
  ),
  GetPage(
    name: AppConstants.routes.editTournament(),
    page: () => const EditTournamentScreen(),
    transition: Transition.cupertino,
    middlewares: [AuthGuard()],
  ),
  GetPage(
    name: AppConstants.routes.tournamentTeamEntries(),
    page: () => const TournamentEntriesScreen(),
    binding: BindingsBuilder(() {
      if (!Get.isRegistered<TournamentDetailController>()) {
        Get.lazyPut(TournamentDetailController.new);
      }
    }),
    transition: Transition.cupertino,
    middlewares: [AuthGuard()],
  ),
  GetPage(
    name: AppConstants.routes.tournamentOrganizers(),
    page: () => const TournamentOrganizersScreen(),
    binding: BindingsBuilder(() {
      if (!Get.isRegistered<TournamentDetailController>()) {
        Get.lazyPut(TournamentDetailController.new);
      }
    }),
    transition: Transition.cupertino,
    middlewares: [AuthGuard()],
  ),
  GetPage(
    name: AppConstants.routes.tournamentDetail(),
    page: () => const TournamentDetailScreen(),
    binding: BindingsBuilder(() {
      Get.lazyPut(TournamentDetailController.new);
    }),
    transition: Transition.cupertino,
    middlewares: [AuthGuard()],
  ),
];
