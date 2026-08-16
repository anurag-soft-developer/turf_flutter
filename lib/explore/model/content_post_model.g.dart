// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_post_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MediaModel _$MediaModelFromJson(Map<String, dynamic> json) => MediaModel(
  id: mongoIdFromJsonNullable(json['_id']),
  url: json['url'] as String,
  kind: $enumDecode(_$MediaKindEnumMap, json['kind']),
  caption: json['caption'] as String?,
);

Map<String, dynamic> _$MediaModelToJson(MediaModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'url': instance.url,
      'kind': _$MediaKindEnumMap[instance.kind]!,
      'caption': instance.caption,
    };

const _$MediaKindEnumMap = {MediaKind.image: 'image', MediaKind.video: 'video'};

PostMatchRef _$PostMatchRefFromJson(Map<String, dynamic> json) => PostMatchRef(
  id: mongoIdFromJsonNullable(json['_id']),
  fromTeam: const TeamRefConverter().fromJson(json['fromTeam']),
  toTeam: const TeamRefConverter().fromJson(json['toTeam']),
  status: $enumDecode(_$TeamMatchStatusEnumMap, json['status']),
  sportType: $enumDecode(_$TeamSportTypeEnumMap, json['sportType']),
);

Map<String, dynamic> _$PostMatchRefToJson(PostMatchRef instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'fromTeam': const TeamRefConverter().toJson(instance.fromTeam),
      'toTeam': const TeamRefConverter().toJson(instance.toTeam),
      'status': _$TeamMatchStatusEnumMap[instance.status]!,
      'sportType': _$TeamSportTypeEnumMap[instance.sportType]!,
    };

const _$TeamMatchStatusEnumMap = {
  TeamMatchStatus.requested: 'requested',
  TeamMatchStatus.accepted: 'accepted',
  TeamMatchStatus.negotiating: 'negotiating',
  TeamMatchStatus.scheduleFinalized: 'schedule_finalized',
  TeamMatchStatus.rejected: 'rejected',
  TeamMatchStatus.expired: 'expired',
  TeamMatchStatus.cancelled: 'cancelled',
  TeamMatchStatus.ongoing: 'ongoing',
  TeamMatchStatus.completed: 'completed',
  TeamMatchStatus.draw: 'draw',
  TeamMatchStatus.abandoned: 'abandoned',
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

ContentPostModel _$ContentPostModelFromJson(Map<String, dynamic> json) =>
    ContentPostModel(
      id: mongoIdFromJsonNullable(json['_id']),
      postedBy: const UserConverter().fromJson(json['postedBy']),
      team: const TeamRefConverter().fromJson(json['team']),
      match: json['match'] == null
          ? null
          : PostMatchRef.fromJson(json['match'] as Map<String, dynamic>),
      turf: const TurfConverter().fromJson(json['turf']),
      status: $enumDecode(_$PostStatusEnumMap, json['status']),
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          [],
      location: json['location'] == null
          ? null
          : LocationModel.fromJson(json['location'] as Map<String, dynamic>),
      media:
          (json['media'] as List<dynamic>?)
              ?.map((e) => MediaModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$ContentPostModelToJson(ContentPostModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'postedBy': const UserConverter().toJson(instance.postedBy),
      'team': const TeamRefConverter().toJson(instance.team),
      'match': instance.match?.toJson(),
      'turf': const TurfConverter().toJson(instance.turf),
      'status': _$PostStatusEnumMap[instance.status]!,
      'title': instance.title,
      'content': instance.content,
      'tags': instance.tags,
      'location': instance.location?.toJson(),
      'media': instance.media.map((e) => e.toJson()).toList(),
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$PostStatusEnumMap = {
  PostStatus.draft: 'draft',
  PostStatus.published: 'published',
  PostStatus.archived: 'archived',
};
