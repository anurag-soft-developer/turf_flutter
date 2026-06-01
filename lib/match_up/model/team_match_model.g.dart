// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_match_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TeamMatchTimeSlot _$TeamMatchTimeSlotFromJson(Map<String, dynamic> json) =>
    TeamMatchTimeSlot(
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
    );

Map<String, dynamic> _$TeamMatchTimeSlotToJson(TeamMatchTimeSlot instance) =>
    <String, dynamic>{
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime.toIso8601String(),
    };

ProposedSlotModel _$ProposedSlotModelFromJson(Map<String, dynamic> json) =>
    ProposedSlotModel(
      proposalId: _objectIdFromJson(json['proposalId']),
      slot: TeamMatchTimeSlot.fromJson(json['slot'] as Map<String, dynamic>),
      proposedByTeamId: _objectIdFromJson(json['proposedByTeamId']),
      status: $enumDecode(_$MatchProposalStatusEnumMap, json['status']),
      decidedByTeamId: _objectIdFromJsonNullable(json['decidedByTeamId']),
      decidedAt: json['decidedAt'] == null
          ? null
          : DateTime.parse(json['decidedAt'] as String),
      reason: json['reason'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$ProposedSlotModelToJson(ProposedSlotModel instance) =>
    <String, dynamic>{
      'proposalId': instance.proposalId,
      'slot': instance.slot.toJson(),
      'proposedByTeamId': instance.proposedByTeamId,
      'status': _$MatchProposalStatusEnumMap[instance.status]!,
      'decidedByTeamId': instance.decidedByTeamId,
      'decidedAt': instance.decidedAt?.toIso8601String(),
      'reason': instance.reason,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$MatchProposalStatusEnumMap = {
  MatchProposalStatus.pending: 'pending',
  MatchProposalStatus.accepted: 'accepted',
  MatchProposalStatus.rejected: 'rejected',
  MatchProposalStatus.withdrawn: 'withdrawn',
  MatchProposalStatus.expired: 'expired',
};

ProposedTurfModel _$ProposedTurfModelFromJson(Map<String, dynamic> json) =>
    ProposedTurfModel(
      proposalId: _objectIdFromJson(json['proposalId']),
      turfId: const TurfConverter().fromJson(json['turfId']),
      proposedByTeamId: _objectIdFromJson(json['proposedByTeamId']),
      status: $enumDecode(_$MatchProposalStatusEnumMap, json['status']),
      decidedByTeamId: _objectIdFromJsonNullable(json['decidedByTeamId']),
      decidedAt: json['decidedAt'] == null
          ? null
          : DateTime.parse(json['decidedAt'] as String),
      reason: json['reason'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$ProposedTurfModelToJson(ProposedTurfModel instance) =>
    <String, dynamic>{
      'proposalId': instance.proposalId,
      'turfId': const TurfConverter().toJson(instance.turfId),
      'proposedByTeamId': instance.proposedByTeamId,
      'status': _$MatchProposalStatusEnumMap[instance.status]!,
      'decidedByTeamId': instance.decidedByTeamId,
      'decidedAt': instance.decidedAt?.toIso8601String(),
      'reason': instance.reason,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

CricketInningsSummaryModel _$CricketInningsSummaryModelFromJson(
  Map<String, dynamic> json,
) => CricketInningsSummaryModel(
  runs: (json['runs'] as num).toInt(),
  wickets: (json['wickets'] as num).toInt(),
  legalBalls: (json['legalBalls'] as num).toInt(),
  battingTeamId: const TeamRefConverter().fromJson(json['battingTeamId']),
  bowlingTeamId: const TeamRefConverter().fromJson(json['bowlingTeamId']),
);

Map<String, dynamic> _$CricketInningsSummaryModelToJson(
  CricketInningsSummaryModel instance,
) => <String, dynamic>{
  'runs': instance.runs,
  'wickets': instance.wickets,
  'legalBalls': instance.legalBalls,
  'battingTeamId': const TeamRefConverter().toJson(instance.battingTeamId),
  'bowlingTeamId': const TeamRefConverter().toJson(instance.bowlingTeamId),
};

CricketStateModel _$CricketStateModelFromJson(
  Map<String, dynamic> json,
) => CricketStateModel(
  maxOvers: (json['maxOvers'] as num).toInt(),
  currentInnings: (json['currentInnings'] as num).toInt(),
  battingTeamId: const TeamRefConverter().fromJson(json['battingTeamId']),
  bowlingTeamId: const TeamRefConverter().fromJson(json['bowlingTeamId']),
  inningsSummaries:
      (json['inningsSummaries'] as List<dynamic>?)
          ?.map(
            (e) =>
                CricketInningsSummaryModel.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      [],
  strikerUserId: const UserConverter().fromJson(json['strikerUserId']),
  nonStrikerUserId: const UserConverter().fromJson(json['nonStrikerUserId']),
  bowlerUserId: const UserConverter().fromJson(json['bowlerUserId']),
);

Map<String, dynamic> _$CricketStateModelToJson(
  CricketStateModel instance,
) => <String, dynamic>{
  'maxOvers': instance.maxOvers,
  'currentInnings': instance.currentInnings,
  'battingTeamId': const TeamRefConverter().toJson(instance.battingTeamId),
  'bowlingTeamId': const TeamRefConverter().toJson(instance.bowlingTeamId),
  'strikerUserId': const UserConverter().toJson(instance.strikerUserId),
  'nonStrikerUserId': const UserConverter().toJson(instance.nonStrikerUserId),
  'bowlerUserId': const UserConverter().toJson(instance.bowlerUserId),
  'inningsSummaries': instance.inningsSummaries.map((e) => e.toJson()).toList(),
};

FootballInningsSummaryModel _$FootballInningsSummaryModelFromJson(
  Map<String, dynamic> json,
) => FootballInningsSummaryModel(
  scoreTeamOne: (json['scoreTeamOne'] as num).toInt(),
  scoreTeamTwo: (json['scoreTeamTwo'] as num).toInt(),
  period: $enumDecodeNullable(_$MatchFootballPeriodEnumMap, json['period']),
);

Map<String, dynamic> _$FootballInningsSummaryModelToJson(
  FootballInningsSummaryModel instance,
) => <String, dynamic>{
  'scoreTeamOne': instance.scoreTeamOne,
  'scoreTeamTwo': instance.scoreTeamTwo,
  'period': _$MatchFootballPeriodEnumMap[instance.period],
};

const _$MatchFootballPeriodEnumMap = {
  MatchFootballPeriod.firstHalf: 'first_half',
  MatchFootballPeriod.secondHalf: 'second_half',
  MatchFootballPeriod.extraFirst: 'extra_first',
  MatchFootballPeriod.extraSecond: 'extra_second',
  MatchFootballPeriod.penalties: 'penalties',
};

FootballStateModel _$FootballStateModelFromJson(Map<String, dynamic> json) =>
    FootballStateModel(
      scoreTeamOne: (json['scoreTeamOne'] as num).toInt(),
      scoreTeamTwo: (json['scoreTeamTwo'] as num).toInt(),
      currentInnings: (json['currentInnings'] as num?)?.toInt() ?? 1,
      currentPeriod: $enumDecode(
        _$MatchFootballPeriodEnumMap,
        json['currentPeriod'],
      ),
      matchMinute: (json['matchMinute'] as num?)?.toInt(),
      inningsSummaries:
          (json['inningsSummaries'] as List<dynamic>?)
              ?.map(
                (e) => FootballInningsSummaryModel.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          [],
      timerElapsedMs: (json['timerElapsedMs'] as num?)?.toInt() ?? 0,
      totalTimerElapsedMs: (json['totalTimerElapsedMs'] as num?)?.toInt() ?? 0,
      timerStartedAt: json['timerStartedAt'] == null
          ? null
          : DateTime.parse(json['timerStartedAt'] as String),
      isTimerPaused: json['isTimerPaused'] as bool? ?? true,
    );

Map<String, dynamic> _$FootballStateModelToJson(
  FootballStateModel instance,
) => <String, dynamic>{
  'scoreTeamOne': instance.scoreTeamOne,
  'scoreTeamTwo': instance.scoreTeamTwo,
  'currentInnings': instance.currentInnings,
  'currentPeriod': _$MatchFootballPeriodEnumMap[instance.currentPeriod]!,
  'matchMinute': instance.matchMinute,
  'inningsSummaries': instance.inningsSummaries.map((e) => e.toJson()).toList(),
  'timerElapsedMs': instance.timerElapsedMs,
  'totalTimerElapsedMs': instance.totalTimerElapsedMs,
  'timerStartedAt': instance.timerStartedAt?.toIso8601String(),
  'isTimerPaused': instance.isTimerPaused,
};

TeamMatchModel _$TeamMatchModelFromJson(
  Map<String, dynamic> json,
) => TeamMatchModel(
  id: json['_id'] as String?,
  source: $enumDecode(_$TeamMatchSourceEnumMap, json['source']),
  fromTeam: const TeamRefConverter().fromJson(json['fromTeam']),
  toTeam: const TeamRefConverter().fromJson(json['toTeam']),
  sportType: $enumDecode(_$TeamSportTypeEnumMap, json['sportType']),
  status: $enumDecode(_$TeamMatchStatusEnumMap, json['status']),
  statusUpdatedBy: _objectIdFromJsonNullable(json['statusUpdatedBy']),
  statusUpdatedAt: json['statusUpdatedAt'] == null
      ? null
      : DateTime.parse(json['statusUpdatedAt'] as String),
  proposedSlots:
      (json['proposedSlots'] as List<dynamic>?)
          ?.map((e) => ProposedSlotModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  proposedTurfs:
      (json['proposedTurfs'] as List<dynamic>?)
          ?.map((e) => ProposedTurfModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  selectedSlotProposalId: _objectIdFromJsonNullable(
    json['selectedSlotProposalId'],
  ),
  selectedTurfProposalId: _objectIdFromJsonNullable(
    json['selectedTurfProposalId'],
  ),
  winnerTeam: const TeamRefConverter().fromJson(json['winnerTeam']),
  notes: json['notes'] as String?,
  turfBookingId: const TurfBookingRefConverter().fromJson(
    json['turfBookingId'],
  ),
  expiresAt: json['expiresAt'] == null
      ? null
      : DateTime.parse(json['expiresAt'] as String),
  closedAt: json['closedAt'] == null
      ? null
      : DateTime.parse(json['closedAt'] as String),
  announcedPlayers:
      (json['announcedPlayers'] as List<dynamic>?)
          ?.map((e) => AnnouncedPlayerModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  cricketState: json['cricketState'] == null
      ? null
      : CricketStateModel.fromJson(
          json['cricketState'] as Map<String, dynamic>,
        ),
  footballState: json['footballState'] == null
      ? null
      : FootballStateModel.fromJson(
          json['footballState'] as Map<String, dynamic>,
        ),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$TeamMatchModelToJson(
  TeamMatchModel instance,
) => <String, dynamic>{
  '_id': instance.id,
  'source': _$TeamMatchSourceEnumMap[instance.source]!,
  'fromTeam': const TeamRefConverter().toJson(instance.fromTeam),
  'toTeam': const TeamRefConverter().toJson(instance.toTeam),
  'sportType': _$TeamSportTypeEnumMap[instance.sportType]!,
  'status': _$TeamMatchStatusEnumMap[instance.status]!,
  'statusUpdatedBy': instance.statusUpdatedBy,
  'statusUpdatedAt': instance.statusUpdatedAt?.toIso8601String(),
  'proposedSlots': instance.proposedSlots.map((e) => e.toJson()).toList(),
  'proposedTurfs': instance.proposedTurfs.map((e) => e.toJson()).toList(),
  'selectedSlotProposalId': instance.selectedSlotProposalId,
  'selectedTurfProposalId': instance.selectedTurfProposalId,
  'winnerTeam': const TeamRefConverter().toJson(instance.winnerTeam),
  'notes': instance.notes,
  'turfBookingId': const TurfBookingRefConverter().toJson(
    instance.turfBookingId,
  ),
  'expiresAt': instance.expiresAt?.toIso8601String(),
  'closedAt': instance.closedAt?.toIso8601String(),
  'announcedPlayers': instance.announcedPlayers.map((e) => e.toJson()).toList(),
  'cricketState': instance.cricketState?.toJson(),
  'footballState': instance.footballState?.toJson(),
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};

const _$TeamMatchSourceEnumMap = {TeamMatchSource.feed: 'feed'};

const _$TeamSportTypeEnumMap = {
  TeamSportType.cricket: 'cricket',
  TeamSportType.football: 'football',
};

const _$TeamMatchStatusEnumMap = {
  TeamMatchStatus.requested: 'requested',
  TeamMatchStatus.accepted: 'accepted',
  TeamMatchStatus.negotiating: 'negotiating',
  TeamMatchStatus.scheduleFinalized: 'schedule_finalized',
  TeamMatchStatus.rejected: 'rejected',
  TeamMatchStatus.expired: 'expired',
  TeamMatchStatus.cancelled: 'cancelled',
  TeamMatchStatus.ongoing: 'ongoing',
  TeamMatchStatus.completed: 'completed',
  TeamMatchStatus.draw: 'draw',
  TeamMatchStatus.abandoned: 'abandoned',
};

SendMatchRequest _$SendMatchRequestFromJson(Map<String, dynamic> json) =>
    SendMatchRequest(
      fromTeamId: json['fromTeamId'] as String,
      toTeamId: json['toTeamId'] as String,
      notes: json['notes'] as String?,
      expiresInMinutes: (json['expiresInMinutes'] as num?)?.toInt() ?? 120,
    );

Map<String, dynamic> _$SendMatchRequestToJson(SendMatchRequest instance) =>
    <String, dynamic>{
      'fromTeamId': instance.fromTeamId,
      'toTeamId': instance.toTeamId,
      'notes': ?instance.notes,
      'expiresInMinutes': ?instance.expiresInMinutes,
    };

SetTeamOpenForMatchRequest _$SetTeamOpenForMatchRequestFromJson(
  Map<String, dynamic> json,
) => SetTeamOpenForMatchRequest(isOpen: json['isOpen'] as bool);

Map<String, dynamic> _$SetTeamOpenForMatchRequestToJson(
  SetTeamOpenForMatchRequest instance,
) => <String, dynamic>{'isOpen': instance.isOpen};

RespondMatchRequest _$RespondMatchRequestFromJson(Map<String, dynamic> json) =>
    RespondMatchRequest(
      actorTeamId: json['actorTeamId'] as String,
      action: $enumDecode(_$MatchResponseActionEnumMap, json['action']),
    );

Map<String, dynamic> _$RespondMatchRequestToJson(
  RespondMatchRequest instance,
) => <String, dynamic>{
  'actorTeamId': instance.actorTeamId,
  'action': _$MatchResponseActionEnumMap[instance.action]!,
};

const _$MatchResponseActionEnumMap = {
  MatchResponseAction.accept: 'accept',
  MatchResponseAction.reject: 'reject',
};

ProposeScheduleTimeSlot _$ProposeScheduleTimeSlotFromJson(
  Map<String, dynamic> json,
) => ProposeScheduleTimeSlot(
  startTime: DateTime.parse(json['startTime'] as String),
  endTime: DateTime.parse(json['endTime'] as String),
);

Map<String, dynamic> _$ProposeScheduleTimeSlotToJson(
  ProposeScheduleTimeSlot instance,
) => <String, dynamic>{
  'startTime': instance.startTime.toIso8601String(),
  'endTime': instance.endTime.toIso8601String(),
};

ProposeScheduleRequest _$ProposeScheduleRequestFromJson(
  Map<String, dynamic> json,
) => ProposeScheduleRequest(
  actorTeamId: json['actorTeamId'] as String,
  proposedSlots: (json['proposedSlots'] as List<dynamic>?)
      ?.map((e) => ProposeScheduleTimeSlot.fromJson(e as Map<String, dynamic>))
      .toList(),
  proposedTurfIds: (json['proposedTurfIds'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$ProposeScheduleRequestToJson(
  ProposeScheduleRequest instance,
) => <String, dynamic>{
  'actorTeamId': instance.actorTeamId,
  'proposedSlots': ?instance.proposedSlots?.map((e) => e.toJson()).toList(),
  'proposedTurfIds': ?instance.proposedTurfIds,
  'notes': ?instance.notes,
};

DecideSlotProposalRequest _$DecideSlotProposalRequestFromJson(
  Map<String, dynamic> json,
) => DecideSlotProposalRequest(
  actorTeamId: json['actorTeamId'] as String,
  proposalId: json['proposalId'] as String,
  action: $enumDecode(_$ProposalDecisionActionEnumMap, json['action']),
  reason: json['reason'] as String?,
);

Map<String, dynamic> _$DecideSlotProposalRequestToJson(
  DecideSlotProposalRequest instance,
) => <String, dynamic>{
  'actorTeamId': instance.actorTeamId,
  'proposalId': instance.proposalId,
  'action': _$ProposalDecisionActionEnumMap[instance.action]!,
  'reason': ?instance.reason,
};

const _$ProposalDecisionActionEnumMap = {
  ProposalDecisionAction.accept: 'accept',
  ProposalDecisionAction.reject: 'reject',
  ProposalDecisionAction.withdraw: 'withdraw',
};

DecideTurfProposalRequest _$DecideTurfProposalRequestFromJson(
  Map<String, dynamic> json,
) => DecideTurfProposalRequest(
  actorTeamId: json['actorTeamId'] as String,
  proposalId: json['proposalId'] as String,
  action: $enumDecode(_$ProposalDecisionActionEnumMap, json['action']),
  reason: json['reason'] as String?,
);

Map<String, dynamic> _$DecideTurfProposalRequestToJson(
  DecideTurfProposalRequest instance,
) => <String, dynamic>{
  'actorTeamId': instance.actorTeamId,
  'proposalId': instance.proposalId,
  'action': _$ProposalDecisionActionEnumMap[instance.action]!,
  'reason': ?instance.reason,
};

FinalizeScheduleRequest _$FinalizeScheduleRequestFromJson(
  Map<String, dynamic> json,
) => FinalizeScheduleRequest(
  actorTeamId: json['actorTeamId'] as String,
  slotProposalId: json['slotProposalId'] as String,
  turfProposalId: json['turfProposalId'] as String,
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$FinalizeScheduleRequestToJson(
  FinalizeScheduleRequest instance,
) => <String, dynamic>{
  'actorTeamId': instance.actorTeamId,
  'slotProposalId': instance.slotProposalId,
  'turfProposalId': instance.turfProposalId,
  'notes': ?instance.notes,
};

CancelNegotiationRequest _$CancelNegotiationRequestFromJson(
  Map<String, dynamic> json,
) => CancelNegotiationRequest(
  actorTeamId: json['actorTeamId'] as String,
  reason: json['reason'] as String?,
);

Map<String, dynamic> _$CancelNegotiationRequestToJson(
  CancelNegotiationRequest instance,
) => <String, dynamic>{
  'actorTeamId': instance.actorTeamId,
  'reason': ?instance.reason,
};

UpdateTeamMatchRequest _$UpdateTeamMatchRequestFromJson(
  Map<String, dynamic> json,
) => UpdateTeamMatchRequest(
  turfBookingId: json['turfBookingId'] as String?,
  notes: json['notes'] as String?,
  slot: json['slot'] == null
      ? null
      : TeamMatchTimeSlot.fromJson(json['slot'] as Map<String, dynamic>),
  turfId: json['turfId'] as String?,
  selfAcceptTeamId: json['selfAcceptTeamId'] as String?,
);

Map<String, dynamic> _$UpdateTeamMatchRequestToJson(
  UpdateTeamMatchRequest instance,
) => <String, dynamic>{
  'turfBookingId': ?instance.turfBookingId,
  'notes': ?instance.notes,
  'slot': ?instance.slot?.toJson(),
  'turfId': ?instance.turfId,
  'selfAcceptTeamId': ?instance.selfAcceptTeamId,
};

RecordMatchResultRequest _$RecordMatchResultRequestFromJson(
  Map<String, dynamic> json,
) => RecordMatchResultRequest(
  actorTeamId: json['actorTeamId'] as String,
  outcome: $enumDecode(_$MatchResultOutcomeEnumMap, json['outcome']),
  winnerTeam: json['winnerTeam'] as String?,
);

Map<String, dynamic> _$RecordMatchResultRequestToJson(
  RecordMatchResultRequest instance,
) => <String, dynamic>{
  'actorTeamId': instance.actorTeamId,
  'outcome': _$MatchResultOutcomeEnumMap[instance.outcome]!,
  'winnerTeam': ?instance.winnerTeam,
};

const _$MatchResultOutcomeEnumMap = {
  MatchResultOutcome.ongoing: 'ongoing',
  MatchResultOutcome.completed: 'completed',
  MatchResultOutcome.draw: 'draw',
};
