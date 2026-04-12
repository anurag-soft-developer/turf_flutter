import 'package:get/get.dart';

import '../model/team_model.dart';
import '../team_service.dart';

class TeamsRankingController extends GetxController {
  final TeamService _teamService = TeamService();

  final RxBool isLoading = true.obs;
  final RxList<TeamModel> teams = <TeamModel>[].obs;
  final Rx<TeamSportType> selectedSport = TeamSportType.cricket.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  void switchSport(TeamSportType sport) {
    if (selectedSport.value == sport) return;
    selectedSport.value = sport;
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      final page = await _teamService.findMany(
        TeamFilterQuery(
          status: TeamStatus.active,
          visibility: TeamVisibility.public,
          sportType: selectedSport.value,
          page: 1,
          limit: 50,
        ),
      );
      teams.assignAll(page?.data ?? []);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> reload() async {
    await load();
  }
}
