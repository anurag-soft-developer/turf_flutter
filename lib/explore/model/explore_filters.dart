import '../../match_up/matches/match_list_filters.dart';
import '../../team/model/team_model.dart';

enum ExplorePostKind {
  all,
  media,
  opening;

  String get apiValue => name;

  String get label => switch (this) {
        ExplorePostKind.all => 'All',
        ExplorePostKind.media => 'Media',
        ExplorePostKind.opening => 'Opening',
      };
}

class ExploreFilters {
  const ExploreFilters({
    this.matchFilters = MatchListFilters.all,
    this.sportType,
    this.postKind = ExplorePostKind.all,
  });

  static const all = ExploreFilters();

  final MatchListFilters matchFilters;
  final TeamSportType? sportType;
  final ExplorePostKind postKind;

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
        postKind.apiValue,
      ];

  ExploreFilters copyWith({
    MatchListFilters? matchFilters,
    TeamSportType? sportType,
    bool clearSportType = false,
    ExplorePostKind? postKind,
  }) {
    return ExploreFilters(
      matchFilters: matchFilters ?? this.matchFilters,
      sportType: clearSportType ? null : sportType ?? this.sportType,
      postKind: postKind ?? this.postKind,
    );
  }
}
