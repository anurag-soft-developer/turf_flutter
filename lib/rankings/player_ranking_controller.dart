import 'package:get/get.dart';

import '../components/shared/app_segmented_tabs/segmented_tab_cache_controller.dart';
import '../core/models/user/player_stats_models.dart';
import '../core/services/user_service.dart';
import 'model/player_leaderboard_model.dart';

class PlayerRankingController extends GetxController
    with SegmentedTabCacheController<SportType, PlayerLeaderboardRow> {
  static const int _pageSize = 20;

  final UserService _userService = UserService();

  final Rx<SportType> selectedSport = SportType.cricket.obs;

  @override
  List<SportType> get tabKeys => SportType.values;

  @override
  bool get paginatedTabs => true;

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

  Future<void> loadMore(SportType sport) => loadMoreTab(sport);

  @override
  Future<List<PlayerLeaderboardRow>> fetchTabItems(SportType sport) async {
    return (await fetchTabPage(sport, 1)).items;
  }

  @override
  Future<SegmentedTabPageResult<PlayerLeaderboardRow>> fetchTabPage(
    SportType sport,
    int page,
  ) async {
    final result = await _userService.getLeaderboard(
      PlayerLeaderboardQuery(sportType: sport, page: page, limit: _pageSize),
    );
    return SegmentedTabPageResult(
      items: result?.data ?? <PlayerLeaderboardRow>[],
      page: result?.page ?? page,
      hasMore: result?.hasNextPage ?? false,
    );
  }

  @override
  String mapFetchError(Object error) {
    return 'Failed to load ranked players';
  }
}
