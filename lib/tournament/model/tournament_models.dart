import '../../match_up/model/team_match_model.dart';

String? mongoId(dynamic value) {
  if (value == null) return null;
  if (value is String && value.isNotEmpty) return value;
  if (value is Map) {
    final id = value['_id'] ?? value['id'];
    if (id != null) return id.toString();
  }
  return null;
}

String displayName(dynamic value, {String fallback = 'Team'}) {
  if (value is Map) {
    final name = value['name']?.toString();
    if (name != null && name.isNotEmpty) return name;
  }
  return fallback;
}

class TournamentOrganizerRef {
  final String id;
  final String? fullName;
  final String? avatar;

  const TournamentOrganizerRef({required this.id, this.fullName, this.avatar});

  String get displayName {
    final name = fullName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return 'Organizer';
  }
}

class TournamentModel {
  final String id;
  final String name;
  final String organizerUserId;
  final List<TournamentOrganizerRef> organizers;
  final String sportType;
  final String format;
  final String status;
  final int? maxTeams;
  final DateTime? rosterLockedAt;
  final int maxOvers;
  final int? advanceCount;
  final List<String> coverImages;
  final String? description;
  final String? venueName;
  final String? category;
  final String? ballType;
  final String? pitchType;
  final String? matchType;
  final int? durationMinutes;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? registrationDeadline;
  final bool isPublic;

  const TournamentModel({
    required this.id,
    required this.name,
    required this.organizerUserId,
    this.organizers = const [],
    this.sportType = 'cricket',
    required this.format,
    required this.status,
    this.maxTeams,
    this.rosterLockedAt,
    required this.maxOvers,
    this.advanceCount,
    this.coverImages = const [],
    this.description,
    this.venueName,
    this.category,
    this.ballType,
    this.pitchType,
    this.matchType,
    this.durationMinutes,
    this.startDate,
    this.endDate,
    this.registrationDeadline,
    this.isPublic = true,
  });

  factory TournamentModel.fromJson(Map<String, dynamic> json) {
    return TournamentModel(
      id: mongoId(json['_id']) ?? '',
      name: json['name']?.toString() ?? '',
      organizerUserId:
          mongoId(json['organizerUserId']) ??
          json['organizerUserId']?.toString() ??
          '',
      organizers: _organizers(json['organizerIds']),
      sportType: json['sportType']?.toString() ?? 'cricket',
      format: json['format']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      maxTeams: (json['maxTeams'] as num?)?.toInt(),
      rosterLockedAt: _parseDate(json['rosterLockedAt']),
      maxOvers: (json['maxOvers'] as num?)?.toInt() ?? 20,
      advanceCount: (json['advanceCount'] as num?)?.toInt(),
      coverImages: _stringList(json['coverImages']),
      description: _optionalString(json['description']),
      venueName: _optionalString(json['venueName']),
      category: _optionalString(json['category']),
      ballType: _optionalString(json['ballType']),
      pitchType: _optionalString(json['pitchType']),
      matchType: _optionalString(json['matchType']),
      durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
      startDate: _parseDate(json['startDate']),
      endDate: _parseDate(json['endDate']),
      registrationDeadline: _parseDate(json['registrationDeadline']),
      isPublic: _parseBool(json['isPublic'], fallback: true),
    );
  }

  /// Membership in [organizers], or the creator when that list was never seeded.
  bool isOrganizer(String? userId) {
    if (userId == null || userId.isEmpty) return false;
    if (organizers.isEmpty) return userId == organizerUserId;
    return organizers.any((organizer) => organizer.id == userId);
  }

  bool isCreator(String userId) =>
      userId.isNotEmpty && userId == organizerUserId;

  List<TournamentOrganizerRef> get organizerList {
    if (organizers.isNotEmpty) return organizers;
    if (organizerUserId.isEmpty) return const [];
    return [TournamentOrganizerRef(id: organizerUserId)];
  }
}

List<TournamentOrganizerRef> _organizers(dynamic value) {
  if (value is! List) return const [];
  return value
      .map((item) {
        if (item is String && item.isNotEmpty) {
          return TournamentOrganizerRef(id: item);
        }
        if (item is Map) {
          final id = mongoId(item) ?? '';
          if (id.isEmpty) return null;
          return TournamentOrganizerRef(
            id: id,
            fullName: _optionalString(item['fullName']),
            avatar: _optionalString(item['avatar']),
          );
        }
        return null;
      })
      .whereType<TournamentOrganizerRef>()
      .toList();
}

String? _optionalString(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return text;
}

bool _parseBool(dynamic value, {required bool fallback}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value.toString().trim().toLowerCase();
  if (text == 'true' || text == '1') return true;
  if (text == 'false' || text == '0') return false;
  return fallback;
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is String && value.trim().isEmpty) return null;
  return DateTime.tryParse(value.toString());
}

class TournamentPage {
  final List<TournamentModel> items;
  final int total;
  final int page;
  final int limit;

  const TournamentPage({
    required this.items,
    required this.total,
    this.page = 1,
    this.limit = 20,
  });

  bool get hasNextPage => page * limit < total;

  factory TournamentPage.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    final items = raw is List
        ? raw
              .whereType<Map>()
              .map(
                (item) =>
                    TournamentModel.fromJson(item.cast<String, dynamic>()),
              )
              .toList()
        : <TournamentModel>[];
    final limit = (json['limit'] as num?)?.toInt() ?? 20;
    return TournamentPage(
      items: items,
      total: (json['total'] as num?)?.toInt() ?? items.length,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: limit,
    );
  }
}

class TournamentTeamRef {
  final String id;
  final String name;
  final String sportType;

  const TournamentTeamRef({
    required this.id,
    required this.name,
    this.sportType = 'cricket',
  });

  factory TournamentTeamRef.fromJson(Map<String, dynamic> json) {
    return TournamentTeamRef(
      id: mongoId(json['_id']) ?? mongoId(json['id']) ?? '',
      name: json['name']?.toString() ?? 'Team',
      sportType: json['sportType']?.toString() ?? 'cricket',
    );
  }
}

class TournamentEntryModel {
  final String id;
  final String teamId;
  final String teamName;
  final String teamLogo;
  final String? teamLocationLabel;
  final String direction;
  final String status;

  const TournamentEntryModel({
    required this.id,
    required this.teamId,
    required this.teamName,
    this.teamLogo = '',
    this.teamLocationLabel,
    required this.direction,
    required this.status,
  });

  factory TournamentEntryModel.fromJson(Map<String, dynamic> json) {
    final team = json['team'];
    return TournamentEntryModel(
      id: mongoId(json['_id']) ?? '',
      teamId: mongoId(team) ?? '',
      teamName: displayName(team),
      teamLogo: _teamLogo(team),
      teamLocationLabel: _teamLocationLabel(team),
      direction: json['direction']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}

String _teamLogo(dynamic team) {
  if (team is Map) {
    return team['logo']?.toString() ?? '';
  }
  return '';
}

String? _teamLocationLabel(dynamic team) {
  if (team is! Map) return null;
  final location = team['location'];
  if (location is! Map) return null;
  for (final key in ['city', 'state', 'country']) {
    final value = location[key]?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
  }
  final address = location['address']?.toString().trim();
  if (address != null && address.isNotEmpty) return address;
  return null;
}

class TournamentFixtureModel {
  final TeamMatchModel match;
  final String stage;
  final int round;
  final String? groupLabel;
  final int matchNumber;
  final String? bracketWinnerId;
  final String? bracketWinnerName;

  const TournamentFixtureModel({
    required this.match,
    required this.stage,
    required this.round,
    required this.groupLabel,
    required this.matchNumber,
    this.bracketWinnerId,
    this.bracketWinnerName,
  });

  String get id => match.id ?? '';

  String get fromTeamId => match.fromTeamHelper.getId() ?? '';

  String get toTeamId => match.toTeamHelper.getId() ?? '';

  factory TournamentFixtureModel.fromJson(Map<String, dynamic> json) {
    final winner = json['tournamentBracketWinner'] ?? json['winnerTeam'];
    return TournamentFixtureModel(
      match: TeamMatchModel.fromJson(json),
      stage: json['stage']?.toString() ?? '',
      round: (json['round'] as num?)?.toInt() ?? 0,
      groupLabel: json['groupLabel']?.toString(),
      matchNumber: (json['matchNumber'] as num?)?.toInt() ?? 0,
      bracketWinnerId: mongoId(json['tournamentBracketWinner']),
      bracketWinnerName: winner == null
          ? null
          : displayName(winner, fallback: ''),
    );
  }

  /// Team that advances: organizer pick on a draw, otherwise the recorded winner.
  String? get decidedWinnerId {
    final picked = bracketWinnerId;
    if (picked != null && picked.isNotEmpty) return picked;
    if (match.status != TeamMatchStatus.completed) return null;
    final winnerId = match.winnerTeamHelper.getId();
    if (winnerId == null || winnerId.isEmpty) return null;
    return winnerId;
  }

  String get label {
    final group = groupLabel == null ? '' : 'Group $groupLabel · ';
    return '$group$stage · round $round · match $matchNumber';
  }
}

class StandingRowModel {
  final String teamId;
  final String teamName;
  final int played;
  final int won;
  final int drawn;
  final int lost;
  final int points;
  final double nrr;
  final int goalsFor;
  final int goalsAgainst;

  const StandingRowModel({
    required this.teamId,
    required this.teamName,
    required this.played,
    required this.won,
    required this.drawn,
    required this.lost,
    required this.points,
    required this.nrr,
    this.goalsFor = 0,
    this.goalsAgainst = 0,
  });

  int get goalDifference => goalsFor - goalsAgainst;

  factory StandingRowModel.fromJson(Map<String, dynamic> json) {
    return StandingRowModel(
      teamId: json['teamId']?.toString() ?? mongoId(json['team']) ?? '',
      teamName: displayName(json['team']),
      played: (json['played'] as num?)?.toInt() ?? 0,
      won: (json['won'] as num?)?.toInt() ?? 0,
      drawn: (json['drawn'] as num?)?.toInt() ?? 0,
      lost: (json['lost'] as num?)?.toInt() ?? 0,
      points: (json['points'] as num?)?.toInt() ?? 0,
      nrr: (json['nrr'] as num?)?.toDouble() ?? 0,
      goalsFor: (json['goalsFor'] as num?)?.toInt() ?? 0,
      goalsAgainst: (json['goalsAgainst'] as num?)?.toInt() ?? 0,
    );
  }
}

class StandingGroupModel {
  final String? groupLabel;
  final List<StandingRowModel> rows;

  const StandingGroupModel({required this.groupLabel, required this.rows});
}

class PendingQualifierModel {
  final String groupLabel;
  final int advanceCount;
  final List<String> lockedTeamIds;
  final List<String> tiedTeamIds;

  const PendingQualifierModel({
    required this.groupLabel,
    required this.advanceCount,
    required this.lockedTeamIds,
    required this.tiedTeamIds,
  });
}

class PendingBracketPickModel {
  final String matchId;
  final String fromTeamId;
  final String toTeamId;

  const PendingBracketPickModel({
    required this.matchId,
    required this.fromTeamId,
    required this.toTeamId,
  });
}

class TournamentTableModel {
  final List<StandingGroupModel> standings;
  final List<PendingQualifierModel> pendingQualifiers;
  final List<PendingBracketPickModel> pendingBracketPicks;

  const TournamentTableModel({
    required this.standings,
    required this.pendingQualifiers,
    required this.pendingBracketPicks,
  });

  factory TournamentTableModel.fromJson(Map<String, dynamic> json) {
    final groups = json['standings'];
    final qualifiers = json['pendingQualifiers'];
    final picks = json['pendingBracketPicks'];
    return TournamentTableModel(
      standings: groups is List
          ? groups.whereType<Map>().map((group) {
              final rows = group['rows'];
              return StandingGroupModel(
                groupLabel: group['groupLabel']?.toString(),
                rows: rows is List
                    ? rows
                          .whereType<Map>()
                          .map(
                            (row) => StandingRowModel.fromJson(
                              row.cast<String, dynamic>(),
                            ),
                          )
                          .toList()
                    : const [],
              );
            }).toList()
          : const [],
      pendingQualifiers: qualifiers is List
          ? qualifiers.whereType<Map>().map((item) {
              return PendingQualifierModel(
                groupLabel: item['groupLabel']?.toString() ?? '',
                advanceCount: (item['advanceCount'] as num?)?.toInt() ?? 2,
                lockedTeamIds: _stringList(item['lockedTeamIds']),
                tiedTeamIds: _stringList(item['tiedTeamIds']),
              );
            }).toList()
          : const [],
      pendingBracketPicks: picks is List
          ? picks.whereType<Map>().map((item) {
              return PendingBracketPickModel(
                matchId: item['matchId']?.toString() ?? '',
                fromTeamId: item['fromTeamId']?.toString() ?? '',
                toTeamId: item['toTeamId']?.toString() ?? '',
              );
            }).toList()
          : const [],
    );
  }
}

List<String> _stringList(dynamic value) {
  if (value is! List) return const [];
  return value.map((item) => item.toString()).toList();
}
