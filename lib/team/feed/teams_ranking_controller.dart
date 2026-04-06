import 'package:get/get.dart';

import '../model/team_model.dart';
import '../team_service.dart';

/// Lists teams in API order until a dedicated ranking endpoint exists.
class TeamsRankingController extends GetxController {
  final TeamService _teamService = TeamService();

  final RxBool isLoading = true.obs;
  final RxList<TeamModel> teams = <TeamModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      final page = await _teamService.findMany(
        const TeamFilterQuery(
          status: TeamStatus.active,
          visibility: TeamVisibility.public,
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
