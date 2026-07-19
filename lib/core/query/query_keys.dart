class QueryKeys {
  QueryKeys._();

  static const featuredTurfs = ['featuredTurfs'];

  /// Prefix `playerDashboard` — invalidate with [playerDashboardPrefix] to refetch all variants.
  static const playerDashboardPrefix = ['playerDashboard'];

  static List<Object?> playerDashboard({double? lat, double? lng}) => [
        ...playerDashboardPrefix,
        lat ?? 'none',
        lng ?? 'none',
      ];

  static List<Object?> turfSearch({
    String? search,
    List<String>? sportTypes,
    List<String>? amenities,
    String? city,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String? sortBy,
  }) =>
      [
        'turfSearch',
        search ?? '',
        ...(sportTypes ?? const <String>[]),
        ...(amenities ?? const <String>[]),
        city ?? '',
        minPrice ?? 0,
        maxPrice ?? 5000,
        minRating ?? 0,
        sortBy ?? 'distance:asc',
      ];

  static const dashboardLeaderboard = ['dashboardLeaderboard', 'cricket'];

  static List<Object> playerLeaderboard(String sport) =>
      ['playerLeaderboard', sport];

  static List<Object> teamLeaderboard(String sport) =>
      ['teamLeaderboard', sport];

  /// Non-paginated memberships snapshot (Match Up, Team Openings CTA state).
  static const myMemberships = ['myMemberships'];

  /// Paginated active memberships (My Teams). Shares prefix with [myMemberships].
  static List<Object?> myMembershipsActive({String? search}) =>
      ['myMemberships', 'active', search ?? ''];

  static List<Object?> matchUpOpponents({
    required String sport,
    String? fromTeamId,
    String? search,
  }) =>
      [
        'matchUpOpponents',
        sport,
        fromTeamId ?? '',
        search ?? '',
      ];

  static List<Object?> matchChallenges({
    required String tab,
    String? teamFilter,
  }) =>
      [
        'matchChallenges',
        tab,
        teamFilter ?? 'all',
      ];

  static List<Object?> matches({
    required String scope,
    String? status,
    String? search,
  }) =>
      [
        'matches',
        scope,
        status ?? 'all',
        search ?? '',
      ];

  static List<Object?> bookings({
    required String tab,
    String? paymentStatus,
  }) =>
      [
        'bookings',
        tab,
        paymentStatus ?? '',
      ];

  static List<Object> teamOpenings(String sport) => ['teamOpenings', sport];

  static List<Object> turfDetail(String turfId) => ['turfDetail', turfId];

  /// [date] must be `yyyy-MM-dd`.
  static List<Object> turfSlots(String turfId, String date) =>
      ['turfSlots', turfId, date];

  static const profile = ['profile'];

  /// Pending / accepted / rejected join-request tabs.
  static List<Object> myJoinRequests(String status) =>
      ['myJoinRequests', status];

  static List<Object> turfReviewStats(String turfId) =>
      ['turfReviewStats', turfId];

  /// Preview and full share the `['turfReviews', turfId]` prefix for invalidation.
  static List<Object> turfReviews(String turfId, {bool preview = false}) =>
      ['turfReviews', turfId, preview ? 'preview' : 'full'];

  static const notifications = ['notifications'];

  static List<Object> teamDetail(String teamId) => ['teamDetail', teamId];

  static List<Object?> teamRoster(String teamId, {String? status}) =>
      ['teamRoster', teamId, status];

  static List<Object> matchChallengeDetail(String matchId) =>
      ['matchChallengeDetail', matchId];

  static List<Object> cricketSession(String matchId) =>
      ['cricketSession', matchId];

  static List<Object> cricketOvers(String matchId) =>
      ['cricketOvers', matchId];

  static List<Object> footballSession(String matchId) =>
      ['footballSession', matchId];

  static List<Object> footballEvents(String matchId) =>
      ['footballEvents', matchId];

  static List<Object> publicProfile(String userId) =>
      ['publicProfile', userId];

  static List<Object> followers(String userId) => ['followers', userId];

  static List<Object> following(String userId) => ['following', userId];

  /// Logged-in user's outgoing follow edge towards [userId].
  static List<Object> followStatus(String userId) => ['followStatus', userId];

  static List<Object> bookingDetail(String bookingId) =>
      ['bookingDetail', bookingId];
}
