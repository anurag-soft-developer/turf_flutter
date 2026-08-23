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

  static const turfSearchPrefix = ['turfSearch'];

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
        ...turfSearchPrefix,
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

  static const playerLeaderboardPrefix = ['playerLeaderboard'];

  static List<Object> playerLeaderboard(String sport) =>
      [...playerLeaderboardPrefix, sport];

  static const teamLeaderboardPrefix = ['teamLeaderboard'];

  static List<Object> teamLeaderboard(String sport) =>
      [...teamLeaderboardPrefix, sport];

  /// Non-paginated memberships snapshot (Match Up, Team Openings CTA state).
  static const myMemberships = ['myMemberships'];

  /// Paginated active memberships (My Teams). Shares prefix with [myMemberships].
  static List<Object?> myMembershipsActive({String? search}) =>
      [...myMemberships, 'active', search ?? ''];

  static const matchUpOpponentsPrefix = ['matchUpOpponents'];

  static List<Object?> matchUpOpponents({
    required String sport,
    String? fromTeamId,
    String? search,
  }) =>
      [
        ...matchUpOpponentsPrefix,
        sport,
        fromTeamId ?? '',
        search ?? '',
      ];

  static const matchChallengesPrefix = ['matchChallenges'];

  static List<Object?> matchChallenges({
    required String tab,
    String? teamFilter,
  }) =>
      [
        ...matchChallengesPrefix,
        tab,
        teamFilter ?? 'all',
      ];

  static const matchesPrefix = ['matches'];

  static List<Object?> matches({
    required String scope,
    String? status,
    String? search,
  }) =>
      [
        ...matchesPrefix,
        scope,
        status ?? 'all',
        search ?? '',
      ];

  static const explorePrefix = ['explore'];

  static List<Object?> explore({
    required String mode,
    required String category,
    String? q,
    List<String>? filterParts,
    double? lat,
    double? lng,
  }) =>
      [
        ...explorePrefix,
        mode,
        category,
        q ?? '',
        ...(filterParts ?? const <String>[]),
        lat ?? 'none',
        lng ?? 'none',
      ];

  static const bookingsPrefix = ['bookings'];

  static List<Object?> bookings({
    required String tab,
    String? paymentStatus,
  }) =>
      [
        ...bookingsPrefix,
        tab,
        paymentStatus ?? '',
      ];

  static const teamOpeningsPrefix = ['teamOpenings'];

  static List<Object> teamOpenings(String sport) =>
      [...teamOpeningsPrefix, sport];

  static const turfDetailPrefix = ['turfDetail'];

  static List<Object> turfDetail(String turfId) =>
      [...turfDetailPrefix, turfId];

  static const turfSlotsPrefix = ['turfSlots'];

  /// [date] must be `yyyy-MM-dd`.
  static List<Object> turfSlots(String turfId, String date) =>
      [...turfSlotsPrefix, turfId, date];

  static const profile = ['profile'];

  static const myJoinRequestsPrefix = ['myJoinRequests'];

  /// Pending / accepted / rejected join-request tabs.
  static List<Object> myJoinRequests(String status) =>
      [...myJoinRequestsPrefix, status];

  static const myInvitationsPrefix = ['myInvitations'];

  static List<Object> myInvitations(String status) =>
      [...myInvitationsPrefix, status];

  static const teamInvitesPrefix = ['teamInvites'];

  static List<Object?> teamInvites(String teamId, {String? status}) =>
      [...teamInvitesPrefix, teamId, status];

  static const turfReviewStatsPrefix = ['turfReviewStats'];

  static List<Object> turfReviewStats(String turfId) =>
      [...turfReviewStatsPrefix, turfId];

  static const turfReviewsPrefix = ['turfReviews'];

  /// Preview and full share the `['turfReviews', turfId]` prefix for invalidation.
  static List<Object> turfReviews(String turfId, {bool preview = false}) =>
      [...turfReviewsPrefix, turfId, preview ? 'preview' : 'full'];

  static const notifications = ['notifications'];

  static const teamDetailPrefix = ['teamDetail'];

  static List<Object> teamDetail(String teamId) =>
      [...teamDetailPrefix, teamId];

  static const teamRosterPrefix = ['teamRoster'];

  static List<Object?> teamRoster(String teamId, {String? status}) =>
      [...teamRosterPrefix, teamId, status];

  static const matchChallengeDetailPrefix = ['matchChallengeDetail'];

  static List<Object> matchChallengeDetail(String matchId) =>
      [...matchChallengeDetailPrefix, matchId];

  static const explorePostPrefix = ['explorePost'];

  static List<Object> explorePost(String postId) =>
      [...explorePostPrefix, postId];

  static const cricketSessionPrefix = ['cricketSession'];

  static List<Object> cricketSession(String matchId) =>
      [...cricketSessionPrefix, matchId];

  static const cricketOversPrefix = ['cricketOvers'];

  static List<Object> cricketOvers(String matchId) =>
      [...cricketOversPrefix, matchId];

  static const footballSessionPrefix = ['footballSession'];

  static List<Object> footballSession(String matchId) =>
      [...footballSessionPrefix, matchId];

  static const footballEventsPrefix = ['footballEvents'];

  static List<Object> footballEvents(String matchId) =>
      [...footballEventsPrefix, matchId];

  static const publicProfilePrefix = ['publicProfile'];

  static List<Object> publicProfile(String userId) =>
      [...publicProfilePrefix, userId];

  static const followersPrefix = ['followers'];

  static List<Object> followers(String userId) =>
      [...followersPrefix, userId];

  static const followingPrefix = ['following'];

  static List<Object> following(String userId) =>
      [...followingPrefix, userId];

  static const teamFollowersPrefix = ['teamFollowers'];

  static List<Object> teamFollowers(String teamId) =>
      [...teamFollowersPrefix, teamId];

  static const followStatusPrefix = ['followStatus'];

  /// Logged-in user's outgoing follow edge towards a user or team.
  static List<Object> followStatus(
    String recipientId, {
    String recipientType = 'User',
  }) =>
      [...followStatusPrefix, recipientType, recipientId];

  static const bookingDetailPrefix = ['bookingDetail'];

  static List<Object> bookingDetail(String bookingId) =>
      [...bookingDetailPrefix, bookingId];
}
