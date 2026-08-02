enum ScoringSport { cricket, football }

enum ScoringAction { appendBall, appendEvent, undoBall, undoEvent }

/// Known `data.kind` values on cricket / announced-player scoring events.
abstract final class ScoringEventKind {
  static const cricketCreateSession = 'cricket_create_session';
  static const cricketChangeInning = 'cricket_change_inning';
  static const cricketCompleteMatch = 'cricket_complete_match';
  static const cricketUpdateLineup = 'cricket_update_lineup';
  static const announcedPlayersUpdated = 'announced_players_updated';
}

class ScoringMatchRef {
  final String teamMatchId;

  const ScoringMatchRef({required this.teamMatchId});

  Map<String, dynamic> toJson() => {'teamMatchId': teamMatchId};
}

class ScoringUpdatePayload {
  final String eventId;
  final ScoringSport sport;
  final String teamMatchId;
  final String actorUserId;
  final ScoringAction action;
  final Map<String, dynamic> data;
  final DateTime createdAt;

  const ScoringUpdatePayload({
    required this.eventId,
    required this.sport,
    required this.teamMatchId,
    required this.actorUserId,
    required this.action,
    required this.data,
    required this.createdAt,
  });

  String? get dataKind => data['kind']?.toString();

  bool get isAnnouncedPlayersUpdated =>
      dataKind == ScoringEventKind.announcedPlayersUpdated;

  bool get isCricketCreateSession =>
      dataKind == ScoringEventKind.cricketCreateSession;

  bool get isCricketChangeInning =>
      dataKind == ScoringEventKind.cricketChangeInning;

  bool get isCricketCompleteMatch =>
      dataKind == ScoringEventKind.cricketCompleteMatch;

  bool get isCricketUpdateLineup =>
      dataKind == ScoringEventKind.cricketUpdateLineup;

  factory ScoringUpdatePayload.fromJson(Map<String, dynamic> json) {
    final matchId =
        json['teamMatchId']?.toString() ?? json['sessionId']?.toString() ?? '';
    return ScoringUpdatePayload(
      eventId: json['eventId']?.toString() ?? '',
      sport: _sportFromApi(json['sport']?.toString()),
      teamMatchId: matchId,
      actorUserId: json['actorUserId']?.toString() ?? '',
      action: _actionFromApi(json['action']?.toString()),
      data: (json['data'] as Map?)?.cast<String, dynamic>() ?? const {},
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now().toUtc(),
    );
  }

  Map<String, dynamic> toJson() => {
    'eventId': eventId,
    'sport': _sportToApi(sport),
    'teamMatchId': teamMatchId,
    'actorUserId': actorUserId,
    'action': _actionToApi(action),
    'data': data,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };
}

ScoringSport _sportFromApi(String? value) {
  return value == 'football' ? ScoringSport.football : ScoringSport.cricket;
}

String _sportToApi(ScoringSport sport) {
  return switch (sport) {
    ScoringSport.cricket => 'cricket',
    ScoringSport.football => 'football',
  };
}

ScoringAction _actionFromApi(String? value) {
  return switch (value) {
    'append_event' => ScoringAction.appendEvent,
    'undo_ball' => ScoringAction.undoBall,
    'undo_event' => ScoringAction.undoEvent,
    _ => ScoringAction.appendBall,
  };
}

String _actionToApi(ScoringAction action) {
  return switch (action) {
    ScoringAction.appendBall => 'append_ball',
    ScoringAction.appendEvent => 'append_event',
    ScoringAction.undoBall => 'undo_ball',
    ScoringAction.undoEvent => 'undo_event',
  };
}
