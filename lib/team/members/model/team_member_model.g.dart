// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_member_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateTeamMemberRequest _$UpdateTeamMemberRequestFromJson(
  Map<String, dynamic> json,
) => UpdateTeamMemberRequest(
  leadershipRole: $enumDecodeNullable(
    _$LeadershipRoleEnumMap,
    json['leadershipRole'],
  ),
  playingPosition: json['playingPosition'] as String?,
  lineupCategory: $enumDecodeNullable(
    _$LineupCategoryEnumMap,
    json['lineupCategory'],
  ),
  jerseyNumber: (json['jerseyNumber'] as num?)?.toInt(),
  nickname: json['nickname'] as String?,
  isVerified: json['isVerified'] as bool?,
);

Map<String, dynamic> _$UpdateTeamMemberRequestToJson(
  UpdateTeamMemberRequest instance,
) => <String, dynamic>{
  'leadershipRole': _$LeadershipRoleEnumMap[instance.leadershipRole],
  'playingPosition': instance.playingPosition,
  'lineupCategory': _$LineupCategoryEnumMap[instance.lineupCategory],
  'jerseyNumber': instance.jerseyNumber,
  'nickname': instance.nickname,
  'isVerified': instance.isVerified,
};

const _$LeadershipRoleEnumMap = {
  LeadershipRole.captain: 'captain',
  LeadershipRole.viceCaptain: 'vice_captain',
};

const _$LineupCategoryEnumMap = {
  LineupCategory.starter: 'starter',
  LineupCategory.substitute: 'substitute',
};

SuspendTeamMemberRequest _$SuspendTeamMemberRequestFromJson(
  Map<String, dynamic> json,
) => SuspendTeamMemberRequest(
  suspendedUntil: json['suspendedUntil'] == null
      ? null
      : DateTime.parse(json['suspendedUntil'] as String),
);

Map<String, dynamic> _$SuspendTeamMemberRequestToJson(
  SuspendTeamMemberRequest instance,
) => <String, dynamic>{
  'suspendedUntil': ?instance.suspendedUntil?.toIso8601String(),
};

TeamMemberModel _$TeamMemberModelFromJson(Map<String, dynamic> json) =>
    TeamMemberModel(
      id: json['_id'] as String?,
      team: const TeamRefConverter().fromJson(json['team']),
      user: const UserConverter().fromJson(json['user']),
      status: $enumDecode(_$TeamMemberStatusEnumMap, json['status']),
      leadershipRole: $enumDecodeNullable(
        _$LeadershipRoleEnumMap,
        json['leadershipRole'],
      ),
      playingPosition: json['playingPosition'] as String?,
      lineupCategory:
          $enumDecodeNullable(
            _$LineupCategoryEnumMap,
            json['lineupCategory'],
          ) ??
          LineupCategory.starter,
      jerseyNumber: (json['jerseyNumber'] as num?)?.toInt(),
      nickname: json['nickname'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      suspendedUntil: json['suspendedUntil'] as String?,
      joinedAt: json['joinedAt'] as String?,
      leftAt: json['leftAt'] as String?,
      reviewedBy: const UserConverter().fromJson(json['reviewedBy']),
      reviewedAt: json['reviewedAt'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );

Map<String, dynamic> _$TeamMemberModelToJson(TeamMemberModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'team': const TeamRefConverter().toJson(instance.team),
      'user': const UserConverter().toJson(instance.user),
      'status': _$TeamMemberStatusEnumMap[instance.status]!,
      'leadershipRole': _$LeadershipRoleEnumMap[instance.leadershipRole],
      'playingPosition': instance.playingPosition,
      'lineupCategory': _$LineupCategoryEnumMap[instance.lineupCategory]!,
      'jerseyNumber': instance.jerseyNumber,
      'nickname': instance.nickname,
      'isVerified': instance.isVerified,
      'suspendedUntil': instance.suspendedUntil,
      'joinedAt': instance.joinedAt,
      'leftAt': instance.leftAt,
      'reviewedBy': const UserConverter().toJson(instance.reviewedBy),
      'reviewedAt': instance.reviewedAt,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };

const _$TeamMemberStatusEnumMap = {
  TeamMemberStatus.pending: 'pending',
  TeamMemberStatus.active: 'active',
  TeamMemberStatus.resigned: 'resigned',
  TeamMemberStatus.removed: 'removed',
  TeamMemberStatus.rejected: 'rejected',
  TeamMemberStatus.suspended: 'suspended',
};
