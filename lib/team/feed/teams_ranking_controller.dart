import 'package:get/get.dart';

import '../../components/shared/app_segmented_tabs/segmented_tab_cache_controller.dart';
import '../model/team_leaderboard_model.dart';
import '../model/team_model.dart';
import '../team_service.dart';

class TeamsRankingController extends GetxController
    with SegmentedTabCacheController<TeamSportType, TeamLeaderboardRow> {
  final TeamService _teamService = TeamService();

  final Rx<TeamSportType> selectedSport = TeamSportType.cricket.obs;

  @override
  List<TeamSportType> get tabKeys => TeamSportType.values;

  @override
  void onInit() {
    super.onInit();
    ensureSportLoaded(selectedSport.value);
  }

  void switchSport(TeamSportType sport) {
    if (selectedSport.value == sport) return;
    selectedSport.value = sport;
    ensureSportLoaded(sport);
  }

  SegmentedTabDataState<TeamLeaderboardRow> stateForSport(TeamSportType sport) {
    return tabStateFor(sport);
  }

  Future<void> ensureSportLoaded(TeamSportType sport) async {
    await ensureTabLoaded(sport);
  }

  Future<void> reloadSport(TeamSportType sport) async {
    await ensureTabLoaded(sport, force: true);
  }

  @override
  Future<List<TeamLeaderboardRow>> fetchTabItems(TeamSportType sport) async {
    final page = await _teamService.getLeaderboard(
      TeamLeaderboardQuery(sportType: sport, page: 1, limit: 50),
    );
    return page?.data ?? <TeamLeaderboardRow>[];
  }

  @override
  String mapFetchError(Object error) {
    return 'Failed to load ranked teams';
  }
}
