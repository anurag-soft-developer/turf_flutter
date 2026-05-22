enum ScoringSport { cricket, football }

enum ScoringAction { appendBall, appendEvent }

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
  return value == 'append_event'
      ? ScoringAction.appendEvent
      : ScoringAction.appendBall;
}

String _actionToApi(ScoringAction action) {
  return switch (action) {
    ScoringAction.appendBall => 'append_ball',
    ScoringAction.appendEvent => 'append_event',
  };
}
