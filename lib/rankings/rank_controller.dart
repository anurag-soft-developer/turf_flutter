import 'package:get/get.dart';

import '../core/models/user/player_stats_models.dart';
import '../team/feed/teams_ranking_controller.dart';
import '../team/model/team_model.dart';
import 'player_ranking_controller.dart';

enum RankTab { teams, players }

class RankController extends GetxController {
  final Rx<RankTab> selectedTab = RankTab.teams.obs;
  final Rx<TeamSportType> selectedSport = TeamSportType.cricket.obs;

  TeamsRankingController get _teams => Get.find<TeamsRankingController>();
  PlayerRankingController get _players => Get.find<PlayerRankingController>();

  SportType get playerSport => SportType.values.firstWhere(
        (s) => s.name == selectedSport.value.name,
        orElse: () => SportType.cricket,
      );

  @override
  void onInit() {
    super.onInit();
    _syncSportToChildren(selectedSport.value);
    ensureActiveTabLoaded();
  }

  void switchTab(RankTab tab) {
    if (selectedTab.value == tab) return;
    selectedTab.value = tab;
    ensureActiveTabLoaded();
  }

  void switchSport(TeamSportType sport) {
    if (selectedSport.value == sport) return;
    selectedSport.value = sport;
    _syncSportToChildren(sport);
    ensureActiveTabLoaded();
  }

  Future<void> ensureActiveTabLoaded() async {
    if (selectedTab.value == RankTab.teams) {
      await _teams.ensureSportLoaded(selectedSport.value);
    } else {
      await _players.ensureSportLoaded(playerSport);
    }
  }

  void _syncSportToChildren(TeamSportType sport) {
    _teams.selectedSport.value = sport;
    final playerSportType = SportType.values.firstWhere(
      (s) => s.name == sport.name,
      orElse: () => SportType.cricket,
    );
    _players.selectedSport.value = playerSportType;
  }
}
