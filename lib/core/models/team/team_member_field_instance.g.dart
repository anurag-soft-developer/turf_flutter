// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_member_field_instance.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TeamMemberFieldInstance _$TeamMemberFieldInstanceFromJson(
  Map<String, dynamic> json,
) => TeamMemberFieldInstance(
  id: json['_id'] as String?,
  name: json['name'] as String,
  logo: json['logo'] as String? ?? '',
  location: json['location'] == null
      ? null
      : LocationModel.fromJson(json['location'] as Map<String, dynamic>),
  sportType: $enumDecode(_$TeamSportTypeEnumMap, json['sportType']),
);

Map<String, dynamic> _$TeamMemberFieldInstanceToJson(
  TeamMemberFieldInstance instance,
) => <String, dynamic>{
  '_id': instance.id,
  'name': instance.name,
  'logo': instance.logo,
  'location': instance.location?.toJson(),
  'sportType': _$TeamSportTypeEnumMap[instance.sportType]!,
};

const _$TeamSportTypeEnumMap = {
  TeamSportType.football: 'football',
  TeamSportType.cricket: 'cricket',
  TeamSportType.basketball: 'basketball',
  TeamSportType.badminton: 'badminton',
  TeamSportType.tennis: 'tennis',
  TeamSportType.volleyball: 'volleyball',
  TeamSportType.hockey: 'hockey',
  TeamSportType.table_tennis: 'table_tennis',
  TeamSportType.squash: 'squash',
  TeamSportType.futsal: 'futsal',
  TeamSportType.kabaddi: 'kabaddi',
  TeamSportType.pickleball: 'pickleball',
  TeamSportType.rugby: 'rugby',
  TeamSportType.baseball: 'baseball',
  TeamSportType.softball: 'softball',
  TeamSportType.handball: 'handball',
  TeamSportType.throwball: 'throwball',
  TeamSportType.netball: 'netball',
  TeamSportType.athletics: 'athletics',
  TeamSportType.boxing: 'boxing',
  TeamSportType.martial_arts: 'martial_arts',
  TeamSportType.skating: 'skating',
  TeamSportType.golf: 'golf',
  TeamSportType.swimming: 'swimming',
};
