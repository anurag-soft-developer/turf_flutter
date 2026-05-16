enum ScoringSport { cricket, football }

enum ScoringAction { appendBall, appendEvent }

enum CricketOutcomeKind {
  dot,
  runs,
  wide,
  noBall,
  bye,
  legBye,
  wicketBowled,
  wicketCaught,
  wicketLbw,
  wicketRunOut,
  wicketStumped,
  wicketHitWicket,
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

class AppendCricketBallRequest {
  final String strikerUserId;
  final String nonStrikerUserId;
  final String bowlerUserId;
  final CricketOutcome outcome;
  final String? incomingBatsmanUserId;

  const AppendCricketBallRequest({
    required this.strikerUserId,
    required this.nonStrikerUserId,
    required this.bowlerUserId,
    required this.outcome,
    this.incomingBatsmanUserId,
  });

  Map<String, dynamic> toJson() => {
    'strikerUserId': strikerUserId,
    'nonStrikerUserId': nonStrikerUserId,
    'bowlerUserId': bowlerUserId,
    'outcome': outcome.toJson(),
    if (incomingBatsmanUserId != null)
      'incomingBatsmanUserId': incomingBatsmanUserId,
  };
}

/// Body for `POST /scoring/cricket/matches/:teamMatchId/session`.
class CreateCricketSessionRequest {
  final String actorTeamId;
  final String battingTeamId;
  final String bowlingTeamId;
  final int maxOvers;
  final String? strikerUserId;
  final String? nonStrikerUserId;
  final String? bowlerUserId;

  const CreateCricketSessionRequest({
    required this.actorTeamId,
    required this.battingTeamId,
    required this.bowlingTeamId,
    this.maxOvers = 20,
    this.strikerUserId,
    this.nonStrikerUserId,
    this.bowlerUserId,
  });

  Map<String, dynamic> toJson() => {
    'actorTeamId': actorTeamId,
    'battingTeamId': battingTeamId,
    'bowlingTeamId': bowlingTeamId,
    'maxOvers': maxOvers,
    if (strikerUserId != null && strikerUserId!.isNotEmpty)
      'strikerUserId': strikerUserId,
    if (nonStrikerUserId != null && nonStrikerUserId!.isNotEmpty)
      'nonStrikerUserId': nonStrikerUserId,
    if (bowlerUserId != null && bowlerUserId!.isNotEmpty)
      'bowlerUserId': bowlerUserId,
  };
}

/// Body for `PATCH /scoring/cricket/matches/:teamMatchId/state`.
class UpdateCricketStateRequest {
  final String actorTeamId;
  final String? strikerUserId;
  final String? nonStrikerUserId;
  final String? bowlerUserId;

  const UpdateCricketStateRequest({
    required this.actorTeamId,
    this.strikerUserId,
    this.nonStrikerUserId,
    this.bowlerUserId,
  });

  Map<String, dynamic> toJson() => {
    'actorTeamId': actorTeamId,
    if (strikerUserId != null && strikerUserId!.isNotEmpty)
      'strikerUserId': strikerUserId,
    if (nonStrikerUserId != null && nonStrikerUserId!.isNotEmpty)
      'nonStrikerUserId': nonStrikerUserId,
    if (bowlerUserId != null && bowlerUserId!.isNotEmpty)
      'bowlerUserId': bowlerUserId,
  };
}

/// Body for `POST /scoring/cricket/matches/:teamMatchId/complete`.
class CompleteCricketMatchRequest {
  final String actorTeamId;

  const CompleteCricketMatchRequest({required this.actorTeamId});

  Map<String, dynamic> toJson() => {'actorTeamId': actorTeamId};
}

abstract class CricketOutcome {
  final CricketOutcomeKind kind;
  const CricketOutcome(this.kind);
  Map<String, dynamic> toJson();
}

class DotOutcome extends CricketOutcome {
  const DotOutcome() : super(CricketOutcomeKind.dot);
  @override
  Map<String, dynamic> toJson() => {'kind': 'dot'};
}

class RunsOutcome extends CricketOutcome {
  final int offBat;
  const RunsOutcome({required this.offBat}) : super(CricketOutcomeKind.runs);
  @override
  Map<String, dynamic> toJson() => {'kind': 'runs', 'offBat': offBat};
}

class WideOutcome extends CricketOutcome {
  final int additionalRuns;
  const WideOutcome({required this.additionalRuns})
    : super(CricketOutcomeKind.wide);
  @override
  Map<String, dynamic> toJson() => {
    'kind': 'wide',
    'additionalRuns': additionalRuns,
  };
}

class NoBallOutcome extends CricketOutcome {
  final int offBat;
  const NoBallOutcome({required this.offBat})
    : super(CricketOutcomeKind.noBall);
  @override
  Map<String, dynamic> toJson() => {'kind': 'no_ball', 'offBat': offBat};
}

class ByeOutcome extends CricketOutcome {
  final int runs;
  const ByeOutcome({required this.runs}) : super(CricketOutcomeKind.bye);
  @override
  Map<String, dynamic> toJson() => {'kind': 'bye', 'runs': runs};
}

class LegByeOutcome extends CricketOutcome {
  final int runs;
  const LegByeOutcome({required this.runs}) : super(CricketOutcomeKind.legBye);
  @override
  Map<String, dynamic> toJson() => {'kind': 'leg_bye', 'runs': runs};
}

class WicketBowledOutcome extends CricketOutcome {
  final int offBat;
  const WicketBowledOutcome({required this.offBat})
    : super(CricketOutcomeKind.wicketBowled);
  @override
  Map<String, dynamic> toJson() => {'kind': 'wicket_bowled', 'offBat': offBat};
}

class WicketCaughtOutcome extends CricketOutcome {
  final int offBat;
  final String fielderUserId;
  const WicketCaughtOutcome({required this.offBat, required this.fielderUserId})
    : super(CricketOutcomeKind.wicketCaught);
  @override
  Map<String, dynamic> toJson() => {
    'kind': 'wicket_caught',
    'offBat': offBat,
    'fielderUserId': fielderUserId,
  };
}

class WicketLbwOutcome extends CricketOutcome {
  final int offBat;
  const WicketLbwOutcome({required this.offBat})
    : super(CricketOutcomeKind.wicketLbw);
  @override
  Map<String, dynamic> toJson() => {'kind': 'wicket_lbw', 'offBat': offBat};
}

class WicketRunOutOutcome extends CricketOutcome {
  final int runsOffBat;
  final String dismissedUserId;
  final String? fielderUserId;
  const WicketRunOutOutcome({
    required this.runsOffBat,
    required this.dismissedUserId,
    this.fielderUserId,
  }) : super(CricketOutcomeKind.wicketRunOut);
  @override
  Map<String, dynamic> toJson() => {
    'kind': 'wicket_run_out',
    'runsOffBat': runsOffBat,
    'dismissedUserId': dismissedUserId,
    if (fielderUserId != null) 'fielderUserId': fielderUserId,
  };
}

class WicketStumpedOutcome extends CricketOutcome {
  final int offBat;
  final String wicketKeeperUserId;
  const WicketStumpedOutcome({
    required this.offBat,
    required this.wicketKeeperUserId,
  }) : super(CricketOutcomeKind.wicketStumped);
  @override
  Map<String, dynamic> toJson() => {
    'kind': 'wicket_stumped',
    'offBat': offBat,
    'wicketKeeperUserId': wicketKeeperUserId,
  };
}

class WicketHitWicketOutcome extends CricketOutcome {
  final int offBat;
  const WicketHitWicketOutcome({required this.offBat})
    : super(CricketOutcomeKind.wicketHitWicket);
  @override
  Map<String, dynamic> toJson() => {
    'kind': 'wicket_hit_wicket',
    'offBat': offBat,
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
