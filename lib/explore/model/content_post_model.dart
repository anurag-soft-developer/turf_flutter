import 'package:json_annotation/json_annotation.dart';

import '../../core/models/team/team_ref_converter.dart';
import '../../core/models/team/team_ref_field_instance.dart';
import '../../core/models/turf_field_converter.dart';
import '../../core/models/turf_field_instance.dart';
import '../../core/models/user_field_converters.dart';
import '../../core/models/user_field_instance.dart';
import '../../core/utils/mongo_id_util.dart';
import '../../match_up/model/team_match_model.dart';
import '../../team/model/team_model.dart';

part 'content_post_model.g.dart';

/// Backend `MediaKind`.
enum MediaKind { image, video }

/// Backend `PostStatus`.
enum PostStatus { draft, published, archived }

/// Populated media document on a content post.
@JsonSerializable()
class MediaModel {
  @JsonKey(name: '_id', fromJson: mongoIdFromJsonNullable)
  final String? id;
  final String url;
  final MediaKind kind;
  final String? caption;

  const MediaModel({
    this.id,
    required this.url,
    required this.kind,
    this.caption,
  });

  factory MediaModel.fromJson(Map<String, dynamic> json) =>
      _$MediaModelFromJson(json);

  Map<String, dynamic> toJson() => _$MediaModelToJson(this);
}

/// Lean `match` populate on posts: `_id fromTeam toTeam status sportType`.
@JsonSerializable(explicitToJson: true)
class PostMatchRef {
  @JsonKey(name: '_id', fromJson: mongoIdFromJsonNullable)
  final String? id;

  @TeamRefConverter()
  final dynamic fromTeam;

  @TeamRefConverter()
  final dynamic toTeam;

  final TeamMatchStatus status;
  final TeamSportType sportType;

  const PostMatchRef({
    this.id,
    this.fromTeam,
    this.toTeam,
    required this.status,
    required this.sportType,
  });

  factory PostMatchRef.fromJson(Map<String, dynamic> json) =>
      _$PostMatchRefFromJson(json);

  Map<String, dynamic> toJson() => _$PostMatchRefToJson(this);

  TeamRefFieldInstance get fromTeamHelper => TeamRefFieldInstance(fromTeam);

  TeamRefFieldInstance get toTeamHelper => TeamRefFieldInstance(toTeam);

  String get versusLabel {
    final from = fromTeamHelper.getName();
    final to = toTeamHelper.getName();
    if (from != null && to != null) return '$from vs $to';
    if (from != null) return from;
    if (to != null) return to;
    return 'Match';
  }
}

/// Backend `ContentPost` as returned on explore / populated lists.
@JsonSerializable(explicitToJson: true)
class ContentPostModel {
  @JsonKey(name: '_id', fromJson: mongoIdFromJsonNullable)
  final String? id;

  @UserConverter()
  final dynamic postedBy;

  @TeamRefConverter()
  final dynamic team;

  final PostMatchRef? match;

  @TurfConverter()
  final dynamic turf;

  final PostStatus status;
  final String title;
  final String content;
  @JsonKey(defaultValue: <String>[])
  final List<String> tags;
  final LocationModel? location;
  @JsonKey(defaultValue: <MediaModel>[])
  final List<MediaModel> media;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ContentPostModel({
    this.id,
    this.postedBy,
    this.team,
    this.match,
    this.turf,
    required this.status,
    this.title = '',
    this.content = '',
    this.tags = const [],
    this.location,
    this.media = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory ContentPostModel.fromJson(Map<String, dynamic> json) =>
      _$ContentPostModelFromJson(json);

  Map<String, dynamic> toJson() => _$ContentPostModelToJson(this);

  UserFieldInstance get postedByHelper => UserFieldInstance(postedBy);

  TeamRefFieldInstance get teamHelper => TeamRefFieldInstance(team);

  TurfFieldInstance get turfHelper => TurfFieldInstance(turf);

  MediaModel? get primaryMedia => media.isEmpty ? null : media.first;
}
