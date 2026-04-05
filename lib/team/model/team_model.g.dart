// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PromoteOwnerRequest _$PromoteOwnerRequestFromJson(Map<String, dynamic> json) =>
    PromoteOwnerRequest(userId: json['userId'] as String);

Map<String, dynamic> _$PromoteOwnerRequestToJson(
  PromoteOwnerRequest instance,
) => <String, dynamic>{'userId': instance.userId};

CreateTeamRequest _$CreateTeamRequestFromJson(Map<String, dynamic> json) =>
    CreateTeamRequest(
      name: json['name'] as String,
      description: json['description'] as String?,
      sportType: $enumDecode(_$TeamSportTypeEnumMap, json['sportType']),
      maxRosterSize: (json['maxRosterSize'] as num).toInt(),
      maxPendingJoinRequests: (json['maxPendingJoinRequests'] as num).toInt(),
      logo: json['logo'] as String?,
      coverImages: (json['coverImages'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      visibility: $enumDecode(_$TeamVisibilityEnumMap, json['visibility']),
      joinMode: $enumDecode(_$TeamJoinModeEnumMap, json['joinMode']),
      location: json['location'] == null
          ? null
          : LocationModel.fromJson(json['location'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CreateTeamRequestToJson(CreateTeamRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'sportType': _$TeamSportTypeEnumMap[instance.sportType]!,
      'maxRosterSize': instance.maxRosterSize,
      'maxPendingJoinRequests': instance.maxPendingJoinRequests,
      'logo': instance.logo,
      'coverImages': instance.coverImages,
      'visibility': _$TeamVisibilityEnumMap[instance.visibility]!,
      'joinMode': _$TeamJoinModeEnumMap[instance.joinMode]!,
      'location': instance.location?.toJson(),
    };

const _$TeamSportTypeEnumMap = {
  TeamSportType.cricket: 'cricket',
  TeamSportType.football: 'football',
};

const _$TeamVisibilityEnumMap = {
  TeamVisibility.public: 'public',
  TeamVisibility.private: 'private',
};

const _$TeamJoinModeEnumMap = {
  TeamJoinMode.open: 'open',
  TeamJoinMode.approval: 'approval',
};

UpdateTeamRequest _$UpdateTeamRequestFromJson(Map<String, dynamic> json) =>
    UpdateTeamRequest(
      name: json['name'] as String?,
      description: json['description'] as String?,
      sportType: $enumDecodeNullable(_$TeamSportTypeEnumMap, json['sportType']),
      maxRosterSize: (json['maxRosterSize'] as num?)?.toInt(),
      maxPendingJoinRequests: (json['maxPendingJoinRequests'] as num?)?.toInt(),
      logo: json['logo'] as String?,
      coverImages: (json['coverImages'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      visibility: $enumDecodeNullable(
        _$TeamVisibilityEnumMap,
        json['visibility'],
      ),
      joinMode: $enumDecodeNullable(_$TeamJoinModeEnumMap, json['joinMode']),
      status: $enumDecodeNullable(_$TeamStatusEnumMap, json['status']),
      location: json['location'] == null
          ? null
          : LocationModel.fromJson(json['location'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UpdateTeamRequestToJson(UpdateTeamRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'sportType': _$TeamSportTypeEnumMap[instance.sportType],
      'maxRosterSize': instance.maxRosterSize,
      'maxPendingJoinRequests': instance.maxPendingJoinRequests,
      'logo': instance.logo,
      'coverImages': instance.coverImages,
      'visibility': _$TeamVisibilityEnumMap[instance.visibility],
      'joinMode': _$TeamJoinModeEnumMap[instance.joinMode],
      'status': _$TeamStatusEnumMap[instance.status],
      'location': instance.location?.toJson(),
    };

const _$TeamStatusEnumMap = {
  TeamStatus.active: 'active',
  TeamStatus.inactive: 'inactive',
  TeamStatus.archived: 'archived',
};

TeamModel _$TeamModelFromJson(Map<String, dynamic> json) => TeamModel(
  id: json['_id'] as String?,
  name: json['name'] as String,
  description: json['description'] as String?,
  sportType: $enumDecode(_$TeamSportTypeEnumMap, json['sportType']),
  location: json['location'] == null
      ? null
      : LocationModel.fromJson(json['location'] as Map<String, dynamic>),
  visibility: $enumDecode(_$TeamVisibilityEnumMap, json['visibility']),
  joinMode: $enumDecode(_$TeamJoinModeEnumMap, json['joinMode']),
  createdBy: const UserConverter().fromJson(json['createdBy']),
  ownerIds: json['ownerIds'] == null ? [] : _ownerIdsFromJson(json['ownerIds']),
  logo: json['logo'] as String? ?? '',
  coverImages:
      (json['coverImages'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  maxRosterSize: (json['maxRosterSize'] as num).toInt(),
  maxPendingJoinRequests: (json['maxPendingJoinRequests'] as num).toInt(),
  status: $enumDecode(_$TeamStatusEnumMap, json['status']),
  createdAt: json['createdAt'] as String?,
  updatedAt: json['updatedAt'] as String?,
);

Map<String, dynamic> _$TeamModelToJson(TeamModel instance) => <String, dynamic>{
  '_id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'sportType': _$TeamSportTypeEnumMap[instance.sportType]!,
  'location': instance.location?.toJson(),
  'visibility': _$TeamVisibilityEnumMap[instance.visibility]!,
  'joinMode': _$TeamJoinModeEnumMap[instance.joinMode]!,
  'createdBy': const UserConverter().toJson(instance.createdBy),
  'ownerIds': instance.ownerIds,
  'logo': instance.logo,
  'coverImages': instance.coverImages,
  'maxRosterSize': instance.maxRosterSize,
  'maxPendingJoinRequests': instance.maxPendingJoinRequests,
  'status': _$TeamStatusEnumMap[instance.status]!,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
};
