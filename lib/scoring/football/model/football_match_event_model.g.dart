// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'football_match_event_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FootballMatchEvent _$FootballMatchEventFromJson(Map<String, dynamic> json) =>
    FootballMatchEvent(
      id: json['_id'] == null ? '' : _mongoIdFromJson(json['_id']),
      teamMatchId: const TeamMatchRefConverter().fromJson(json['teamMatchId']),
      sequence: (json['sequence'] as num).toInt(),
      kind: _kindFromApi(json['kind'] as String?),
      period: _periodFromJson(json['period']),
      beneficiaryTeamId: const TeamMatchRefConverter().fromJson(
        json['beneficiaryTeamId'],
      ),
      scoreDeltaTeamOne: (json['scoreDeltaTeamOne'] as num).toInt(),
      scoreDeltaTeamTwo: (json['scoreDeltaTeamTwo'] as num).toInt(),
      matchMinute: (json['matchMinute'] as num?)?.toInt(),
      primaryUserId: const UserConverter().fromJson(json['primaryUserId']),
      secondaryUserId: const UserConverter().fromJson(json['secondaryUserId']),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$FootballMatchEventToJson(FootballMatchEvent instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'teamMatchId': const TeamMatchRefConverter().toJson(instance.teamMatchId),
      'sequence': instance.sequence,
      'kind': _$FootballEventKindEnumMap[instance.kind]!,
      'period': _$MatchFootballPeriodEnumMap[instance.period]!,
      'matchMinute': instance.matchMinute,
      'beneficiaryTeamId': const TeamMatchRefConverter().toJson(
        instance.beneficiaryTeamId,
      ),
      'primaryUserId': const UserConverter().toJson(instance.primaryUserId),
      'secondaryUserId': const UserConverter().toJson(instance.secondaryUserId),
      'scoreDeltaTeamOne': instance.scoreDeltaTeamOne,
      'scoreDeltaTeamTwo': instance.scoreDeltaTeamTwo,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$FootballEventKindEnumMap = {
  FootballEventKind.goal: 'goal',
  FootballEventKind.ownGoal: 'own_goal',
  FootballEventKind.yellowCard: 'yellow_card',
  FootballEventKind.redCard: 'red_card',
  FootballEventKind.substitution: 'substitution',
  FootballEventKind.penaltyScored: 'penalty_scored',
  FootballEventKind.penaltyMissed: 'penalty_missed',
};

const _$MatchFootballPeriodEnumMap = {
  MatchFootballPeriod.firstHalf: 'first_half',
  MatchFootballPeriod.secondHalf: 'second_half',
  MatchFootballPeriod.extraFirst: 'extra_first',
  MatchFootballPeriod.extraSecond: 'extra_second',
  MatchFootballPeriod.penalties: 'penalties',
};
