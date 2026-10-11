import 'package:json_annotation/json_annotation.dart';

import '../../core/models/team/team_ref_converter.dart';
import '../../core/models/team/team_ref_field_instance.dart';
import '../../core/models/user_field_converters.dart';
import '../../core/models/user_field_instance.dart';
import '../../core/models/turf_booking/turf_booking_ref_converter.dart';
import '../../core/models/turf_booking/turf_booking_ref_field_instance.dart';
import '../../core/models/turf_field_converter.dart';
import '../../core/models/turf_field_instance.dart';
import '../../core/utils/mongo_id_util.dart';
import '../../team/model/team_model.dart';
import '../announced_players/model/announced_player_model.dart';

part 'team_match_model.g.dart';

/// Backend `TeamFilterDto.limit` / matchmaking feed — max 50.
const int kMatchmakingFeedMaxLimit = 50;

/// Backend `ListNegotiationsFilterSchema` — max 50.
const int kMatchmakingListRequestsMaxLimit = 50;

// --- Enums (backend string values) ---

/// Backend [TeamMatchSource].
enum TeamMatchSource { ranked, unranked }

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
  @JsonValue('abandoned')
  abandoned,
}

/// Backend [MatchProposalStatus].
enum MatchProposalStatus { pending, accepted, rejected, withdrawn, expired }

/// Backend `ListNegotiationsFilterSchema.type`.
enum NegotiationListType { incoming, outgoing, all }

/// Backend `ListNegotiationsFilterSchema.scope`.
enum NegotiationListScope { mine, all }

/// Backend `matchResponseActionSchema`.
enum MatchResponseAction { accept, reject }

/// Backend `proposalDecisionActionSchema`.
enum ProposalDecisionAction { accept, reject, withdraw }

/// Backend `RecordMatchResultSchema.outcome`.
enum MatchResultOutcome { ongoing, completed, draw }

// --- Nested document shapes ---

@JsonSerializable()
class GuestJoinSettingsModel {
  @JsonKey(defaultValue: false)
  final bool fromTeamOpen;
  @JsonKey(defaultValue: false)
  final bool toTeamOpen;
  @JsonKey(defaultValue: 0)
  final int maxPerTeam;

  const GuestJoinSettingsModel({
    this.fromTeamOpen = false,
    this.toTeamOpen = false,
    this.maxPerTeam = 0,
  });

  factory GuestJoinSettingsModel.fromJson(Map<String, dynamic> json) =>
      _$GuestJoinSettingsModelFromJson(json);

  Map<String, dynamic> toJson() => _$GuestJoinSettingsModelToJson(this);
}

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
  @JsonKey(name: 'proposalId', fromJson: mongoIdFromJson)
  final String proposalId;
  final TeamMatchTimeSlot slot;
  @JsonKey(name: 'proposedByTeamId', fromJson: mongoIdFromJson)
  final String proposedByTeamId;
  final MatchProposalStatus status;
  @JsonKey(name: 'decidedByTeamId', fromJson: mongoIdFromJsonNullable)
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
  @JsonKey(name: 'proposalId', fromJson: mongoIdFromJson)
  final String proposalId;

  /// Lean id or populated turf (see [turfIdHelper]).
  @JsonKey(name: 'turfId')
  @TurfConverter()
  final dynamic turfId;
  @JsonKey(name: 'proposedByTeamId', fromJson: mongoIdFromJson)
  final String proposedByTeamId;
  final MatchProposalStatus status;
  @JsonKey(name: 'decidedByTeamId', fromJson: mongoIdFromJsonNullable)
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

/// Backend embedded `inningsSummaries[]` item ([CricketInningsSummary]).
@JsonSerializable(explicitToJson: true)
class CricketInningsSummaryModel {
  final int runs;
  final int wickets;
  final int legalBalls;

  @JsonKey(name: 'battingTeamId')
  @TeamRefConverter()
  final dynamic battingTeamId;

  @JsonKey(name: 'bowlingTeamId')
  @TeamRefConverter()
  final dynamic bowlingTeamId;

  const CricketInningsSummaryModel({
    required this.runs,
    required this.wickets,
    required this.legalBalls,
    this.battingTeamId,
    this.bowlingTeamId,
  });

  factory CricketInningsSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$CricketInningsSummaryModelFromJson(json);

  Map<String, dynamic> toJson() => _$CricketInningsSummaryModelToJson(this);

  TeamRefFieldInstance get battingTeamHelper =>
      TeamRefFieldInstance(battingTeamId);

  TeamRefFieldInstance get bowlingTeamHelper =>
      TeamRefFieldInstance(bowlingTeamId);
}

/// Backend [FootballPeriod] on embedded football state.
enum MatchFootballPeriod {
  @JsonValue('first_half')
  firstHalf,
  @JsonValue('second_half')
  secondHalf,
  @JsonValue('extra_first')
  extraFirst,
  @JsonValue('extra_second')
  extraSecond,
  @JsonValue('penalties')
  penalties,
}

/// Backend embedded [CricketState].
@JsonSerializable(explicitToJson: true)
class CricketStateModel {
  final int maxOvers;

  /// Opening overs with a restricted field. Null on older matches (use the default).
  final int? powerplayOvers;

  final int currentInnings;

  /// Lean id or populated team subset ([TeamMemberFieldInstance]).
  @JsonKey(name: 'battingTeamId')
  @TeamRefConverter()
  final dynamic battingTeamId;

  /// Lean id or populated team subset ([TeamMemberFieldInstance]).
  @JsonKey(name: 'bowlingTeamId')
  @TeamRefConverter()
  final dynamic bowlingTeamId;

  @JsonKey(name: 'strikerUserId')
  @UserConverter()
  final dynamic strikerUserId;

  @JsonKey(name: 'nonStrikerUserId')
  @UserConverter()
  final dynamic nonStrikerUserId;

  @JsonKey(name: 'bowlerUserId')
  @UserConverter()
  final dynamic bowlerUserId;

  @JsonKey(
    name: 'fromTeamActiveParticipantIds',
    fromJson: mongoIdListFromJson,
    defaultValue: <String>[],
  )
  final List<String> fromTeamActiveParticipantIds;

  @JsonKey(
    name: 'toTeamActiveParticipantIds',
    fromJson: mongoIdListFromJson,
    defaultValue: <String>[],
  )
  final List<String> toTeamActiveParticipantIds;

  @JsonKey(defaultValue: <CricketInningsSummaryModel>[])
  final List<CricketInningsSummaryModel> inningsSummaries;

  const CricketStateModel({
    required this.maxOvers,
    this.powerplayOvers,
    required this.currentInnings,
    required this.battingTeamId,
    required this.bowlingTeamId,
    required this.inningsSummaries,
    this.strikerUserId,
    this.nonStrikerUserId,
    this.bowlerUserId,
    this.fromTeamActiveParticipantIds = const [],
    this.toTeamActiveParticipantIds = const [],
  });

  factory CricketStateModel.fromJson(Map<String, dynamic> json) =>
      _$CricketStateModelFromJson(json);

  Map<String, dynamic> toJson() => _$CricketStateModelToJson(this);

  TeamRefFieldInstance get battingTeamHelper =>
      TeamRefFieldInstance(battingTeamId);

  TeamRefFieldInstance get bowlingTeamHelper =>
      TeamRefFieldInstance(bowlingTeamId);

  UserFieldInstance get strikerUserHelper => UserFieldInstance(strikerUserId);

  UserFieldInstance get nonStrikerUserHelper =>
      UserFieldInstance(nonStrikerUserId);

  UserFieldInstance get bowlerUserHelper => UserFieldInstance(bowlerUserId);

  /// Stored value, or 6 for a T20-length game and 10 otherwise.
  int get powerplayOversOrDefault {
    final stored = powerplayOvers;
    if (stored == null) return defaultPowerplayOvers(maxOvers);
    if (stored < 0) return 0;
    if (stored > maxOvers) return maxOvers;
    return stored;
  }

  /// True while the innings has not yet used up the powerplay legal balls.
  bool isInPowerplay(int legalBalls) {
    final overs = powerplayOversOrDefault;
    return overs > 0 && legalBalls < overs * 6;
  }
}

/// T20-style opening powerplay, else the 50-over opening block.
int defaultPowerplayOvers(int maxOvers) {
  if (maxOvers <= 0) return 0;
  if (maxOvers <= 20) return maxOvers < 6 ? maxOvers : 6;
  return maxOvers < 10 ? maxOvers : 10;
}

/// Backend embedded `inningsSummaries[]` item ([FootballInningsSummary]).
@JsonSerializable(explicitToJson: true)
class FootballInningsSummaryModel {
  final int scoreTeamOne;
  final int scoreTeamTwo;
  final MatchFootballPeriod? period;

  const FootballInningsSummaryModel({
    required this.scoreTeamOne,
    required this.scoreTeamTwo,
    this.period,
  });

  factory FootballInningsSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$FootballInningsSummaryModelFromJson(json);

  Map<String, dynamic> toJson() => _$FootballInningsSummaryModelToJson(this);
}

/// Backend embedded [FootballState].
@JsonSerializable(explicitToJson: true)
class FootballStateModel {
  final int scoreTeamOne;
  final int scoreTeamTwo;
  final int currentInnings;
  final MatchFootballPeriod currentPeriod;
  final int? matchMinute;

  @JsonKey(defaultValue: <FootballInningsSummaryModel>[])
  final List<FootballInningsSummaryModel> inningsSummaries;

  final int timerElapsedMs;
  final int totalTimerElapsedMs;
  final DateTime? timerStartedAt;
  final bool isTimerPaused;

  @JsonKey(
    name: 'fromTeamActiveParticipantIds',
    fromJson: mongoIdListFromJson,
    defaultValue: <String>[],
  )
  final List<String> fromTeamActiveParticipantIds;

  @JsonKey(
    name: 'toTeamActiveParticipantIds',
    fromJson: mongoIdListFromJson,
    defaultValue: <String>[],
  )
  final List<String> toTeamActiveParticipantIds;

  const FootballStateModel({
    required this.scoreTeamOne,
    required this.scoreTeamTwo,
    this.currentInnings = 1,
    required this.currentPeriod,
    this.matchMinute,
    required this.inningsSummaries,
    this.timerElapsedMs = 0,
    this.totalTimerElapsedMs = 0,
    this.timerStartedAt,
    this.isTimerPaused = true,
    this.fromTeamActiveParticipantIds = const [],
    this.toTeamActiveParticipantIds = const [],
  });

  factory FootballStateModel.fromJson(Map<String, dynamic> json) =>
      _$FootballStateModelFromJson(json);

  Map<String, dynamic> toJson() => _$FootballStateModelToJson(this);
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
  @JsonKey(name: 'statusUpdatedBy', fromJson: mongoIdFromJsonNullable)
  final String? statusUpdatedBy;
  final DateTime? statusUpdatedAt;
  @JsonKey(defaultValue: <ProposedSlotModel>[])
  final List<ProposedSlotModel> proposedSlots;
  @JsonKey(defaultValue: <ProposedTurfModel>[])
  final List<ProposedTurfModel> proposedTurfs;
  @JsonKey(name: 'selectedSlotProposalId', fromJson: mongoIdFromJsonNullable)
  final String? selectedSlotProposalId;
  @JsonKey(name: 'selectedTurfProposalId', fromJson: mongoIdFromJsonNullable)
  final String? selectedTurfProposalId;

  /// Explicit venue — set by client; never derived from turf on the server.
  final LocationModel? venueLocation;

  /// Lean id or populated team subset when backend populates `winnerTeam`.
  @JsonKey(name: 'winnerTeam')
  @TeamRefConverter()
  final dynamic winnerTeam;
  final String? notes;

  /// Lean id or populated [TurfBookingModel] when backend populates `turfBookingId`.
  @JsonKey(name: 'turfBookingId')
  @TurfBookingRefConverter()
  final dynamic turfBookingId;
  final DateTime? expiresAt;
  final DateTime? closedAt;

  @JsonKey(defaultValue: <AnnouncedPlayerModel>[])
  final List<AnnouncedPlayerModel> announcedPlayers;
  final GuestJoinSettingsModel? guestJoin;

  final CricketStateModel? cricketState;
  final FootballStateModel? footballState;
  @JsonKey(name: 'tournamentId', fromJson: mongoIdFromJsonNullable)
  final String? tournamentId;
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
    this.venueLocation,
    this.winnerTeam,
    this.notes,
    this.turfBookingId,
    this.expiresAt,
    this.closedAt,
    this.announcedPlayers = const [],
    this.guestJoin,
    this.cricketState,
    this.footballState,
    this.tournamentId,
    this.createdAt,
    this.updatedAt,
  });

  factory TeamMatchModel.fromJson(Map<String, dynamic> json) =>
      _$TeamMatchModelFromJson(json);

  Map<String, dynamic> toJson() => _$TeamMatchModelToJson(this);

  TeamMatchModel copyWith({
    String? id,
    TeamMatchSource? source,
    dynamic fromTeam,
    dynamic toTeam,
    TeamSportType? sportType,
    TeamMatchStatus? status,
    String? statusUpdatedBy,
    DateTime? statusUpdatedAt,
    List<ProposedSlotModel>? proposedSlots,
    List<ProposedTurfModel>? proposedTurfs,
    String? selectedSlotProposalId,
    String? selectedTurfProposalId,
    LocationModel? venueLocation,
    dynamic winnerTeam,
    String? notes,
    dynamic turfBookingId,
    DateTime? expiresAt,
    DateTime? closedAt,
    List<AnnouncedPlayerModel>? announcedPlayers,
    GuestJoinSettingsModel? guestJoin,
    CricketStateModel? cricketState,
    FootballStateModel? footballState,
    String? tournamentId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TeamMatchModel(
      id: id ?? this.id,
      source: source ?? this.source,
      fromTeam: fromTeam ?? this.fromTeam,
      toTeam: toTeam ?? this.toTeam,
      sportType: sportType ?? this.sportType,
      status: status ?? this.status,
      statusUpdatedBy: statusUpdatedBy ?? this.statusUpdatedBy,
      statusUpdatedAt: statusUpdatedAt ?? this.statusUpdatedAt,
      proposedSlots: proposedSlots ?? this.proposedSlots,
      proposedTurfs: proposedTurfs ?? this.proposedTurfs,
      selectedSlotProposalId:
          selectedSlotProposalId ?? this.selectedSlotProposalId,
      selectedTurfProposalId:
          selectedTurfProposalId ?? this.selectedTurfProposalId,
      venueLocation: venueLocation ?? this.venueLocation,
      winnerTeam: winnerTeam ?? this.winnerTeam,
      notes: notes ?? this.notes,
      turfBookingId: turfBookingId ?? this.turfBookingId,
      expiresAt: expiresAt ?? this.expiresAt,
      closedAt: closedAt ?? this.closedAt,
      announcedPlayers: announcedPlayers ?? this.announcedPlayers,
      guestJoin: guestJoin ?? this.guestJoin,
      cricketState: cricketState ?? this.cricketState,
      footballState: footballState ?? this.footballState,
      tournamentId: tournamentId ?? this.tournamentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  TeamRefFieldInstance get fromTeamHelper => TeamRefFieldInstance(fromTeam);

  TeamRefFieldInstance get toTeamHelper => TeamRefFieldInstance(toTeam);

  TeamRefFieldInstance get winnerTeamHelper => TeamRefFieldInstance(winnerTeam);

  bool get isUnranked => source == TeamMatchSource.unranked;

  TurfBookingRefFieldInstance get turfBookingIdHelper =>
      TurfBookingRefFieldInstance(turfBookingId);

  String get versusLabel {
    final from = fromTeamHelper.bracketLabel;
    final to = toTeamHelper.bracketLabel;
    return '$from vs $to';
  }

  ProposedTurfModel? get selectedTurfProposal {
    if (selectedTurfProposalId != null) {
      for (final turf in proposedTurfs) {
        if (turf.proposalId == selectedTurfProposalId) return turf;
      }
    }
    for (final turf in proposedTurfs) {
      if (turf.status == MatchProposalStatus.accepted) return turf;
    }
    return null;
  }
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

  /// When non-empty, sent as `teamIds=id1,id2` (preferred over [teamId] for batches).
  final List<String>? teamIds;
  final NegotiationListType type;
  final TeamMatchStatus? status;

  /// When non-empty, sent as `statuses=a,b` (preferred over [status] for multiple).
  final List<TeamMatchStatus>? statuses;

  /// `mine` (default) or `all` — platform-wide listing.
  final NegotiationListScope scope;

  /// `ranked` or `unranked`. Null lists both.
  final TeamMatchSource? source;

  /// Case-insensitive filter on either team's name / shortName.
  final String? search;

  /// Backend `sportType` filter (e.g. cricket, football).
  final TeamSportType? sportType;

  /// Same format as turf search: `createdAt:desc`, optional multi: `a:asc,b:desc`.
  final String? sort;
  final int page;
  final int limit;

  const ListNegotiationsFilterQuery({
    this.teamId,
    this.teamIds,
    this.type = NegotiationListType.all,
    this.status,
    this.statuses,
    this.scope = NegotiationListScope.mine,
    this.source,
    this.search,
    this.sportType,
    this.sort,
    this.page = 1,
    this.limit = 10,
  });

  Map<String, dynamic> toQueryParameters() {
    final clampedLimit = limit.clamp(1, kMatchmakingListRequestsMaxLimit);
    final params = <String, dynamic>{
      if (type != NegotiationListType.all) 'type': type.name,
      'scope': scope.name,
      if (source != null) 'source': source!.name,
      'page': page.toString(),
      'limit': clampedLimit.toString(),
    };
    final ids = teamIds?.where((id) => id.isNotEmpty).toList();
    if (ids != null && ids.isNotEmpty) {
      params['teamIds'] = ids.join(',');
    } else if (teamId != null) {
      params['teamId'] = teamId!;
    }
    final statusList = statuses
        ?.map(_$teamMatchStatusToApiString)
        .where((s) => s.isNotEmpty)
        .toList();
    if (statusList != null && statusList.isNotEmpty) {
      params['statuses'] = statusList.join(',');
    } else if (status != null) {
      params['status'] = _$teamMatchStatusToApiString(status!);
    }
    final searchParam = search?.trim();
    if (searchParam != null && searchParam.isNotEmpty) {
      params['search'] = searchParam;
    }
    if (sportType != null) {
      params['sportType'] = sportType!.name;
    }
    final sortParam = sort;
    if (sortParam != null && sortParam.isNotEmpty) {
      params['sort'] = sortParam;
    }
    return params;
  }
}

/// Backend [ListPreMatchInboxFilterDto] — received / sent challenge tabs.
class ListPreMatchInboxFilterQuery {
  final NegotiationListType type;
  final String? teamId;
  final List<String>? teamIds;
  final String? sort;
  final int page;
  final int limit;

  const ListPreMatchInboxFilterQuery({
    required this.type,
    this.teamId,
    this.teamIds,
    this.sort,
    this.page = 1,
    this.limit = 10,
  }) : assert(
         type == NegotiationListType.incoming ||
             type == NegotiationListType.outgoing,
         'inbox type must be incoming or outgoing',
       );

  Map<String, dynamic> toQueryParameters() {
    final clampedLimit = limit.clamp(1, kMatchmakingListRequestsMaxLimit);
    final params = <String, dynamic>{
      'type': type.name,
      'page': page.toString(),
      'limit': clampedLimit.toString(),
    };
    final ids = teamIds?.where((id) => id.isNotEmpty).toList();
    if (ids != null && ids.isNotEmpty) {
      params['teamIds'] = ids.join(',');
    } else if (teamId != null) {
      params['teamId'] = teamId!;
    }
    final sortParam = sort;
    if (sortParam != null && sortParam.isNotEmpty) {
      params['sort'] = sortParam;
    }
    return params;
  }
}

String _$teamMatchStatusToApiString(TeamMatchStatus s) => switch (s) {
  TeamMatchStatus.scheduleFinalized => 'schedule_finalized',
  TeamMatchStatus.abandoned => 'abandoned',
  _ => s.name,
};

// --- Request bodies ---

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class CreateMatchRequest {
  final TeamMatchSource source;
  final String fromTeamId;
  final String toTeamId;
  final String? notes;
  final int? expiresInMinutes;
  final TeamMatchTimeSlot? slot;
  final String? turfId;
  final LocationModel? venueLocation;

  /// Unranked only — opens guest-join for nearby players.
  final bool? allowNearbyPlayers;

  const CreateMatchRequest({
    required this.source,
    required this.fromTeamId,
    required this.toTeamId,
    this.notes,
    this.expiresInMinutes,
    this.slot,
    this.turfId,
    this.venueLocation,
    this.allowNearbyPlayers,
  });

  factory CreateMatchRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateMatchRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateMatchRequestToJson(this);
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
  final String? actorTeamId;
  final String? reason;

  CancelNegotiationRequest({this.actorTeamId, this.reason});

  factory CancelNegotiationRequest.fromJson(Map<String, dynamic> json) =>
      _$CancelNegotiationRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CancelNegotiationRequestToJson(this);
}

/// Body for `POST /matchmaking/requests/:id/revoke`.
class RevokeMatchRequest {
  final String actorTeamId;

  const RevokeMatchRequest({required this.actorTeamId});

  Map<String, dynamic> toJson() => {'actorTeamId': actorTeamId};
}

/// Body for `PATCH /matchmaking/requests/:id` ([UpdateTeamMatchDto] / `UpdateTeamMatchSchema`).
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class UpdateTeamMatchRequest {
  final String? turfBookingId;
  final String? notes;

  /// New accepted slot; server creates the proposal and `selectedSlotProposalId`.
  final TeamMatchTimeSlot? slot;

  /// Turf id for a new accepted proposal; server creates `selectedTurfProposalId`.
  final String? turfId;

  /// Explicit venue only — never copied from turf on the server.
  final LocationModel? venueLocation;
  final String? selfAcceptTeamId;

  const UpdateTeamMatchRequest({
    this.turfBookingId,
    this.notes,
    this.slot,
    this.turfId,
    this.venueLocation,
    this.selfAcceptTeamId,
  });

  factory UpdateTeamMatchRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateTeamMatchRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateTeamMatchRequestToJson(this);
}

@JsonSerializable(includeIfNull: false)
class RecordMatchResultRequest {
  @JsonKey(name: 'actorTeamId')
  final String? actorTeamId;
  final MatchResultOutcome outcome;
  @JsonKey(name: 'winnerTeam')
  final String? winnerTeam;

  RecordMatchResultRequest({
    this.actorTeamId,
    required this.outcome,
    this.winnerTeam,
  });

  factory RecordMatchResultRequest.fromJson(Map<String, dynamic> json) =>
      _$RecordMatchResultRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RecordMatchResultRequestToJson(this);
}
