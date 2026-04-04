import 'package:json_annotation/json_annotation.dart';

import '../../core/models/location_model.dart';
import '../../core/models/turf_field_converter.dart';
import '../../core/models/user_field_converters.dart';

export '../../core/models/location_model.dart';

part 'local_match_model.g.dart';

enum LocalMatchVisibility {
  public,
  private,
}

enum LocalMatchJoinMode {
  open,
  approval,
}

enum LocalMatchStatus {
  open,
  full,
  cancelled,
  completed,
}

enum JoinRequestStatus {
  pending,
  accepted,
  rejected,
}

@JsonSerializable(explicitToJson: true)
class LocalMatchMemberModel {
  @UserConverter()
  final dynamic user;

  @JsonKey(name: 'joinedAt')
  final String joinedAt;

  LocalMatchMemberModel({required this.user, required this.joinedAt});

  factory LocalMatchMemberModel.fromJson(Map<String, dynamic> json) =>
      _$LocalMatchMemberModelFromJson(json);

  Map<String, dynamic> toJson() => _$LocalMatchMemberModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class JoinRequestEntryModel {
  @JsonKey(name: '_id')
  final String? id;

  @UserConverter()
  final dynamic user;

  final JoinRequestStatus status;

  @JsonKey(name: 'createdAt')
  final String createdAt;

  @UserConverter()
  final dynamic reviewedBy;

  @JsonKey(name: 'reviewedAt')
  final String? reviewedAt;

  JoinRequestEntryModel({
    this.id,
    required this.user,
    required this.status,
    required this.createdAt,
    this.reviewedBy,
    this.reviewedAt,
  });

  factory JoinRequestEntryModel.fromJson(Map<String, dynamic> json) =>
      _$JoinRequestEntryModelFromJson(json);

  Map<String, dynamic> toJson() => _$JoinRequestEntryModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class LocalMatchModel {
  @JsonKey(name: '_id')
  final String? id;

  final String title;

  final String? description;

  @JsonKey(defaultValue: <String>[])
  final List<String> sportTypes;

  final LocalMatchVisibility visibility;

  final LocalMatchJoinMode joinMode;

  final LocationModel location;

  @TurfConverter()
  final dynamic turf;

  @JsonKey(name: 'createdBy')
  @UserConverter()
  final dynamic createdBy;

  @JsonKey(defaultValue: <String>[])
  final List<String> hostIds;

  @JsonKey(defaultValue: <LocalMatchMemberModel>[])
  final List<LocalMatchMemberModel> members;

  @JsonKey(defaultValue: <JoinRequestEntryModel>[])
  final List<JoinRequestEntryModel> joinRequests;

  @JsonKey(name: 'maxMembers')
  final int maxMembers;

  @JsonKey(name: 'maxPendingJoinRequests')
  final int maxPendingJoinRequests;

  @JsonKey(name: 'closingTime')
  final String closingTime;

  @JsonKey(name: 'eventStartsAt')
  final String? eventStartsAt;

  @JsonKey(name: 'eventEndsAt')
  final String? eventEndsAt;

  final LocalMatchStatus status;

  @JsonKey(name: 'createdAt')
  final String? createdAt;

  @JsonKey(name: 'updatedAt')
  final String? updatedAt;

  LocalMatchModel({
    this.id,
    required this.title,
    this.description,
    required this.sportTypes,
    required this.visibility,
    required this.joinMode,
    required this.location,
    this.turf,
    required this.createdBy,
    required this.hostIds,
    required this.members,
    required this.joinRequests,
    required this.maxMembers,
    required this.maxPendingJoinRequests,
    required this.closingTime,
    this.eventStartsAt,
    this.eventEndsAt,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory LocalMatchModel.fromJson(Map<String, dynamic> json) =>
      _$LocalMatchModelFromJson(json);

  Map<String, dynamic> toJson() => _$LocalMatchModelToJson(this);
}

// --- API request bodies ---

@JsonSerializable(explicitToJson: true)
class CreateLocalMatchRequest {
  final String title;
  final String? description;
  final List<String>? sportTypes;
  final LocalMatchVisibility visibility;
  final LocalMatchJoinMode joinMode;
  final LocationModel? location;
  final String? turf;

  @JsonKey(name: 'maxMembers')
  final int maxMembers;

  @JsonKey(name: 'maxPendingJoinRequests')
  final int maxPendingJoinRequests;

  @JsonKey(name: 'closingTime')
  final String closingTime;

  @JsonKey(name: 'eventStartsAt')
  final String? eventStartsAt;

  @JsonKey(name: 'eventEndsAt')
  final String? eventEndsAt;

  CreateLocalMatchRequest({
    required this.title,
    this.description,
    this.sportTypes,
    required this.visibility,
    required this.joinMode,
    this.location,
    this.turf,
    required this.maxMembers,
    required this.maxPendingJoinRequests,
    required this.closingTime,
    this.eventStartsAt,
    this.eventEndsAt,
  });

  factory CreateLocalMatchRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateLocalMatchRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateLocalMatchRequestToJson(this);
}

@JsonSerializable(explicitToJson: true)
class UpdateLocalMatchLocationRequest {
  final String? address;
  final GeoPointModel? coordinates;

  UpdateLocalMatchLocationRequest({this.address, this.coordinates});

  factory UpdateLocalMatchLocationRequest.fromJson(
    Map<String, dynamic> json,
  ) =>
      _$UpdateLocalMatchLocationRequestFromJson(json);

  Map<String, dynamic> toJson() =>
      _$UpdateLocalMatchLocationRequestToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class UpdateLocalMatchRequest {
  final String? title;
  final String? description;
  final List<String>? sportTypes;

  @JsonKey(name: 'maxMembers')
  final int? maxMembers;

  @JsonKey(name: 'maxPendingJoinRequests')
  final int? maxPendingJoinRequests;

  @JsonKey(name: 'closingTime')
  final String? closingTime;

  @JsonKey(name: 'eventStartsAt')
  final String? eventStartsAt;

  @JsonKey(name: 'eventEndsAt')
  final String? eventEndsAt;

  final LocalMatchVisibility? visibility;
  final LocalMatchJoinMode? joinMode;

  final UpdateLocalMatchLocationRequest? location;
  final String? turf;
  final LocalMatchStatus? status;

  UpdateLocalMatchRequest({
    this.title,
    this.description,
    this.sportTypes,
    this.maxMembers,
    this.maxPendingJoinRequests,
    this.closingTime,
    this.eventStartsAt,
    this.eventEndsAt,
    this.visibility,
    this.joinMode,
    this.location,
    this.turf,
    this.status,
  });

  factory UpdateLocalMatchRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateLocalMatchRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateLocalMatchRequestToJson(this);
}

@JsonSerializable()
class PromoteHostRequest {
  @JsonKey(name: 'userId')
  final String userId;

  PromoteHostRequest({required this.userId});

  factory PromoteHostRequest.fromJson(Map<String, dynamic> json) =>
      _$PromoteHostRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PromoteHostRequestToJson(this);
}
