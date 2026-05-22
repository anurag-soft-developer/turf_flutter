import '../../../match_up/model/team_match_model.dart';

/// Body for `POST /scoring/football/matches/:teamMatchId/session`.
class CreateFootballSessionRequest {
  final MatchFootballPeriod period;
  final int? matchMinute;

  const CreateFootballSessionRequest({
    this.period = MatchFootballPeriod.firstHalf,
    this.matchMinute,
  });

  Map<String, dynamic> toJson() => {
    'period': _periodToApi(period),
    if (matchMinute != null) 'matchMinute': matchMinute,
  };
}

/// Body for `POST /scoring/football/matches/:teamMatchId/events`.
class AppendFootballEventRequest {
  final MatchFootballPeriod period;
  final int? matchMinute;
  final FootballEventPayload payload;

  const AppendFootballEventRequest({
    required this.period,
    required this.payload,
    this.matchMinute,
  });

  Map<String, dynamic> toJson() => {
    'period': _periodToApi(period),
    if (matchMinute != null) 'matchMinute': matchMinute,
    'payload': payload.toJson(),
  };
}

abstract class FootballEventPayload {
  String get kind;
  Map<String, dynamic> toJson();
}

class GoalPayload extends FootballEventPayload {
  @override
  final String kind = 'goal';
  final String beneficiaryTeamId;
  final String scorerUserId;
  final String? assistUserId;

  GoalPayload({
    required this.beneficiaryTeamId,
    required this.scorerUserId,
    this.assistUserId,
  });

  @override
  Map<String, dynamic> toJson() => {
    'kind': kind,
    'beneficiaryTeamId': beneficiaryTeamId,
    'scorerUserId': scorerUserId,
    if (assistUserId != null && assistUserId!.isNotEmpty)
      'assistUserId': assistUserId,
  };
}

class OwnGoalPayload extends FootballEventPayload {
  @override
  final String kind = 'own_goal';
  final String beneficiaryTeamId;
  final String concedingPlayerUserId;

  OwnGoalPayload({
    required this.beneficiaryTeamId,
    required this.concedingPlayerUserId,
  });

  @override
  Map<String, dynamic> toJson() => {
    'kind': kind,
    'beneficiaryTeamId': beneficiaryTeamId,
    'concedingPlayerUserId': concedingPlayerUserId,
  };
}

class YellowCardPayload extends FootballEventPayload {
  @override
  final String kind = 'yellow_card';
  final String teamId;
  final String playerUserId;

  YellowCardPayload({required this.teamId, required this.playerUserId});

  @override
  Map<String, dynamic> toJson() => {
    'kind': kind,
    'teamId': teamId,
    'playerUserId': playerUserId,
  };
}

class RedCardPayload extends FootballEventPayload {
  @override
  final String kind = 'red_card';
  final String teamId;
  final String playerUserId;

  RedCardPayload({required this.teamId, required this.playerUserId});

  @override
  Map<String, dynamic> toJson() => {
    'kind': kind,
    'teamId': teamId,
    'playerUserId': playerUserId,
  };
}

class SubstitutionPayload extends FootballEventPayload {
  @override
  final String kind = 'substitution';
  final String teamId;
  final String playerOffUserId;
  final String playerOnUserId;

  SubstitutionPayload({
    required this.teamId,
    required this.playerOffUserId,
    required this.playerOnUserId,
  });

  @override
  Map<String, dynamic> toJson() => {
    'kind': kind,
    'teamId': teamId,
    'playerOffUserId': playerOffUserId,
    'playerOnUserId': playerOnUserId,
  };
}

class PenaltyScoredPayload extends FootballEventPayload {
  @override
  final String kind = 'penalty_scored';
  final String beneficiaryTeamId;
  final String takerUserId;

  PenaltyScoredPayload({
    required this.beneficiaryTeamId,
    required this.takerUserId,
  });

  @override
  Map<String, dynamic> toJson() => {
    'kind': kind,
    'beneficiaryTeamId': beneficiaryTeamId,
    'takerUserId': takerUserId,
  };
}

class PenaltyMissedPayload extends FootballEventPayload {
  @override
  final String kind = 'penalty_missed';
  final String teamId;
  final String takerUserId;

  PenaltyMissedPayload({required this.teamId, required this.takerUserId});

  @override
  Map<String, dynamic> toJson() => {
    'kind': kind,
    'teamId': teamId,
    'takerUserId': takerUserId,
  };
}

String _periodToApi(MatchFootballPeriod period) {
  return switch (period) {
    MatchFootballPeriod.firstHalf => 'first_half',
    MatchFootballPeriod.secondHalf => 'second_half',
    MatchFootballPeriod.extraFirst => 'extra_first',
    MatchFootballPeriod.extraSecond => 'extra_second',
    MatchFootballPeriod.penalties => 'penalties',
  };
}

MatchFootballPeriod periodFromApi(String? value) {
  return switch (value) {
    'second_half' => MatchFootballPeriod.secondHalf,
    'extra_first' => MatchFootballPeriod.extraFirst,
    'extra_second' => MatchFootballPeriod.extraSecond,
    'penalties' => MatchFootballPeriod.penalties,
    _ => MatchFootballPeriod.firstHalf,
  };
}

String periodLabel(MatchFootballPeriod period) {
  return switch (period) {
    MatchFootballPeriod.firstHalf => '1st half',
    MatchFootballPeriod.secondHalf => '2nd half',
    MatchFootballPeriod.extraFirst => 'Extra time (1st)',
    MatchFootballPeriod.extraSecond => 'Extra time (2nd)',
    MatchFootballPeriod.penalties => 'Penalties',
  };
}
