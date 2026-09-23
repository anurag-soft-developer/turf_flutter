import 'package:get/get.dart';

import '../model/team_match_model.dart';
import '../shared/match_team_filter_controller.dart';

enum MyMatchesTab { all, live, upcoming, others }

/// Ranked or unranked. [all] sends no source filter.
enum MyMatchesTypeFilter { all, ranked, unranked }

/// Tab + team + type filter for the My Matches list. Fetching is owned by flutter_query.
class MyMatchesController extends MatchTeamFilterController {
  final Rx<MyMatchesTab> selectedTab = MyMatchesTab.all.obs;
  final Rx<MyMatchesTypeFilter> typeFilter = MyMatchesTypeFilter.all.obs;

  @override
  void onInit() {
    super.onInit();
    applyTabFromArguments();
  }

  void applyTabFromArguments() {
    final tab = enumTabFromArguments(MyMatchesTab.values);
    if (tab != null) selectedTab.value = tab;
  }

  void switchTab(int index) {
    if (index < 0 || index >= MyMatchesTab.values.length) return;
    final tab = MyMatchesTab.values[index];
    if (selectedTab.value == tab) return;
    selectedTab.value = tab;
  }

  void setTypeFilter(MyMatchesTypeFilter value) {
    if (typeFilter.value == value) return;
    typeFilter.value = value;
  }
}

extension MyMatchesTypeFilterX on MyMatchesTypeFilter {
  /// API `source` query. Null means both ranked and unranked.
  TeamMatchSource? get apiSource => switch (this) {
    MyMatchesTypeFilter.all => null,
    MyMatchesTypeFilter.ranked => TeamMatchSource.ranked,
    MyMatchesTypeFilter.unranked => TeamMatchSource.unranked,
  };

  String get menuLabel => switch (this) {
    MyMatchesTypeFilter.all => 'All',
    MyMatchesTypeFilter.ranked => 'Ranked',
    MyMatchesTypeFilter.unranked => 'Unranked',
  };

  bool get hasSelection => this != MyMatchesTypeFilter.all;
}

extension MyMatchesTabX on MyMatchesTab {
  List<TeamMatchStatus> get apiStatuses => switch (this) {
    MyMatchesTab.live => const [TeamMatchStatus.ongoing],
    MyMatchesTab.upcoming => const [TeamMatchStatus.scheduleFinalized],
    MyMatchesTab.others => const [
      TeamMatchStatus.completed,
      TeamMatchStatus.draw,
      TeamMatchStatus.rejected,
      TeamMatchStatus.cancelled,
      TeamMatchStatus.abandoned,
      TeamMatchStatus.expired,
    ],
    MyMatchesTab.all => const [
      TeamMatchStatus.ongoing,
      TeamMatchStatus.scheduleFinalized,
      TeamMatchStatus.completed,
      TeamMatchStatus.draw,
      TeamMatchStatus.rejected,
      TeamMatchStatus.cancelled,
      TeamMatchStatus.abandoned,
      TeamMatchStatus.expired,
    ],
  };

  String get sort =>
      this == MyMatchesTab.upcoming ? 'createdAt:asc' : 'updatedAt:desc';

  bool isHistoryFor(TeamMatchModel match) {
    if (this == MyMatchesTab.live || this == MyMatchesTab.upcoming) {
      return false;
    }
    if (this == MyMatchesTab.others) return true;
    return switch (match.status) {
      TeamMatchStatus.completed ||
      TeamMatchStatus.draw ||
      TeamMatchStatus.rejected ||
      TeamMatchStatus.cancelled ||
      TeamMatchStatus.abandoned ||
      TeamMatchStatus.expired => true,
      _ => false,
    };
  }
}
