// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cricket_ball_event_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CricketBallEvent _$CricketBallEventFromJson(Map<String, dynamic> json) =>
    CricketBallEvent(
      ballInOverAfter: (json['ballInOverAfter'] as num).toInt(),
      strikerUserId: const UserConverter().fromJson(json['strikerUserId']),
      nonStrikerUserId: const UserConverter().fromJson(
        json['nonStrikerUserId'],
      ),
      runsOffBat: (json['runsOffBat'] as num).toInt(),
      extrasWide: (json['extrasWide'] as num).toInt(),
      extrasNoBall: json['extrasNoBall'] as bool,
      extrasBye: (json['extrasBye'] as num).toInt(),
      extrasLegBye: (json['extrasLegBye'] as num).toInt(),
      isWicket: json['isWicket'] as bool,
      totalRunsOnDelivery: (json['totalRunsOnDelivery'] as num).toInt(),
      isLegalDelivery: json['isLegalDelivery'] as bool,
      wicketsFallen: (json['wicketsFallen'] as num).toInt(),
      wicketKind: $enumDecodeNullable(
        _$CricketWicketKindEnumMap,
        json['wicketKind'],
      ),
      dismissedUserId: const UserConverter().fromJson(json['dismissedUserId']),
      primaryFielderUserId: const UserConverter().fromJson(
        json['primaryFielderUserId'],
      ),
    );

Map<String, dynamic> _$CricketBallEventToJson(
  CricketBallEvent instance,
) => <String, dynamic>{
  'ballInOverAfter': instance.ballInOverAfter,
  'strikerUserId': const UserConverter().toJson(instance.strikerUserId),
  'nonStrikerUserId': const UserConverter().toJson(instance.nonStrikerUserId),
  'runsOffBat': instance.runsOffBat,
  'extrasWide': instance.extrasWide,
  'extrasNoBall': instance.extrasNoBall,
  'extrasBye': instance.extrasBye,
  'extrasLegBye': instance.extrasLegBye,
  'isWicket': instance.isWicket,
  'wicketKind': _$CricketWicketKindEnumMap[instance.wicketKind],
  'dismissedUserId': const UserConverter().toJson(instance.dismissedUserId),
  'primaryFielderUserId': const UserConverter().toJson(
    instance.primaryFielderUserId,
  ),
  'totalRunsOnDelivery': instance.totalRunsOnDelivery,
  'isLegalDelivery': instance.isLegalDelivery,
  'wicketsFallen': instance.wicketsFallen,
};

const _$CricketWicketKindEnumMap = {
  CricketWicketKind.bowled: 'bowled',
  CricketWicketKind.caught: 'caught',
  CricketWicketKind.lbw: 'lbw',
  CricketWicketKind.runOut: 'run_out',
  CricketWicketKind.stumped: 'stumped',
  CricketWicketKind.hitWicket: 'hit_wicket',
  CricketWicketKind.other: 'other',
};

CricketOverEvent _$CricketOverEventFromJson(Map<String, dynamic> json) =>
    CricketOverEvent(
      id: json['_id'] == null ? '' : _mongoIdFromJson(json['_id']),
      teamMatchId: const TeamMatchRefConverter().fromJson(json['teamMatchId']),
      bowlerUserId: const UserConverter().fromJson(json['bowlerUserId']),
      sequence: (json['sequence'] as num).toInt(),
      innings: (json['innings'] as num).toInt(),
      overAfter: (json['overAfter'] as num).toInt(),
      ballEvents:
          (json['ballEvents'] as List<dynamic>?)
              ?.map((e) => CricketBallEvent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$CricketOverEventToJson(CricketOverEvent instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'teamMatchId': const TeamMatchRefConverter().toJson(instance.teamMatchId),
      'bowlerUserId': const UserConverter().toJson(instance.bowlerUserId),
      'sequence': instance.sequence,
      'innings': instance.innings,
      'overAfter': instance.overAfter,
      'ballEvents': instance.ballEvents.map((e) => e.toJson()).toList(),
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
