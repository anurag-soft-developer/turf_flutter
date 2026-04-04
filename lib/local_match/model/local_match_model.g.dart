// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_match_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocalMatchMemberModel _$LocalMatchMemberModelFromJson(
  Map<String, dynamic> json,
) => LocalMatchMemberModel(
  user: const UserConverter().fromJson(json['user']),
  joinedAt: json['joinedAt'] as String,
);

Map<String, dynamic> _$LocalMatchMemberModelToJson(
  LocalMatchMemberModel instance,
) => <String, dynamic>{
  'user': const UserConverter().toJson(instance.user),
  'joinedAt': instance.joinedAt,
};

JoinRequestEntryModel _$JoinRequestEntryModelFromJson(
  Map<String, dynamic> json,
) => JoinRequestEntryModel(
  id: json['_id'] as String?,
  user: const UserConverter().fromJson(json['user']),
  status: $enumDecode(_$JoinRequestStatusEnumMap, json['status']),
  createdAt: json['createdAt'] as String,
  reviewedBy: const UserConverter().fromJson(json['reviewedBy']),
  reviewedAt: json['reviewedAt'] as String?,
);

Map<String, dynamic> _$JoinRequestEntryModelToJson(
  JoinRequestEntryModel instance,
) => <String, dynamic>{
  '_id': instance.id,
  'user': const UserConverter().toJson(instance.user),
  'status': _$JoinRequestStatusEnumMap[instance.status]!,
  'createdAt': instance.createdAt,
  'reviewedBy': const UserConverter().toJson(instance.reviewedBy),
  'reviewedAt': instance.reviewedAt,
};

const _$JoinRequestStatusEnumMap = {
  JoinRequestStatus.pending: 'pending',
  JoinRequestStatus.accepted: 'accepted',
  JoinRequestStatus.rejected: 'rejected',
};

LocalMatchModel _$LocalMatchModelFromJson(
  Map<String, dynamic> json,
) => LocalMatchModel(
  id: json['_id'] as String?,
  title: json['title'] as String,
  description: json['description'] as String?,
  sportTypes:
      (json['sportTypes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  visibility: $enumDecode(_$LocalMatchVisibilityEnumMap, json['visibility']),
  joinMode: $enumDecode(_$LocalMatchJoinModeEnumMap, json['joinMode']),
  location: LocationModel.fromJson(json['location'] as Map<String, dynamic>),
  turf: const TurfConverter().fromJson(json['turf']),
  createdBy: const UserConverter().fromJson(json['createdBy']),
  hostIds:
      (json['hostIds'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      [],
  members:
      (json['members'] as List<dynamic>?)
          ?.map(
            (e) => LocalMatchMemberModel.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      [],
  joinRequests:
      (json['joinRequests'] as List<dynamic>?)
          ?.map(
            (e) => JoinRequestEntryModel.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      [],
  maxMembers: (json['maxMembers'] as num).toInt(),
  maxPendingJoinRequests: (json['maxPendingJoinRequests'] as num).toInt(),
  closingTime: json['closingTime'] as String,
  eventStartsAt: json['eventStartsAt'] as String?,
  eventEndsAt: json['eventEndsAt'] as String?,
  status: $enumDecode(_$LocalMatchStatusEnumMap, json['status']),
  createdAt: json['createdAt'] as String?,
  updatedAt: json['updatedAt'] as String?,
);

Map<String, dynamic> _$LocalMatchModelToJson(LocalMatchModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'sportTypes': instance.sportTypes,
      'visibility': _$LocalMatchVisibilityEnumMap[instance.visibility]!,
      'joinMode': _$LocalMatchJoinModeEnumMap[instance.joinMode]!,
      'location': instance.location.toJson(),
      'turf': const TurfConverter().toJson(instance.turf),
      'createdBy': const UserConverter().toJson(instance.createdBy),
      'hostIds': instance.hostIds,
      'members': instance.members.map((e) => e.toJson()).toList(),
      'joinRequests': instance.joinRequests.map((e) => e.toJson()).toList(),
      'maxMembers': instance.maxMembers,
      'maxPendingJoinRequests': instance.maxPendingJoinRequests,
      'closingTime': instance.closingTime,
      'eventStartsAt': instance.eventStartsAt,
      'eventEndsAt': instance.eventEndsAt,
      'status': _$LocalMatchStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };

const _$LocalMatchVisibilityEnumMap = {
  LocalMatchVisibility.public: 'public',
  LocalMatchVisibility.private: 'private',
};

const _$LocalMatchJoinModeEnumMap = {
  LocalMatchJoinMode.open: 'open',
  LocalMatchJoinMode.approval: 'approval',
};

const _$LocalMatchStatusEnumMap = {
  LocalMatchStatus.open: 'open',
  LocalMatchStatus.full: 'full',
  LocalMatchStatus.cancelled: 'cancelled',
  LocalMatchStatus.completed: 'completed',
};

CreateLocalMatchRequest _$CreateLocalMatchRequestFromJson(
  Map<String, dynamic> json,
) => CreateLocalMatchRequest(
  title: json['title'] as String,
  description: json['description'] as String?,
  sportTypes: (json['sportTypes'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  visibility: $enumDecode(_$LocalMatchVisibilityEnumMap, json['visibility']),
  joinMode: $enumDecode(_$LocalMatchJoinModeEnumMap, json['joinMode']),
  location: json['location'] == null
      ? null
      : LocationModel.fromJson(json['location'] as Map<String, dynamic>),
  turf: json['turf'] as String?,
  maxMembers: (json['maxMembers'] as num).toInt(),
  maxPendingJoinRequests: (json['maxPendingJoinRequests'] as num).toInt(),
  closingTime: json['closingTime'] as String,
  eventStartsAt: json['eventStartsAt'] as String?,
  eventEndsAt: json['eventEndsAt'] as String?,
);

Map<String, dynamic> _$CreateLocalMatchRequestToJson(
  CreateLocalMatchRequest instance,
) => <String, dynamic>{
  'title': instance.title,
  'description': instance.description,
  'sportTypes': instance.sportTypes,
  'visibility': _$LocalMatchVisibilityEnumMap[instance.visibility]!,
  'joinMode': _$LocalMatchJoinModeEnumMap[instance.joinMode]!,
  'location': instance.location?.toJson(),
  'turf': instance.turf,
  'maxMembers': instance.maxMembers,
  'maxPendingJoinRequests': instance.maxPendingJoinRequests,
  'closingTime': instance.closingTime,
  'eventStartsAt': instance.eventStartsAt,
  'eventEndsAt': instance.eventEndsAt,
};

UpdateLocalMatchLocationRequest _$UpdateLocalMatchLocationRequestFromJson(
  Map<String, dynamic> json,
) => UpdateLocalMatchLocationRequest(
  address: json['address'] as String?,
  coordinates: json['coordinates'] == null
      ? null
      : GeoPointModel.fromJson(json['coordinates'] as Map<String, dynamic>),
);

Map<String, dynamic> _$UpdateLocalMatchLocationRequestToJson(
  UpdateLocalMatchLocationRequest instance,
) => <String, dynamic>{
  'address': instance.address,
  'coordinates': instance.coordinates?.toJson(),
};

UpdateLocalMatchRequest _$UpdateLocalMatchRequestFromJson(
  Map<String, dynamic> json,
) => UpdateLocalMatchRequest(
  title: json['title'] as String?,
  description: json['description'] as String?,
  sportTypes: (json['sportTypes'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  maxMembers: (json['maxMembers'] as num?)?.toInt(),
  maxPendingJoinRequests: (json['maxPendingJoinRequests'] as num?)?.toInt(),
  closingTime: json['closingTime'] as String?,
  eventStartsAt: json['eventStartsAt'] as String?,
  eventEndsAt: json['eventEndsAt'] as String?,
  visibility: $enumDecodeNullable(
    _$LocalMatchVisibilityEnumMap,
    json['visibility'],
  ),
  joinMode: $enumDecodeNullable(_$LocalMatchJoinModeEnumMap, json['joinMode']),
  location: json['location'] == null
      ? null
      : UpdateLocalMatchLocationRequest.fromJson(
          json['location'] as Map<String, dynamic>,
        ),
  turf: json['turf'] as String?,
  status: $enumDecodeNullable(_$LocalMatchStatusEnumMap, json['status']),
);

Map<String, dynamic> _$UpdateLocalMatchRequestToJson(
  UpdateLocalMatchRequest instance,
) => <String, dynamic>{
  'title': ?instance.title,
  'description': ?instance.description,
  'sportTypes': ?instance.sportTypes,
  'maxMembers': ?instance.maxMembers,
  'maxPendingJoinRequests': ?instance.maxPendingJoinRequests,
  'closingTime': ?instance.closingTime,
  'eventStartsAt': ?instance.eventStartsAt,
  'eventEndsAt': ?instance.eventEndsAt,
  'visibility': ?_$LocalMatchVisibilityEnumMap[instance.visibility],
  'joinMode': ?_$LocalMatchJoinModeEnumMap[instance.joinMode],
  'location': ?instance.location?.toJson(),
  'turf': ?instance.turf,
  'status': ?_$LocalMatchStatusEnumMap[instance.status],
};

PromoteHostRequest _$PromoteHostRequestFromJson(Map<String, dynamic> json) =>
    PromoteHostRequest(userId: json['userId'] as String);

Map<String, dynamic> _$PromoteHostRequestToJson(PromoteHostRequest instance) =>
    <String, dynamic>{'userId': instance.userId};
