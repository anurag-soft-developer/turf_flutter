import 'package:json_annotation/json_annotation.dart';

import '../../core/models/team/team_ref_converter.dart';
import '../../core/models/team/team_ref_field_instance.dart';
import '../../core/models/turf_field_converter.dart';
import '../../core/models/turf_field_instance.dart';
import '../../team/model/team_model.dart';

part 'team_match_model.g.dart';

/// Backend `TeamFilterDto.limit` / matchmaking feed — max 50.
const int kMatchmakingFeedMaxLimit = 50;

/// Backend `ListNegotiationsFilterSchema` — max 50.
const int kMatchmakingListRequestsMaxLimit = 50;

// --- Enums (backend string values) ---

/// Backend [TeamMatchSource].
enum TeamMatchSource {
  feed,
}

/// Backend [TeamMatchStatus].
enum TeamMatchStatus {
  requested,
  accepted,
  negotiating,
  @JsonValue('schedule_finalized')
  scheduleFinalized,
  rejected,
  expired,
  cancelled,
  ongoing,
  completed,
  draw,
}

/// Backend [MatchProposalStatus].
enum MatchProposalStatus {
  pending,
  accepted,
  rejected,
  withdrawn,
  expired,
}

/// Backend `ListNegotiationsFilterSchema.type`.
enum NegotiationListType {
  incoming,
  outgoing,
  all,
}

/// Backend `matchResponseActionSchema`.
enum MatchResponseAction {
  accept,
  reject,
}

/// Backend `proposalDecisionActionSchema`.
enum ProposalDecisionAction {
  accept,
  reject,
  withdraw,
}

/// Backend `RecordMatchResultSchema.outcome`.
enum MatchResultOutcome {
  ongoing,
  completed,
  draw,
}

// --- ObjectId helpers (lean refs vs populated docs) ---

String _objectIdFromJson(dynamic json) {
  if (json is String) return json;
  if (json is Map<String, dynamic>) {
    final id = json['_id'] ?? json['id'];
    if (id != null) return id.toString();
  }
  return json.toString();
}

String? _objectIdFromJsonNullable(dynamic json) {
  if (json == null) return null;
  return _objectIdFromJson(json);
}

// --- Nested document shapes ---

/// Slot range on a [TeamMatchModel] proposal.
@JsonSerializable()
class TeamMatchTimeSlot {
  final DateTime startTime;
  final DateTime endTime;

  const TeamMatchTimeSlot({required this.startTime, required this.endTime});

  factory TeamMatchTimeSlot.fromJson(Map<String, dynamic> json) =>
      _$TeamMatchTimeSlotFromJson(json);

  Map<String, dynamic> toJson() => _$TeamMatchTimeSlotToJson(this);
}

/// Backend embedded `proposedSlots[]` item.
@JsonSerializable(explicitToJson: true)
class ProposedSlotModel {
  @JsonKey(name: 'proposalId', fromJson: _objectIdFromJson)
  final String proposalId;
  final TeamMatchTimeSlot slot;
  @JsonKey(name: 'proposedByTeamId', fromJson: _objectIdFromJson)
  final String proposedByTeamId;
  final MatchProposalStatus status;
  @JsonKey(name: 'decidedByTeamId', fromJson: _objectIdFromJsonNullable)
  final String? decidedByTeamId;
  final DateTime? decidedAt;
  final String? reason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProposedSlotModel({
    required this.proposalId,
    required this.slot,
    required this.proposedByTeamId,
    required this.status,
    this.decidedByTeamId,
    this.decidedAt,
    this.reason,
    this.createdAt,
    this.updatedAt,
  });

  factory ProposedSlotModel.fromJson(Map<String, dynamic> json) =>
      _$ProposedSlotModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProposedSlotModelToJson(this);
}

/// Backend embedded `proposedTurfs[]` item.
@JsonSerializable(explicitToJson: true)
class ProposedTurfModel {
  @JsonKey(name: 'proposalId', fromJson: _objectIdFromJson)
  final String proposalId;
  /// Lean id or populated turf (see [turfIdHelper]).
  @JsonKey(name: 'turfId')
  @TurfConverter()
  final dynamic turfId;
  @JsonKey(name: 'proposedByTeamId', fromJson: _objectIdFromJson)
  final String proposedByTeamId;
  final MatchProposalStatus status;
  @JsonKey(name: 'decidedByTeamId', fromJson: _objectIdFromJsonNullable)
  final String? decidedByTeamId;
  final DateTime? decidedAt;
  final String? reason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProposedTurfModel({
    required this.proposalId,
    required this.turfId,
    required this.proposedByTeamId,
    required this.status,
    this.decidedByTeamId,
    this.decidedAt,
    this.reason,
    this.createdAt,
    this.updatedAt,
  });

  factory ProposedTurfModel.fromJson(Map<String, dynamic> json) =>
      _$ProposedTurfModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProposedTurfModelToJson(this);

  TurfFieldInstance get turfIdHelper => TurfFieldInstance(turfId);
}

/// Backend [TeamMatch] document.
@JsonSerializable(explicitToJson: true)
class TeamMatchModel {
  @JsonKey(name: '_id')
  final String? id;
  final TeamMatchSource source;
  /// Lean id or populated team subset ([TeamMemberFieldInstance] via [TeamRefConverter]).
  @JsonKey(name: 'fromTeam')
  @TeamRefConverter()
  final dynamic fromTeam;
  /// Lean id or populated team subset ([TeamMemberFieldInstance] via [TeamRefConverter]).
  @JsonKey(name: 'toTeam')
  @TeamRefConverter()
  final dynamic toTeam;
  final TeamSportType sportType;
  final TeamMatchStatus status;
  @JsonKey(name: 'statusUpdatedBy', fromJson: _objectIdFromJsonNullable)
  final String? statusUpdatedBy;
  final DateTime? statusUpdatedAt;
  @JsonKey(defaultValue: <ProposedSlotModel>[])
  final List<ProposedSlotModel> proposedSlots;
  @JsonKey(defaultValue: <ProposedTurfModel>[])
  final List<ProposedTurfModel> proposedTurfs;
  @JsonKey(name: 'selectedSlotProposalId', fromJson: _objectIdFromJsonNullable)
  final String? selectedSlotProposalId;
  @JsonKey(name: 'selectedTurfProposalId', fromJson: _objectIdFromJsonNullable)
  final String? selectedTurfProposalId;
  /// Lean id or populated team subset when backend populates `winnerTeam`.
  @JsonKey(name: 'winnerTeam')
  @TeamRefConverter()
  final dynamic winnerTeam;
  final String? notes;
  final DateTime? expiresAt;
  final DateTime? closedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TeamMatchModel({
    this.id,
    required this.source,
    required this.fromTeam,
    required this.toTeam,
    required this.sportType,
    required this.status,
    this.statusUpdatedBy,
    this.statusUpdatedAt,
    this.proposedSlots = const [],
    this.proposedTurfs = const [],
    this.selectedSlotProposalId,
    this.selectedTurfProposalId,
    this.winnerTeam,
    this.notes,
    this.expiresAt,
    this.closedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory TeamMatchModel.fromJson(Map<String, dynamic> json) =>
      _$TeamMatchModelFromJson(json);

  Map<String, dynamic> toJson() => _$TeamMatchModelToJson(this);

  TeamRefFieldInstance get fromTeamHelper => TeamRefFieldInstance(fromTeam);

  TeamRefFieldInstance get toTeamHelper => TeamRefFieldInstance(toTeam);

  TeamRefFieldInstance get winnerTeamHelper => TeamRefFieldInstance(winnerTeam);
}

// --- Query param objects ---

/// Backend [MatchFeedFilterDto] / `MatchFeedFilterSchema`.
class MatchFeedFilterQuery {
  final String fromTeamId;
  final int page;
  final int limit;
  final double? nearbyLat;
  final double? nearbyLng;
  final double? nearbyRadiusKm;

  const MatchFeedFilterQuery({
    required this.fromTeamId,
    this.page = 1,
    this.limit = 10,
    this.nearbyLat,
    this.nearbyLng,
    this.nearbyRadiusKm,
  });

  Map<String, dynamic> toQueryParameters() {
    final clampedLimit = limit.clamp(1, kMatchmakingFeedMaxLimit);
    final params = <String, dynamic>{
      'fromTeamId': fromTeamId,
      'page': page.toString(),
      'limit': clampedLimit.toString(),
    };
    if (nearbyLat != null && nearbyLng != null) {
      params.addAll(
        nearbyLocationQueryParameters(
          nearbyLat: nearbyLat!,
          nearbyLng: nearbyLng!,
          nearbyRadiusKm: nearbyRadiusKm,
        ),
      );
    }
    return params;
  }
}

/// Backend [ListNegotiationsFilterDto] / `ListNegotiationsFilterSchema`.
class ListNegotiationsFilterQuery {
  final String? teamId;
  final NegotiationListType type;
  final TeamMatchStatus? status;
  final int page;
  final int limit;

  const ListNegotiationsFilterQuery({
    this.teamId,
    this.type = NegotiationListType.all,
    this.status,
    this.page = 1,
    this.limit = 10,
  });

  Map<String, dynamic> toQueryParameters() {
    final clampedLimit = limit.clamp(1, kMatchmakingListRequestsMaxLimit);
    final params = <String, dynamic>{
      'type': type.name,
      'page': page.toString(),
      'limit': clampedLimit.toString(),
    };
    if (teamId != null) params['teamId'] = teamId!;
    if (status != null) {
      params['status'] = _$teamMatchStatusToApiString(status!);
    }
    return params;
  }
}

String _$teamMatchStatusToApiString(TeamMatchStatus s) => switch (s) {
  TeamMatchStatus.scheduleFinalized => 'schedule_finalized',
  _ => s.name,
};

// --- Request bodies ---

@JsonSerializable(includeIfNull: false)
class SendMatchRequest {
  @JsonKey(name: 'fromTeamId')
  final String fromTeamId;
  @JsonKey(name: 'toTeamId')
  final String toTeamId;
  final String? notes;
  @JsonKey(name: 'expiresInMinutes', defaultValue: 120)
  final int expiresInMinutes;

  SendMatchRequest({
    required this.fromTeamId,
    required this.toTeamId,
    this.notes,
    this.expiresInMinutes = 120,
  });

  factory SendMatchRequest.fromJson(Map<String, dynamic> json) =>
      _$SendMatchRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SendMatchRequestToJson(this);
}

@JsonSerializable()
class SetTeamOpenForMatchRequest {
  @JsonKey(name: 'isOpen')
  final bool isOpen;

  SetTeamOpenForMatchRequest({required this.isOpen});

  factory SetTeamOpenForMatchRequest.fromJson(Map<String, dynamic> json) =>
      _$SetTeamOpenForMatchRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SetTeamOpenForMatchRequestToJson(this);
}

@JsonSerializable(includeIfNull: false)
class RespondMatchRequest {
  @JsonKey(name: 'actorTeamId')
  final String actorTeamId;
  final MatchResponseAction action;

  RespondMatchRequest({required this.actorTeamId, required this.action});

  factory RespondMatchRequest.fromJson(Map<String, dynamic> json) =>
      _$RespondMatchRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RespondMatchRequestToJson(this);
}

/// Body slot for [ProposeScheduleRequest] (`TimeSlotSchema`).
@JsonSerializable()
class ProposeScheduleTimeSlot {
  final DateTime startTime;
  final DateTime endTime;

  ProposeScheduleTimeSlot({required this.startTime, required this.endTime});

  factory ProposeScheduleTimeSlot.fromJson(Map<String, dynamic> json) =>
      _$ProposeScheduleTimeSlotFromJson(json);

  Map<String, dynamic> toJson() => _$ProposeScheduleTimeSlotToJson(this);
}

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ProposeScheduleRequest {
  @JsonKey(name: 'actorTeamId')
  final String actorTeamId;
  final List<ProposeScheduleTimeSlot>? proposedSlots;
  @JsonKey(name: 'proposedTurfIds')
  final List<String>? proposedTurfIds;
  final String? notes;

  ProposeScheduleRequest({
    required this.actorTeamId,
    this.proposedSlots,
    this.proposedTurfIds,
    this.notes,
  });

  factory ProposeScheduleRequest.fromJson(Map<String, dynamic> json) =>
      _$ProposeScheduleRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ProposeScheduleRequestToJson(this);
}

@JsonSerializable(includeIfNull: false)
class DecideSlotProposalRequest {
  @JsonKey(name: 'actorTeamId')
  final String actorTeamId;
  @JsonKey(name: 'proposalId')
  final String proposalId;
  final ProposalDecisionAction action;
  final String? reason;

  DecideSlotProposalRequest({
    required this.actorTeamId,
    required this.proposalId,
    required this.action,
    this.reason,
  });

  factory DecideSlotProposalRequest.fromJson(Map<String, dynamic> json) =>
      _$DecideSlotProposalRequestFromJson(json);

  Map<String, dynamic> toJson() => _$DecideSlotProposalRequestToJson(this);
}

@JsonSerializable(includeIfNull: false)
class DecideTurfProposalRequest {
  @JsonKey(name: 'actorTeamId')
  final String actorTeamId;
  @JsonKey(name: 'proposalId')
  final String proposalId;
  final ProposalDecisionAction action;
  final String? reason;

  DecideTurfProposalRequest({
    required this.actorTeamId,
    required this.proposalId,
    required this.action,
    this.reason,
  });

  factory DecideTurfProposalRequest.fromJson(Map<String, dynamic> json) =>
      _$DecideTurfProposalRequestFromJson(json);

  Map<String, dynamic> toJson() => _$DecideTurfProposalRequestToJson(this);
}

@JsonSerializable(includeIfNull: false)
class FinalizeScheduleRequest {
  @JsonKey(name: 'actorTeamId')
  final String actorTeamId;
  @JsonKey(name: 'slotProposalId')
  final String slotProposalId;
  @JsonKey(name: 'turfProposalId')
  final String turfProposalId;
  final String? notes;

  FinalizeScheduleRequest({
    required this.actorTeamId,
    required this.slotProposalId,
    required this.turfProposalId,
    this.notes,
  });

  factory FinalizeScheduleRequest.fromJson(Map<String, dynamic> json) =>
      _$FinalizeScheduleRequestFromJson(json);

  Map<String, dynamic> toJson() => _$FinalizeScheduleRequestToJson(this);
}

@JsonSerializable(includeIfNull: false)
class CancelNegotiationRequest {
  @JsonKey(name: 'actorTeamId')
  final String actorTeamId;
  final String? reason;

  CancelNegotiationRequest({required this.actorTeamId, this.reason});

  factory CancelNegotiationRequest.fromJson(Map<String, dynamic> json) =>
      _$CancelNegotiationRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CancelNegotiationRequestToJson(this);
}

@JsonSerializable(includeIfNull: false)
class RecordMatchResultRequest {
  @JsonKey(name: 'actorTeamId')
  final String actorTeamId;
  final MatchResultOutcome outcome;
  @JsonKey(name: 'winnerTeam')
  final String? winnerTeam;

  RecordMatchResultRequest({
    required this.actorTeamId,
    required this.outcome,
    this.winnerTeam,
  });

  factory RecordMatchResultRequest.fromJson(Map<String, dynamic> json) =>
      _$RecordMatchResultRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RecordMatchResultRequestToJson(this);
}
