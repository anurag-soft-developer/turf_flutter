import 'package:get/get.dart';

import '../core/models/user/player_stats_models.dart';
import '../team/model/team_model.dart';

enum RankTab { teams, players }

/// UI-only rank state. List fetching is owned by flutter_query on list widgets.
class RankController extends GetxController {
  final Rx<RankTab> selectedTab = RankTab.teams.obs;
  final Rx<TeamSportType> selectedSport = TeamSportType.cricket.obs;

  SportType get playerSport => SportType.values.firstWhere(
        (s) => s.name == selectedSport.value.name,
        orElse: () => SportType.cricket,
      );

  void switchTab(RankTab tab) {
    if (selectedTab.value == tab) return;
    selectedTab.value = tab;
  }

  void switchSport(TeamSportType sport) {
    if (selectedSport.value == sport) return;
    selectedSport.value = sport;
  }
}
