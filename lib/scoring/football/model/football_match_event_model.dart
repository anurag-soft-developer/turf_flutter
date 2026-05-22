import 'package:json_annotation/json_annotation.dart';

import '../../../core/models/team_match/team_match_ref_converter.dart';
import '../../../core/models/user_field_converters.dart';
import '../../../match_up/model/team_match_model.dart';
import 'football_scoring_models.dart';

part 'football_match_event_model.g.dart';

String _mongoIdFromJson(dynamic json) {
  if (json == null) return '';
  if (json is Map) {
    final oid = json[r'$oid'];
    if (oid != null) return oid.toString();
  }
  return json.toString();
}

@JsonEnum(fieldRename: FieldRename.snake)
enum FootballEventKind {
  goal,
  ownGoal,
  yellowCard,
  redCard,
  substitution,
  penaltyScored,
  penaltyMissed,
}

FootballEventKind _kindFromApi(String? value) {
  return switch (value) {
    'own_goal' => FootballEventKind.ownGoal,
    'yellow_card' => FootballEventKind.yellowCard,
    'red_card' => FootballEventKind.redCard,
    'substitution' => FootballEventKind.substitution,
    'penalty_scored' => FootballEventKind.penaltyScored,
    'penalty_missed' => FootballEventKind.penaltyMissed,
    _ => FootballEventKind.goal,
  };
}

MatchFootballPeriod _periodFromJson(dynamic json) =>
    periodFromApi(json?.toString());

/// Persisted football event from `POST .../events` and `GET .../events`.
@JsonSerializable(explicitToJson: true)
class FootballMatchEvent {
  @JsonKey(name: '_id', fromJson: _mongoIdFromJson, defaultValue: '')
  final String id;

  @JsonKey(name: 'teamMatchId')
  @TeamMatchRefConverter()
  final dynamic teamMatchId;

  final int sequence;

  @JsonKey(fromJson: _kindFromApi, unknownEnumValue: FootballEventKind.goal)
  final FootballEventKind kind;

  @JsonKey(fromJson: _periodFromJson)
  final MatchFootballPeriod period;

  final int? matchMinute;

  @JsonKey(name: 'beneficiaryTeamId')
  @TeamMatchRefConverter()
  final dynamic beneficiaryTeamId;

  @JsonKey(name: 'primaryUserId')
  @UserConverter()
  final dynamic primaryUserId;

  @JsonKey(name: 'secondaryUserId')
  @UserConverter()
  final dynamic secondaryUserId;

  final int scoreDeltaTeamOne;
  final int scoreDeltaTeamTwo;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FootballMatchEvent({
    this.id = '',
    required this.teamMatchId,
    required this.sequence,
    required this.kind,
    required this.period,
    required this.beneficiaryTeamId,
    required this.scoreDeltaTeamOne,
    required this.scoreDeltaTeamTwo,
    this.matchMinute,
    this.primaryUserId,
    this.secondaryUserId,
    this.createdAt,
    this.updatedAt,
  });

  factory FootballMatchEvent.fromJson(Map<String, dynamic> json) =>
      _$FootballMatchEventFromJson(json);

  Map<String, dynamic> toJson() => _$FootballMatchEventToJson(this);
}
