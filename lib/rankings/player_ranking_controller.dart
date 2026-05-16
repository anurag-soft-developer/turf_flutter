import 'package:get/get.dart';

import '../components/shared/app_segmented_tabs/segmented_tab_cache_controller.dart';
import '../core/models/user/player_stats_models.dart';
import '../core/services/user_service.dart';
import 'model/player_leaderboard_model.dart';

class PlayerRankingController extends GetxController
    with SegmentedTabCacheController<SportType, PlayerLeaderboardRow> {
  final UserService _userService = UserService();

  final Rx<SportType> selectedSport = SportType.cricket.obs;

  @override
  List<SportType> get tabKeys => SportType.values;

  @override
  void onInit() {
    super.onInit();
    ensureSportLoaded(selectedSport.value);
  }

  void switchSport(SportType sport) {
    if (selectedSport.value == sport) return;
    selectedSport.value = sport;
    ensureSportLoaded(sport);
  }

  SegmentedTabDataState<PlayerLeaderboardRow> stateForSport(SportType sport) {
    return tabStateFor(sport);
  }

  Future<void> ensureSportLoaded(SportType sport) async {
    await ensureTabLoaded(sport);
  }

  Future<void> reloadSport(SportType sport) async {
    await ensureTabLoaded(sport, force: true);
  }

  @override
  Future<List<PlayerLeaderboardRow>> fetchTabItems(SportType sport) async {
    final page = await _userService.getLeaderboard(
      PlayerLeaderboardQuery(sportType: sport, page: 1, limit: 50),
    );
    return page?.data ?? <PlayerLeaderboardRow>[];
  }

  @override
  String mapFetchError(Object error) {
    return 'Failed to load ranked players';
  }
}
