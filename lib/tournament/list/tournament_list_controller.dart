import 'package:get/get.dart';

import '../../core/routes/route_query.dart';
import '../../team/model/team_model.dart';

enum TournamentListTab { all, live, upcoming, others }

class TournamentListController extends GetxController {
  final Rx<TournamentListTab> selectedTab = TournamentListTab.all.obs;
  final Rxn<TeamSportType> sportFilter = Rxn<TeamSportType>();

  @override
  void onInit() {
    super.onInit();
    applySportFromRoute();
  }

  void applySportFromRoute() {
    final sport = optionalTeamSportFromRoute();
    if (sport != null) sportFilter.value = sport;
  }

  void switchTab(int index) {
    if (index < 0 || index >= TournamentListTab.values.length) return;
    final tab = TournamentListTab.values[index];
    if (selectedTab.value == tab) return;
    selectedTab.value = tab;
  }

  void setSportFilter(TeamSportType? value) {
    if (sportFilter.value == value) return;
    sportFilter.value = value;
  }
}

extension TournamentListTabX on TournamentListTab {
  /// Backend `status` query (comma-separated when multiple). Null = all tab.
  List<String>? get apiStatuses => switch (this) {
    TournamentListTab.live => const ['ongoing'],
    TournamentListTab.upcoming => const ['inviting', 'scheduled', 'draft'],
    TournamentListTab.others => const ['completed', 'cancelled'],
    TournamentListTab.all => null,
  };

  String get emptyTitle => switch (this) {
    TournamentListTab.all => 'No tournaments',
    TournamentListTab.live => 'No live tournaments',
    TournamentListTab.upcoming => 'No upcoming tournaments',
    TournamentListTab.others => 'No past tournaments',
  };

  String get emptySubtitle => switch (this) {
    TournamentListTab.all =>
      'Tournaments you organize or have entered will show here.',
    TournamentListTab.live =>
      'Tournaments with matches in progress will appear here.',
    TournamentListTab.upcoming =>
      'Open registration and scheduled tournaments show up here.',
    TournamentListTab.others =>
      'Completed and cancelled tournaments appear here.',
  };
}
