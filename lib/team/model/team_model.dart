import 'package:json_annotation/json_annotation.dart';

import '../../core/models/location_model.dart';
import '../../core/models/user_field_converters.dart';
import '../../core/models/user_field_instance.dart';

export '../../core/models/location_model.dart';

part 'team_model.g.dart';

/// Backend [SportType].
enum TeamSportType { cricket, football }

/// Backend [TeamVisibility].
enum TeamVisibility { public, private }

/// Backend [TeamJoinMode]. Private teams cannot use [open] (server validates).
enum TeamJoinMode { open, approval }

/// Backend [TeamStatus].
enum TeamStatus { active, inactive, archived }

/// Backend [TeamGenderCategory].
enum TeamGenderCategory { male, female, mixed }

/// Backend [TeamPreferredTimeSlot].
enum TeamPreferredTimeSlot { morning, afternoon, evening }

/// Backend `dayOfWeekSchema` on team DTOs (`preferredPlayDays`).
enum TeamDayOfWeek {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday,
}

/// Backend [TeamFilterDto] — `limit` max is 50.
const int kTeamFilterMaxLimit = 50;

/// Backend [SPORT_ROSTER_CONFIG] — roster bounds per sport (DTO validation).
({int min, int max}) teamSportRosterBounds(TeamSportType sport) {
  return switch (sport) {
    TeamSportType.cricket => (min: 11, max: 15),
    TeamSportType.football => (min: 5, max: 18),
  };
}

List<String> _ownerIdsFromJson(dynamic json) {
  if (json == null) return const [];
  return (json as List<dynamic>).map((e) => e.toString()).toList();
}

TeamSportStatsMap _sportStatsMapFromJson(dynamic json) {
  if (json is! Map<String, dynamic>) return const TeamSportStatsMap();
  return TeamSportStatsMap.fromJson(json);
}

Map<String, dynamic> _sportStatsMapToJson(TeamSportStatsMap v) => v.toJson();

TeamSocialLinks _socialLinksFromJson(dynamic json) {
  if (json is! Map<String, dynamic>) return const TeamSocialLinks();
  return TeamSocialLinks.fromJson(json);
}

int _intFromJson(dynamic json) {
  if (json is int) return json;
  if (json is String) return int.tryParse(json) ?? 0;
  return 0;
}

double _doubleFromJson(dynamic json) {
  if (json is double) return json;
  if (json is int) return json.toDouble();
  if (json is String) return double.tryParse(json) ?? 0.0;
  return 0.0;
}

@JsonSerializable()
class PromoteOwnerRequest {
  @JsonKey(name: 'userId')
  final String userId;

  PromoteOwnerRequest({required this.userId});

  factory PromoteOwnerRequest.fromJson(Map<String, dynamic> json) =>
      _$PromoteOwnerRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PromoteOwnerRequestToJson(this);
}

/// Backend [TeamSocialLinks].
@JsonSerializable(includeIfNull: false)
class TeamSocialLinks {
  final String? instagram;
  final String? twitter;
  final String? facebook;
  final String? youtube;

  const TeamSocialLinks({
    this.instagram,
    this.twitter,
    this.facebook,
    this.youtube,
  });

  factory TeamSocialLinks.fromJson(Map<String, dynamic> json) =>
      _$TeamSocialLinksFromJson(json);

  Map<String, dynamic> toJson() => _$TeamSocialLinksToJson(this);
}

/// Backend team [FootballStats].
@JsonSerializable()
class TeamFootballStats {
  @JsonKey(fromJson: _intFromJson, defaultValue: 0)
  final int goalsScored;
  @JsonKey(fromJson: _intFromJson, defaultValue: 0)
  final int goalsConceded;
  @JsonKey(fromJson: _intFromJson, defaultValue: 0)
  final int penaltyGoalsScored;
  @JsonKey(fromJson: _intFromJson, defaultValue: 0)
  final int penaltiesMissed;
  @JsonKey(fromJson: _intFromJson, defaultValue: 0)
  final int cleanSheets;
  @JsonKey(fromJson: _intFromJson, defaultValue: 0)
  final int yellowCards;
  @JsonKey(fromJson: _intFromJson, defaultValue: 0)
  final int redCards;

  const TeamFootballStats({
    this.goalsScored = 0,
    this.goalsConceded = 0,
    this.penaltyGoalsScored = 0,
    this.penaltiesMissed = 0,
    this.cleanSheets = 0,
    this.yellowCards = 0,
    this.redCards = 0,
  });

  factory TeamFootballStats.fromJson(Map<String, dynamic> json) =>
      _$TeamFootballStatsFromJson(json);

  Map<String, dynamic> toJson() => _$TeamFootballStatsToJson(this);
}

/// Backend team [CricketStats].
@JsonSerializable()
class TeamCricketStats {
  @JsonKey(fromJson: _intFromJson, defaultValue: 0)
  final int totalRunsScored;
  @JsonKey(fromJson: _intFromJson, defaultValue: 0)
  final int totalRunsConceded;
  @JsonKey(fromJson: _intFromJson, defaultValue: 0)
  final int totalWicketsTaken;
  @JsonKey(fromJson: _intFromJson, defaultValue: 0)
  final int highestTeamScore;
  @JsonKey(fromJson: _intFromJson, defaultValue: 0)
  final int lowestTeamScore;
  @JsonKey(fromJson: _intFromJson, defaultValue: 0)
  final int totalExtras;
  @JsonKey(fromJson: _intFromJson, defaultValue: 0)
  final int timesAllOut;

  const TeamCricketStats({
    this.totalRunsScored = 0,
    this.totalRunsConceded = 0,
    this.totalWicketsTaken = 0,
    this.highestTeamScore = 0,
    this.lowestTeamScore = 0,
    this.totalExtras = 0,
    this.timesAllOut = 0,
  });

  factory TeamCricketStats.fromJson(Map<String, dynamic> json) =>
      _$TeamCricketStatsFromJson(json);

  Map<String, dynamic> toJson() => _$TeamCricketStatsToJson(this);
}

/// Backend [SportStatsMap] — only the team's [TeamSportType] key is populated.
class TeamSportStatsMap {
  final TeamFootballStats? football;
  final TeamCricketStats? cricket;

  const TeamSportStatsMap({this.football, this.cricket});

  factory TeamSportStatsMap.fromJson(Map<String, dynamic> json) {
    TeamFootballStats? f;
    final rawF = json['football'];
    if (rawF is Map<String, dynamic>) {
      f = TeamFootballStats.fromJson(rawF);
    }
    TeamCricketStats? c;
    final rawC = json['cricket'];
    if (rawC is Map<String, dynamic>) {
      c = TeamCricketStats.fromJson(rawC);
    }
    return TeamSportStatsMap(football: f, cricket: c);
  }

  Map<String, dynamic> toJson() => {
    if (football != null) 'football': football!.toJson(),
    if (cricket != null) 'cricket': cricket!.toJson(),
  };
}

/// Team document badge (`badgeId` + `earnedAt` only).
@JsonSerializable()
class TeamEarnedBadge {
  @JsonKey(name: 'badgeId')
  final String badgeId;
  final DateTime earnedAt;

  const TeamEarnedBadge({required this.badgeId, required this.earnedAt});

  factory TeamEarnedBadge.fromJson(Map<String, dynamic> json) =>
      _$TeamEarnedBadgeFromJson(json);

  Map<String, dynamic> toJson() => _$TeamEarnedBadgeToJson(this);
}

/// Matches backend [TeamFilterDto] / `TeamFilterSchema` query params.
class TeamFilterQuery {
  final TeamVisibility? visibility;
  final TeamStatus? status;
  final TeamSportType? sportType;
  final TeamGenderCategory? genderCategory;

  /// Serialized as `'true'` / `'false'` (Zod enum).
  final bool? lookingForMembers;

  /// Serialized as `'true'` / `'false'` (Zod enum).
  final bool? teamOpenForMatch;
  final int page;
  final int limit;
  final double? nearbyLat;
  final double? nearbyLng;
  final double? nearbyRadiusKm;

  const TeamFilterQuery({
    this.visibility,
    this.status,
    this.sportType,
    this.genderCategory,
    this.lookingForMembers,
    this.teamOpenForMatch,
    this.page = 1,
    this.limit = 10,
    this.nearbyLat,
    this.nearbyLng,
    this.nearbyRadiusKm,
  });

  Map<String, dynamic> toQueryParameters() {
    final clampedLimit = limit.clamp(1, kTeamFilterMaxLimit);
    final params = <String, dynamic>{
      'page': page.toString(),
      'limit': clampedLimit.toString(),
    };
    if (visibility != null) params['visibility'] = visibility!.name;
    if (status != null) params['status'] = status!.name;
    if (sportType != null) params['sportType'] = sportType!.name;
    if (genderCategory != null) {
      params['genderCategory'] = genderCategory!.name;
    }
    if (lookingForMembers != null) {
      params['lookingForMembers'] = lookingForMembers! ? 'true' : 'false';
    }
    if (teamOpenForMatch != null) {
      params['teamOpenForMatch'] = teamOpenForMatch! ? 'true' : 'false';
    }
    if (nearbyLat != null && nearbyLng != null) {
      params.addAll(
        nearbyLocationQueryParameters(
          nearbyLat: nearbyLat!,
          nearbyLng: nearbyLng!,
          nearbyRadiusKm: nearbyRadiusKm,
        ),
      );
    }
    return params;
  }
}

/// Body for `POST /teams` ([CreateTeamDto] / [CreateTeamSchema]).
@JsonSerializable(explicitToJson: true, includeIfNull: false)
class CreateTeamRequest {
  final String name;
  @JsonKey(name: 'shortName')
  final String? shortName;
  final String? description;
  final String? tagline;
  @JsonKey(name: 'socialLinks')
  final TeamSocialLinks? socialLinks;
  @JsonKey(name: 'foundedYear')
  final int? foundedYear;
  @JsonKey(name: 'genderCategory')
  final TeamGenderCategory? genderCategory;
  @JsonKey(name: 'maxPendingJoinRequests')
  final int maxPendingJoinRequests;
  final String? logo;
  final List<String>? coverImages;
  final List<String>? tags;
  @JsonKey(name: 'preferredPlayDays')
  final List<TeamDayOfWeek>? preferredPlayDays;
  @JsonKey(name: 'preferredTimeSlot')
  final TeamPreferredTimeSlot? preferredTimeSlot;
  @JsonKey(name: 'lookingForMembers')
  final bool? lookingForMembers;
  @JsonKey(name: 'pinnedNotices')
  final List<String>? pinnedNotices;
  final TeamSportType sportType;
  final TeamVisibility visibility;
  final TeamJoinMode joinMode;
  final LocationModel? location;

  CreateTeamRequest({
    required this.name,
    this.shortName,
    this.description,
    this.tagline,
    this.socialLinks,
    this.foundedYear,
    this.genderCategory,
    required this.maxPendingJoinRequests,
    this.logo,
    this.coverImages,
    this.tags,
    this.preferredPlayDays,
    this.preferredTimeSlot,
    this.lookingForMembers,
    this.pinnedNotices,
    required this.sportType,
    required this.visibility,
    required this.joinMode,
    this.location,
  });

  factory CreateTeamRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateTeamRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateTeamRequestToJson(this);
}

/// Body for `PATCH /teams/:id` ([UpdateTeamDto] / [UpdateTeamSchema]).
/// All fields optional; [sportType] is not in the backend update schema.
@JsonSerializable(explicitToJson: true, includeIfNull: false)
class UpdateTeamRequest {
  final String? name;
  @JsonKey(name: 'shortName')
  final String? shortName;
  final String? description;
  final String? tagline;
  @JsonKey(name: 'socialLinks')
  final TeamSocialLinks? socialLinks;
  @JsonKey(name: 'foundedYear')
  final int? foundedYear;
  @JsonKey(name: 'genderCategory')
  final TeamGenderCategory? genderCategory;
  @JsonKey(name: 'maxPendingJoinRequests')
  final int? maxPendingJoinRequests;
  final String? logo;
  final List<String>? coverImages;
  final List<String>? tags;
  @JsonKey(name: 'preferredPlayDays')
  final List<TeamDayOfWeek>? preferredPlayDays;
  @JsonKey(name: 'preferredTimeSlot')
  final TeamPreferredTimeSlot? preferredTimeSlot;
  @JsonKey(name: 'lookingForMembers')
  final bool? lookingForMembers;
  @JsonKey(name: 'pinnedNotices')
  final List<String>? pinnedNotices;
  final TeamVisibility? visibility;
  final TeamJoinMode? joinMode;
  final TeamStatus? status;
  final LocationModel? location;

  UpdateTeamRequest({
    this.name,
    this.shortName,
    this.description,
    this.tagline,
    this.socialLinks,
    this.foundedYear,
    this.genderCategory,
    this.maxPendingJoinRequests,
    this.logo,
    this.coverImages,
    this.tags,
    this.preferredPlayDays,
    this.preferredTimeSlot,
    this.lookingForMembers,
    this.pinnedNotices,
    this.visibility,
    this.joinMode,
    this.status,
    this.location,
  });

  factory UpdateTeamRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateTeamRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateTeamRequestToJson(this);
}

@JsonSerializable(explicitToJson: true)
class TeamModel {
  @JsonKey(name: '_id')
  final String? id;
  final String name;
  @JsonKey(name: 'shortName')
  final String? shortName;
  final String? description;
  final String? tagline;
  @JsonKey(name: 'socialLinks', fromJson: _socialLinksFromJson)
  final TeamSocialLinks socialLinks;
  @JsonKey(name: 'foundedYear')
  final int? foundedYear;
  final TeamSportType sportType;
  @JsonKey(name: 'genderCategory')
  final TeamGenderCategory? genderCategory;
  final LocationModel? location;
  final TeamVisibility visibility;
  final TeamJoinMode joinMode;
  @JsonKey(name: 'createdBy')
  @UserConverter()
  final dynamic createdBy;
  @JsonKey(
    name: 'ownerIds',
    fromJson: _ownerIdsFromJson,
    defaultValue: <String>[],
  )
  final List<String> ownerIds;
  @JsonKey(defaultValue: '')
  final String logo;
  @JsonKey(defaultValue: <String>[])
  final List<String> coverImages;
  @JsonKey(name: 'maxPendingJoinRequests', fromJson: _intFromJson)
  final int maxPendingJoinRequests;
  final TeamStatus status;
  @JsonKey(name: 'disabledAt')
  final String? disabledAt;
  @JsonKey(defaultValue: <String>[])
  final List<String> tags;
  @JsonKey(name: 'preferredPlayDays', defaultValue: <String>[])
  final List<String> preferredPlayDays;
  @JsonKey(name: 'preferredTimeSlot')
  final TeamPreferredTimeSlot? preferredTimeSlot;
  @JsonKey(name: 'lookingForMembers', defaultValue: false)
  final bool lookingForMembers;
  @JsonKey(name: 'teamOpenForMatch', defaultValue: false)
  final bool teamOpenForMatch;
  @JsonKey(name: 'pinnedNotices', defaultValue: <String>[])
  final List<String> pinnedNotices;
  @JsonKey(fromJson: _intFromJson, defaultValue: 0)
  final int matchesPlayed;
  @JsonKey(fromJson: _intFromJson, defaultValue: 0)
  final int wins;
  @JsonKey(fromJson: _intFromJson, defaultValue: 0)
  final int losses;
  @JsonKey(fromJson: _intFromJson, defaultValue: 0)
  final int draws;
  @JsonKey(fromJson: _doubleFromJson, defaultValue: 0.0)
  final double winRate;
  @JsonKey(
    name: 'sportStats',
    fromJson: _sportStatsMapFromJson,
    toJson: _sportStatsMapToJson,
  )
  final TeamSportStatsMap sportStats;
  @JsonKey(defaultValue: <TeamEarnedBadge>[])
  final List<TeamEarnedBadge> badges;
  @JsonKey(name: 'createdAt')
  final String? createdAt;
  @JsonKey(name: 'updatedAt')
  final String? updatedAt;

  TeamModel({
    this.id,
    required this.name,
    this.shortName,
    this.description,
    this.tagline,
    TeamSocialLinks? socialLinks,
    this.foundedYear,
    required this.sportType,
    this.genderCategory,
    this.location,
    required this.visibility,
    required this.joinMode,
    this.createdBy,
    this.ownerIds = const [],
    this.logo = '',
    this.coverImages = const [],
    required this.maxPendingJoinRequests,
    required this.status,
    this.disabledAt,
    this.tags = const [],
    this.preferredPlayDays = const [],
    this.preferredTimeSlot,
    this.lookingForMembers = false,
    this.teamOpenForMatch = false,
    this.pinnedNotices = const [],
    this.matchesPlayed = 0,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.winRate = 0.0,
    TeamSportStatsMap? sportStats,
    this.badges = const [],
    this.createdAt,
    this.updatedAt,
  }) : socialLinks = socialLinks ?? const TeamSocialLinks(),
       sportStats = sportStats ?? const TeamSportStatsMap();

  factory TeamModel.fromJson(Map<String, dynamic> json) =>
      _$TeamModelFromJson(json);

  Map<String, dynamic> toJson() => _$TeamModelToJson(this);

  UserFieldInstance? _createdByHelper;
  UserFieldInstance get createdByHelper {
    _createdByHelper ??= UserFieldInstance(createdBy);
    return _createdByHelper!;
  }

  bool isOwner(String userId) => ownerIds.contains(userId);

  /// Stats for this team's [sportType], if present in [sportStats].
  dynamic get statsForSport {
    return switch (sportType) {
      TeamSportType.football => sportStats.football,
      TeamSportType.cricket => sportStats.cricket,
    };
  }
}
