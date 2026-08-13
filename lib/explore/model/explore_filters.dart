import '../../match_up/matches/match_list_filters.dart';
import '../../team/model/team_model.dart';

class ExploreFilters {
  const ExploreFilters({
    this.matchFilters = MatchListFilters.all,
    this.sportType,
    this.lookingForMembers,
    this.teamOpenForMatch,
  });

  static const all = ExploreFilters();

  final MatchListFilters matchFilters;
  final TeamSportType? sportType;
  final bool? lookingForMembers;
  final bool? teamOpenForMatch;

  String get matchScope =>
      matchFilters.type == MatchTypeFilter.my ? 'mine' : 'all';

  String get matchStatus => switch (matchFilters.status) {
        MatchStatusFilter.live => 'live',
        MatchStatusFilter.upcoming => 'upcoming',
        MatchStatusFilter.completed => 'completed',
        MatchStatusFilter.all => 'all',
      };

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{
      'matchScope': matchScope,
      'matchStatus': matchStatus,
    };

    if (sportType != null) {
      params['sportType'] = sportType!.name;
    }
    if (lookingForMembers != null) {
      params['lookingForMembers'] = lookingForMembers! ? 'true' : 'false';
    }
    if (teamOpenForMatch != null) {
      params['teamOpenForMatch'] = teamOpenForMatch! ? 'true' : 'false';
    }

    return params;
  }

  List<String> toQueryKeyParts() => [
        matchScope,
        matchStatus,
        sportType?.name ?? '',
        lookingForMembers?.toString() ?? '',
        teamOpenForMatch?.toString() ?? '',
      ];

  ExploreFilters copyWith({
    MatchListFilters? matchFilters,
    TeamSportType? sportType,
    bool? lookingForMembers,
    bool? teamOpenForMatch,
    bool clearSportType = false,
    bool clearLookingForMembers = false,
    bool clearTeamOpenForMatch = false,
  }) {
    return ExploreFilters(
      matchFilters: matchFilters ?? this.matchFilters,
      sportType: clearSportType ? null : sportType ?? this.sportType,
      lookingForMembers: clearLookingForMembers
          ? null
          : lookingForMembers ?? this.lookingForMembers,
      teamOpenForMatch: clearTeamOpenForMatch
          ? null
          : teamOpenForMatch ?? this.teamOpenForMatch,
    );
  }
}
