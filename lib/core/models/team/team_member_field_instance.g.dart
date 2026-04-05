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
  TeamSportType.cricket: 'cricket',
  TeamSportType.football: 'football',
};
