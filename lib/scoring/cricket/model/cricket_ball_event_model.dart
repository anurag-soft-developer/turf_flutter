import 'package:json_annotation/json_annotation.dart';

import '../../../core/models/team_match/team_match_ref_converter.dart';
import '../../../core/models/user_field_converters.dart';

part 'cricket_ball_event_model.g.dart';

String _mongoIdFromJson(dynamic json) {
  if (json == null) return '';
  if (json is Map) {
    final oid = json[r'$oid'];
    if (oid != null) return oid.toString();
  }
  return json.toString();
}

/// Backend `CricketWicketKind` strings (`run_out`, …).
@JsonEnum(fieldRename: FieldRename.snake)
enum CricketWicketKind {
  bowled,
  caught,
  lbw,
  runOut,
  stumped,
  hitWicket,
  other,
}

/// Embedded delivery (`CricketOverEvent.ballEvents[]`).
@JsonSerializable(explicitToJson: true)
class CricketBallEvent {
  final int ballInOverAfter;

  @JsonKey(name: 'strikerUserId')
  @UserConverter()
  final dynamic strikerUserId;

  @JsonKey(name: 'nonStrikerUserId')
  @UserConverter()
  final dynamic nonStrikerUserId;

  final int runsOffBat;
  final int extrasWide;
  final bool extrasNoBall;
  final int extrasBye;
  final int extrasLegBye;
  final bool isWicket;
  final CricketWicketKind? wicketKind;

  @JsonKey(name: 'dismissedUserId')
  @UserConverter()
  final dynamic dismissedUserId;

  @JsonKey(name: 'primaryFielderUserId')
  @UserConverter()
  final dynamic primaryFielderUserId;

  final int totalRunsOnDelivery;
  final bool isLegalDelivery;
  final int wicketsFallen;

  const CricketBallEvent({
    required this.ballInOverAfter,
    required this.strikerUserId,
    required this.nonStrikerUserId,
    required this.runsOffBat,
    required this.extrasWide,
    required this.extrasNoBall,
    required this.extrasBye,
    required this.extrasLegBye,
    required this.isWicket,
    required this.totalRunsOnDelivery,
    required this.isLegalDelivery,
    required this.wicketsFallen,
    this.wicketKind,
    this.dismissedUserId,
    this.primaryFielderUserId,
  });

  factory CricketBallEvent.fromJson(Map<String, dynamic> json) =>
      _$CricketBallEventFromJson(json);

  Map<String, dynamic> toJson() => _$CricketBallEventToJson(this);
}

/// Persisted over row from `POST .../balls` and `GET .../overs`.
@JsonSerializable(explicitToJson: true)
class CricketOverEvent {
  @JsonKey(name: '_id', fromJson: _mongoIdFromJson, defaultValue: '')
  final String id;

  @JsonKey(name: 'teamMatchId')
  @TeamMatchRefConverter()
  final dynamic teamMatchId;

  @JsonKey(name: 'bowlerUserId')
  @UserConverter()
  final dynamic bowlerUserId;

  final int sequence;
  final int innings;
  final int overAfter;

  @JsonKey(defaultValue: <CricketBallEvent>[])
  final List<CricketBallEvent> ballEvents;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CricketOverEvent({
    this.id = '',
    required this.teamMatchId,
    required this.bowlerUserId,
    required this.sequence,
    required this.innings,
    required this.overAfter,
    this.ballEvents = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory CricketOverEvent.fromJson(Map<String, dynamic> json) =>
      _$CricketOverEventFromJson(json);

  Map<String, dynamic> toJson() => _$CricketOverEventToJson(this);
}
