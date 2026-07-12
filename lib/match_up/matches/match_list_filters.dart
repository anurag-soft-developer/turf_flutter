import '../model/team_match_model.dart';

enum MatchTypeFilter { all, my }

enum MatchStatusFilter { all, live, upcoming, completed }

class MatchListFilters {
  const MatchListFilters({
    this.type = MatchTypeFilter.all,
    this.status = MatchStatusFilter.all,
  });

  static const all = MatchListFilters();

  final MatchTypeFilter type;
  final MatchStatusFilter status;

  NegotiationListScope get scope => type == MatchTypeFilter.my
      ? NegotiationListScope.mine
      : NegotiationListScope.all;

  String get typeLabel => switch (type) {
    MatchTypeFilter.all => 'All',
    MatchTypeFilter.my => 'My',
  };

  String get statusLabel => switch (status) {
    MatchStatusFilter.all => 'All',
    MatchStatusFilter.live => 'Live',
    MatchStatusFilter.upcoming => 'Upcoming',
    MatchStatusFilter.completed => 'Completed',
  };

  bool get hasTypeSelection => type != MatchTypeFilter.all;

  bool get hasStatusSelection => status != MatchStatusFilter.all;

  /// Statuses sent to `GET /matchmaking/requests`.
  List<TeamMatchStatus> get apiStatuses => switch (status) {
    MatchStatusFilter.all => const [
      TeamMatchStatus.scheduleFinalized,
      TeamMatchStatus.ongoing,
      TeamMatchStatus.completed,
      TeamMatchStatus.draw,
    ],
    MatchStatusFilter.live => const [TeamMatchStatus.ongoing],
    MatchStatusFilter.upcoming => const [TeamMatchStatus.scheduleFinalized],
    MatchStatusFilter.completed => const [
      TeamMatchStatus.completed,
      TeamMatchStatus.draw,
    ],
  };

  MatchListFilters copyWith({
    MatchTypeFilter? type,
    MatchStatusFilter? status,
  }) {
    return MatchListFilters(
      type: type ?? this.type,
      status: status ?? this.status,
    );
  }

  MatchListFilters withType(MatchTypeFilter value) => copyWith(type: value);

  MatchListFilters withTypeAll() => copyWith(type: MatchTypeFilter.all);

  MatchListFilters withStatus(MatchStatusFilter value) =>
      copyWith(status: value);

  MatchListFilters withStatusAll() =>
      copyWith(status: MatchStatusFilter.all);

  List<String> toQueryKeyParts() => [type.name, status.name];
}
