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

TeamSocialLinks _$TeamSocialLinksFromJson(Map<String, dynamic> json) =>
    TeamSocialLinks(
      instagram: json['instagram'] as String?,
      twitter: json['twitter'] as String?,
      facebook: json['facebook'] as String?,
      youtube: json['youtube'] as String?,
    );

Map<String, dynamic> _$TeamSocialLinksToJson(TeamSocialLinks instance) =>
    <String, dynamic>{
      'instagram': ?instance.instagram,
      'twitter': ?instance.twitter,
      'facebook': ?instance.facebook,
      'youtube': ?instance.youtube,
    };

TeamFootballStats _$TeamFootballStatsFromJson(Map<String, dynamic> json) =>
    TeamFootballStats(
      goalsScored: json['goalsScored'] == null
          ? 0
          : _intFromJson(json['goalsScored']),
      goalsConceded: json['goalsConceded'] == null
          ? 0
          : _intFromJson(json['goalsConceded']),
      penaltyGoalsScored: json['penaltyGoalsScored'] == null
          ? 0
          : _intFromJson(json['penaltyGoalsScored']),
      penaltiesMissed: json['penaltiesMissed'] == null
          ? 0
          : _intFromJson(json['penaltiesMissed']),
      cleanSheets: json['cleanSheets'] == null
          ? 0
          : _intFromJson(json['cleanSheets']),
      yellowCards: json['yellowCards'] == null
          ? 0
          : _intFromJson(json['yellowCards']),
      redCards: json['redCards'] == null ? 0 : _intFromJson(json['redCards']),
    );

Map<String, dynamic> _$TeamFootballStatsToJson(TeamFootballStats instance) =>
    <String, dynamic>{
      'goalsScored': instance.goalsScored,
      'goalsConceded': instance.goalsConceded,
      'penaltyGoalsScored': instance.penaltyGoalsScored,
      'penaltiesMissed': instance.penaltiesMissed,
      'cleanSheets': instance.cleanSheets,
      'yellowCards': instance.yellowCards,
      'redCards': instance.redCards,
    };

TeamCricketStats _$TeamCricketStatsFromJson(Map<String, dynamic> json) =>
    TeamCricketStats(
      totalRunsScored: json['totalRunsScored'] == null
          ? 0
          : _intFromJson(json['totalRunsScored']),
      totalRunsConceded: json['totalRunsConceded'] == null
          ? 0
          : _intFromJson(json['totalRunsConceded']),
      totalWicketsTaken: json['totalWicketsTaken'] == null
          ? 0
          : _intFromJson(json['totalWicketsTaken']),
      highestTeamScore: json['highestTeamScore'] == null
          ? 0
          : _intFromJson(json['highestTeamScore']),
      lowestTeamScore: json['lowestTeamScore'] == null
          ? 0
          : _intFromJson(json['lowestTeamScore']),
      totalExtras: json['totalExtras'] == null
          ? 0
          : _intFromJson(json['totalExtras']),
      timesAllOut: json['timesAllOut'] == null
          ? 0
          : _intFromJson(json['timesAllOut']),
    );

Map<String, dynamic> _$TeamCricketStatsToJson(TeamCricketStats instance) =>
    <String, dynamic>{
      'totalRunsScored': instance.totalRunsScored,
      'totalRunsConceded': instance.totalRunsConceded,
      'totalWicketsTaken': instance.totalWicketsTaken,
      'highestTeamScore': instance.highestTeamScore,
      'lowestTeamScore': instance.lowestTeamScore,
      'totalExtras': instance.totalExtras,
      'timesAllOut': instance.timesAllOut,
    };

TeamEarnedBadge _$TeamEarnedBadgeFromJson(Map<String, dynamic> json) =>
    TeamEarnedBadge(
      badgeId: json['badgeId'] as String,
      earnedAt: DateTime.parse(json['earnedAt'] as String),
    );

Map<String, dynamic> _$TeamEarnedBadgeToJson(TeamEarnedBadge instance) =>
    <String, dynamic>{
      'badgeId': instance.badgeId,
      'earnedAt': instance.earnedAt.toIso8601String(),
    };

CreateTeamRequest _$CreateTeamRequestFromJson(Map<String, dynamic> json) =>
    CreateTeamRequest(
      name: json['name'] as String,
      shortName: json['shortName'] as String?,
      description: json['description'] as String?,
      tagline: json['tagline'] as String?,
      socialLinks: json['socialLinks'] == null
          ? null
          : TeamSocialLinks.fromJson(
              json['socialLinks'] as Map<String, dynamic>,
            ),
      foundedYear: (json['foundedYear'] as num?)?.toInt(),
      genderCategory: $enumDecodeNullable(
        _$TeamGenderCategoryEnumMap,
        json['genderCategory'],
      ),
      maxPendingJoinRequests: (json['maxPendingJoinRequests'] as num).toInt(),
      logo: json['logo'] as String?,
      coverImages: (json['coverImages'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      preferredPlayDays: (json['preferredPlayDays'] as List<dynamic>?)
          ?.map((e) => $enumDecode(_$TeamDayOfWeekEnumMap, e))
          .toList(),
      preferredTimeSlot: $enumDecodeNullable(
        _$TeamPreferredTimeSlotEnumMap,
        json['preferredTimeSlot'],
      ),
      lookingForMembers: json['lookingForMembers'] as bool?,
      pinnedNotices: (json['pinnedNotices'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      sportType: $enumDecode(_$TeamSportTypeEnumMap, json['sportType']),
      visibility: $enumDecode(_$TeamVisibilityEnumMap, json['visibility']),
      joinMode: $enumDecode(_$TeamJoinModeEnumMap, json['joinMode']),
      location: json['location'] == null
          ? null
          : LocationModel.fromJson(json['location'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CreateTeamRequestToJson(CreateTeamRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'shortName': ?instance.shortName,
      'description': ?instance.description,
      'tagline': ?instance.tagline,
      'socialLinks': ?instance.socialLinks?.toJson(),
      'foundedYear': ?instance.foundedYear,
      'genderCategory': ?_$TeamGenderCategoryEnumMap[instance.genderCategory],
      'maxPendingJoinRequests': instance.maxPendingJoinRequests,
      'logo': ?instance.logo,
      'coverImages': ?instance.coverImages,
      'tags': ?instance.tags,
      'preferredPlayDays': ?instance.preferredPlayDays
          ?.map((e) => _$TeamDayOfWeekEnumMap[e]!)
          .toList(),
      'preferredTimeSlot':
          ?_$TeamPreferredTimeSlotEnumMap[instance.preferredTimeSlot],
      'lookingForMembers': ?instance.lookingForMembers,
      'pinnedNotices': ?instance.pinnedNotices,
      'sportType': _$TeamSportTypeEnumMap[instance.sportType]!,
      'visibility': _$TeamVisibilityEnumMap[instance.visibility]!,
      'joinMode': _$TeamJoinModeEnumMap[instance.joinMode]!,
      'location': ?instance.location?.toJson(),
    };

const _$TeamGenderCategoryEnumMap = {
  TeamGenderCategory.male: 'male',
  TeamGenderCategory.female: 'female',
  TeamGenderCategory.mixed: 'mixed',
};

const _$TeamDayOfWeekEnumMap = {
  TeamDayOfWeek.monday: 'monday',
  TeamDayOfWeek.tuesday: 'tuesday',
  TeamDayOfWeek.wednesday: 'wednesday',
  TeamDayOfWeek.thursday: 'thursday',
  TeamDayOfWeek.friday: 'friday',
  TeamDayOfWeek.saturday: 'saturday',
  TeamDayOfWeek.sunday: 'sunday',
};

const _$TeamPreferredTimeSlotEnumMap = {
  TeamPreferredTimeSlot.morning: 'morning',
  TeamPreferredTimeSlot.afternoon: 'afternoon',
  TeamPreferredTimeSlot.evening: 'evening',
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

UpdateTeamRequest _$UpdateTeamRequestFromJson(
  Map<String, dynamic> json,
) => UpdateTeamRequest(
  name: json['name'] as String?,
  shortName: json['shortName'] as String?,
  description: json['description'] as String?,
  tagline: json['tagline'] as String?,
  socialLinks: json['socialLinks'] == null
      ? null
      : TeamSocialLinks.fromJson(json['socialLinks'] as Map<String, dynamic>),
  foundedYear: (json['foundedYear'] as num?)?.toInt(),
  genderCategory: $enumDecodeNullable(
    _$TeamGenderCategoryEnumMap,
    json['genderCategory'],
  ),
  maxPendingJoinRequests: (json['maxPendingJoinRequests'] as num?)?.toInt(),
  logo: json['logo'] as String?,
  coverImages: (json['coverImages'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
  preferredPlayDays: (json['preferredPlayDays'] as List<dynamic>?)
      ?.map((e) => $enumDecode(_$TeamDayOfWeekEnumMap, e))
      .toList(),
  preferredTimeSlot: $enumDecodeNullable(
    _$TeamPreferredTimeSlotEnumMap,
    json['preferredTimeSlot'],
  ),
  lookingForMembers: json['lookingForMembers'] as bool?,
  teamOpenForMatch: json['teamOpenForMatch'] as bool?,
  pinnedNotices: (json['pinnedNotices'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  visibility: $enumDecodeNullable(_$TeamVisibilityEnumMap, json['visibility']),
  joinMode: $enumDecodeNullable(_$TeamJoinModeEnumMap, json['joinMode']),
  status: $enumDecodeNullable(_$TeamStatusEnumMap, json['status']),
  location: json['location'] == null
      ? null
      : LocationModel.fromJson(json['location'] as Map<String, dynamic>),
);

Map<String, dynamic> _$UpdateTeamRequestToJson(UpdateTeamRequest instance) =>
    <String, dynamic>{
      'name': ?instance.name,
      'shortName': ?instance.shortName,
      'description': ?instance.description,
      'tagline': ?instance.tagline,
      'socialLinks': ?instance.socialLinks?.toJson(),
      'foundedYear': ?instance.foundedYear,
      'genderCategory': ?_$TeamGenderCategoryEnumMap[instance.genderCategory],
      'maxPendingJoinRequests': ?instance.maxPendingJoinRequests,
      'logo': ?instance.logo,
      'coverImages': ?instance.coverImages,
      'tags': ?instance.tags,
      'preferredPlayDays': ?instance.preferredPlayDays
          ?.map((e) => _$TeamDayOfWeekEnumMap[e]!)
          .toList(),
      'preferredTimeSlot':
          ?_$TeamPreferredTimeSlotEnumMap[instance.preferredTimeSlot],
      'lookingForMembers': ?instance.lookingForMembers,
      'teamOpenForMatch': ?instance.teamOpenForMatch,
      'pinnedNotices': ?instance.pinnedNotices,
      'visibility': ?_$TeamVisibilityEnumMap[instance.visibility],
      'joinMode': ?_$TeamJoinModeEnumMap[instance.joinMode],
      'status': ?_$TeamStatusEnumMap[instance.status],
      'location': ?instance.location?.toJson(),
    };

const _$TeamStatusEnumMap = {
  TeamStatus.active: 'active',
  TeamStatus.inactive: 'inactive',
  TeamStatus.archived: 'archived',
};

TeamModel _$TeamModelFromJson(Map<String, dynamic> json) => TeamModel(
  id: json['_id'] as String?,
  name: json['name'] as String,
  shortName: json['shortName'] as String?,
  description: json['description'] as String?,
  tagline: json['tagline'] as String?,
  socialLinks: _socialLinksFromJson(json['socialLinks']),
  foundedYear: (json['foundedYear'] as num?)?.toInt(),
  sportType: $enumDecode(_$TeamSportTypeEnumMap, json['sportType']),
  genderCategory: $enumDecodeNullable(
    _$TeamGenderCategoryEnumMap,
    json['genderCategory'],
  ),
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
  maxPendingJoinRequests: _intFromJson(json['maxPendingJoinRequests']),
  status: $enumDecode(_$TeamStatusEnumMap, json['status']),
  disabledAt: json['disabledAt'] as String?,
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
  preferredPlayDays:
      (json['preferredPlayDays'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  preferredTimeSlot: $enumDecodeNullable(
    _$TeamPreferredTimeSlotEnumMap,
    json['preferredTimeSlot'],
  ),
  lookingForMembers: json['lookingForMembers'] as bool? ?? false,
  teamOpenForMatch: json['teamOpenForMatch'] as bool? ?? false,
  pinnedNotices:
      (json['pinnedNotices'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  matchesPlayed: json['matchesPlayed'] == null
      ? 0
      : _intFromJson(json['matchesPlayed']),
  wins: json['wins'] == null ? 0 : _intFromJson(json['wins']),
  losses: json['losses'] == null ? 0 : _intFromJson(json['losses']),
  draws: json['draws'] == null ? 0 : _intFromJson(json['draws']),
  winRate: json['winRate'] == null ? 0.0 : _doubleFromJson(json['winRate']),
  sportStats: _sportStatsMapFromJson(json['sportStats']),
  badges:
      (json['badges'] as List<dynamic>?)
          ?.map((e) => TeamEarnedBadge.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  createdAt: json['createdAt'] as String?,
  updatedAt: json['updatedAt'] as String?,
);

Map<String, dynamic> _$TeamModelToJson(TeamModel instance) => <String, dynamic>{
  '_id': instance.id,
  'name': instance.name,
  'shortName': instance.shortName,
  'description': instance.description,
  'tagline': instance.tagline,
  'socialLinks': instance.socialLinks.toJson(),
  'foundedYear': instance.foundedYear,
  'sportType': _$TeamSportTypeEnumMap[instance.sportType]!,
  'genderCategory': _$TeamGenderCategoryEnumMap[instance.genderCategory],
  'location': instance.location?.toJson(),
  'visibility': _$TeamVisibilityEnumMap[instance.visibility]!,
  'joinMode': _$TeamJoinModeEnumMap[instance.joinMode]!,
  'createdBy': const UserConverter().toJson(instance.createdBy),
  'ownerIds': instance.ownerIds,
  'logo': instance.logo,
  'coverImages': instance.coverImages,
  'maxPendingJoinRequests': instance.maxPendingJoinRequests,
  'status': _$TeamStatusEnumMap[instance.status]!,
  'disabledAt': instance.disabledAt,
  'tags': instance.tags,
  'preferredPlayDays': instance.preferredPlayDays,
  'preferredTimeSlot':
      _$TeamPreferredTimeSlotEnumMap[instance.preferredTimeSlot],
  'lookingForMembers': instance.lookingForMembers,
  'teamOpenForMatch': instance.teamOpenForMatch,
  'pinnedNotices': instance.pinnedNotices,
  'matchesPlayed': instance.matchesPlayed,
  'wins': instance.wins,
  'losses': instance.losses,
  'draws': instance.draws,
  'winRate': instance.winRate,
  'sportStats': _sportStatsMapToJson(instance.sportStats),
  'badges': instance.badges.map((e) => e.toJson()).toList(),
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
};
