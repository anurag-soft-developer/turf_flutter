import '../../match_up/matches/match_list_filters.dart';
import '../../team/model/team_model.dart';

class ExploreFilters {
  const ExploreFilters({
    this.matchFilters = MatchListFilters.all,
    this.sportType,
  });

  static const all = ExploreFilters();

  final MatchListFilters matchFilters;
  final TeamSportType? sportType;

  String get matchScope =>
      matchFilters.type == MatchTypeFilter.my ? 'mine' : 'all';

  String get matchStatus => switch (matchFilters.status) {
        MatchStatusFilter.live => 'live',
        MatchStatusFilter.upcoming => 'upcoming',
        MatchStatusFilter.completed => 'completed',
        MatchStatusFilter.all => 'all',
      };

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{};
    if (matchFilters.type != MatchTypeFilter.all) {
      params['matchScope'] = matchScope;
    }
    if (matchFilters.status != MatchStatusFilter.all) {
      params['matchStatus'] = matchStatus;
    }

    if (sportType != null) {
      params['sportType'] = sportType!.name;
    }

    return params;
  }

  List<String> toQueryKeyParts() => [
        matchScope,
        matchStatus,
        sportType?.name ?? '',
      ];

  ExploreFilters copyWith({
    MatchListFilters? matchFilters,
    TeamSportType? sportType,
    bool clearSportType = false,
  }) {
    return ExploreFilters(
      matchFilters: matchFilters ?? this.matchFilters,
      sportType: clearSportType ? null : sportType ?? this.sportType,
    );
  }
}
