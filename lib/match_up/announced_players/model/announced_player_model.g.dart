// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'announced_player_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AnnouncedPlayerModel _$AnnouncedPlayerModelFromJson(
  Map<String, dynamic> json,
) => AnnouncedPlayerModel(
  teamId: const TeamRefConverter().fromJson(json['teamId']),
  name: json['name'] as String,
  avatar: json['avatar'] as String?,
  email: json['email'] as String?,
  userId: const UserConverter().fromJson(json['userId']),
  isGuest: json['isGuest'] as bool? ?? false,
  guestId: mongoIdFromJsonNullable(json['guestId']),
  isSubstitute: json['is_substitute'] as bool? ?? false,
  isSubstituted: json['is_substituted'] as bool? ?? false,
  substituteCount: (json['substitute_count'] as num?)?.toInt() ?? 0,
  role: $enumDecode(_$AnnouncedPlayerRoleEnumMap, json['role']),
  isCaption: json['isCaption'] as bool? ?? false,
  isWiseCaption: json['isWiseCaption'] as bool? ?? false,
);

Map<String, dynamic> _$AnnouncedPlayerModelToJson(
  AnnouncedPlayerModel instance,
) => <String, dynamic>{
  'teamId': const TeamRefConverter().toJson(instance.teamId),
  'name': instance.name,
  'avatar': instance.avatar,
  'email': instance.email,
  'userId': const UserConverter().toJson(instance.userId),
  'isGuest': instance.isGuest,
  'guestId': instance.guestId,
  'is_substitute': instance.isSubstitute,
  'is_substituted': instance.isSubstituted,
  'substitute_count': instance.substituteCount,
  'role': _$AnnouncedPlayerRoleEnumMap[instance.role]!,
  'isCaption': instance.isCaption,
  'isWiseCaption': instance.isWiseCaption,
};

const _$AnnouncedPlayerRoleEnumMap = {
  AnnouncedPlayerRole.batsman: 'batsman',
  AnnouncedPlayerRole.bowler: 'bowler',
  AnnouncedPlayerRole.allrounder: 'allrounder',
  AnnouncedPlayerRole.wicketKeeper: 'wicket_keeper',
};
