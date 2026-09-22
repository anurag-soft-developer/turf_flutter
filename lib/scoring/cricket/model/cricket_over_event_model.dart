import 'package:json_annotation/json_annotation.dart';

import '../../../core/models/team/team_ref_converter.dart';
import '../../../core/models/team_match/team_match_ref_converter.dart';
import '../../../core/models/user_field_converters.dart';
import '../../../core/utils/mongo_id_util.dart';

part 'cricket_over_event_model.g.dart';

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

/// Backend `CricketScoringEntryKind`.
enum CricketScoringEntryKind { ball, substitution }

DateTime _entryRecordedAtFromJson(dynamic raw) {
  if (raw is DateTime) return raw.toUtc();
  return DateTime.tryParse(raw?.toString() ?? '')?.toUtc() ??
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}

/// Discriminated scoring entry in `CricketOverEvent.events[]`.
sealed class CricketScoringEntry {
  const CricketScoringEntry();

  DateTime get recordedAt;
  CricketScoringEntryKind get kind;
  Map<String, dynamic> toJson();

  factory CricketScoringEntry.fromJson(Map<String, dynamic> json) {
    final kind = json['kind']?.toString();
    if (kind == 'substitution') {
      return CricketSubstitutionEvent.fromJson(json);
    }
    return CricketBallEvent.fromJson(json);
  }
}

/// Embedded delivery (`kind: ball`).
@JsonSerializable(explicitToJson: true)
class CricketBallEvent extends CricketScoringEntry {
  @override
  CricketScoringEntryKind get kind => CricketScoringEntryKind.ball;

  @JsonKey(fromJson: _entryRecordedAtFromJson)
  @override
  final DateTime recordedAt;

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
    required this.recordedAt,
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

  @override
  Map<String, dynamic> toJson() => {
        ..._$CricketBallEventToJson(this),
        'kind': 'ball',
      };
}

/// Embedded substitution (`kind: substitution`).
@JsonSerializable(explicitToJson: true)
class CricketSubstitutionEvent extends CricketScoringEntry {
  @override
  CricketScoringEntryKind get kind => CricketScoringEntryKind.substitution;

  @JsonKey(fromJson: _entryRecordedAtFromJson)
  @override
  final DateTime recordedAt;

  @JsonKey(name: 'teamId')
  @TeamRefConverter()
  final dynamic teamId;

  @JsonKey(name: 'playerOffParticipantId', fromJson: mongoIdFromJson)
  final String playerOffParticipantId;

  @JsonKey(name: 'playerOnParticipantId', fromJson: mongoIdFromJson)
  final String playerOnParticipantId;

  const CricketSubstitutionEvent({
    required this.recordedAt,
    required this.teamId,
    required this.playerOffParticipantId,
    required this.playerOnParticipantId,
  });

  factory CricketSubstitutionEvent.fromJson(Map<String, dynamic> json) =>
      _$CricketSubstitutionEventFromJson(json);

  @override
  Map<String, dynamic> toJson() => {
        ..._$CricketSubstitutionEventToJson(this),
        'kind': 'substitution',
      };
}

List<CricketScoringEntry> _eventsFromJson(List<dynamic>? raw) {
  if (raw == null) return const [];
  return raw
      .whereType<Map>()
      .map((e) => CricketScoringEntry.fromJson(e.cast<String, dynamic>()))
      .toList();
}

List<Map<String, dynamic>> _eventsToJson(List<CricketScoringEntry> events) =>
    events.map((e) => e.toJson()).toList();

/// Persisted over row from scoring APIs (`GET .../overs`, append ball/sub).
@JsonSerializable(explicitToJson: true)
class CricketOverEvent {
  @JsonKey(name: '_id', fromJson: mongoIdFromJson, defaultValue: '')
  final String id;

  @JsonKey(name: 'teamMatchId')
  @TeamMatchRefConverter()
  final dynamic teamMatchId;

  /// Optional on substitution-only placeholder over docs.
  @JsonKey(name: 'bowlerUserId')
  @UserConverter()
  final dynamic bowlerUserId;

  final int sequence;
  final int innings;
  final int overAfter;

  @JsonKey(fromJson: _eventsFromJson, toJson: _eventsToJson)
  final List<CricketScoringEntry> events;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CricketOverEvent({
    this.id = '',
    required this.teamMatchId,
    this.bowlerUserId,
    required this.sequence,
    required this.innings,
    required this.overAfter,
    this.events = const [],
    this.createdAt,
    this.updatedAt,
  });

  /// Ball deliveries only (scorecard / figures).
  List<CricketBallEvent> get ballEvents =>
      events.whereType<CricketBallEvent>().toList();

  factory CricketOverEvent.fromJson(Map<String, dynamic> json) =>
      _$CricketOverEventFromJson(json);

  Map<String, dynamic> toJson() => _$CricketOverEventToJson(this);
}

/// Flatten all over docs' events, sorted by recordedAt (stable tie-break).
List<CricketScoringEntry> flattenCricketTimeline(
  List<CricketOverEvent> overs,
) {
  final rows = <({CricketScoringEntry entry, int docSeq, int idx})>[];
  for (final over in overs) {
    for (var i = 0; i < over.events.length; i++) {
      rows.add((entry: over.events[i], docSeq: over.sequence, idx: i));
    }
  }
  rows.sort((a, b) {
    final t = a.entry.recordedAt.compareTo(b.entry.recordedAt);
    if (t != 0) return t;
    final s = a.docSeq.compareTo(b.docSeq);
    if (s != 0) return s;
    return a.idx.compareTo(b.idx);
  });
  return rows.map((r) => r.entry).toList();
}
