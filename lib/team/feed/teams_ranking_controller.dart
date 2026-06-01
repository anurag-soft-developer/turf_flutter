import 'package:get/get.dart';

import '../../components/shared/app_segmented_tabs/segmented_tab_cache_controller.dart';
import '../model/team_leaderboard_model.dart';
import '../model/team_model.dart';
import '../team_service.dart';

class TeamsRankingController extends GetxController
    with SegmentedTabCacheController<TeamSportType, TeamLeaderboardRow> {
  static const int _pageSize = 20;

  final TeamService _teamService = TeamService();

  final Rx<TeamSportType> selectedSport = TeamSportType.cricket.obs;

  @override
  List<TeamSportType> get tabKeys => TeamSportType.values;

  @override
  bool get paginatedTabs => true;

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

  Future<void> loadMore(TeamSportType sport) => loadMoreTab(sport);

  @override
  Future<List<TeamLeaderboardRow>> fetchTabItems(TeamSportType sport) async {
    return (await fetchTabPage(sport, 1)).items;
  }

  @override
  Future<SegmentedTabPageResult<TeamLeaderboardRow>> fetchTabPage(
    TeamSportType sport,
    int page,
  ) async {
    final result = await _teamService.getLeaderboard(
      TeamLeaderboardQuery(sportType: sport, page: page, limit: _pageSize),
    );
    return SegmentedTabPageResult(
      items: result?.data ?? <TeamLeaderboardRow>[],
      page: result?.page ?? page,
      hasMore: result?.hasNextPage ?? false,
    );
  }

  @override
  String mapFetchError(Object error) {
    return 'Failed to load ranked teams';
  }
}
