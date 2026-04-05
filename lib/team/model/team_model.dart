import 'package:json_annotation/json_annotation.dart';

import '../../core/models/location_model.dart';
import '../../core/models/user_field_converters.dart';
import '../../core/models/user_field_instance.dart';

export '../../core/models/location_model.dart';

part 'team_model.g.dart';

/// Backend [SportType].
enum TeamSportType {
  cricket,
  football,
}

/// Backend [TeamVisibility].
enum TeamVisibility {
  public,
  private,
}

/// Backend [TeamJoinMode]. Private teams cannot use [open] (server validates).
enum TeamJoinMode {
  open,
  approval,
}

/// Backend [TeamStatus].
enum TeamStatus {
  active,
  inactive,
  archived,
}

List<String> _ownerIdsFromJson(dynamic json) {
  if (json == null) return const [];
  return (json as List<dynamic>).map((e) => e.toString()).toList();
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

/// Matches backend [TeamFilterDto] / `TeamFilterSchema` query params.
class TeamFilterQuery {
  final TeamVisibility? visibility;
  final TeamStatus? status;
  final TeamSportType? sportType;
  final int page;
  final int limit;
  final double? nearbyLat;
  final double? nearbyLng;
  final double? nearbyRadiusKm;

  const TeamFilterQuery({
    this.visibility,
    this.status,
    this.sportType,
    this.page = 1,
    this.limit = 10,
    this.nearbyLat,
    this.nearbyLng,
    this.nearbyRadiusKm,
  });

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (visibility != null) params['visibility'] = visibility!.name;
    if (status != null) params['status'] = status!.name;
    if (sportType != null) params['sportType'] = sportType!.name;
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

@JsonSerializable(explicitToJson: true)
class CreateTeamRequest {
  final String name;
  final String? description;
  final TeamSportType sportType;
  @JsonKey(name: 'maxRosterSize')
  final int maxRosterSize;
  @JsonKey(name: 'maxPendingJoinRequests')
  final int maxPendingJoinRequests;
  final String? logo;
  final List<String>? coverImages;
  final TeamVisibility visibility;
  final TeamJoinMode joinMode;
  final LocationModel? location;

  CreateTeamRequest({
    required this.name,
    this.description,
    required this.sportType,
    required this.maxRosterSize,
    required this.maxPendingJoinRequests,
    this.logo,
    this.coverImages,
    required this.visibility,
    required this.joinMode,
    this.location,
  });

  factory CreateTeamRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateTeamRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateTeamRequestToJson(this);
}

@JsonSerializable(explicitToJson: true)
class UpdateTeamRequest {
  final String? name;
  final String? description;
  final TeamSportType? sportType;
  @JsonKey(name: 'maxRosterSize')
  final int? maxRosterSize;
  @JsonKey(name: 'maxPendingJoinRequests')
  final int? maxPendingJoinRequests;
  final String? logo;
  final List<String>? coverImages;
  final TeamVisibility? visibility;
  final TeamJoinMode? joinMode;
  final TeamStatus? status;
  final LocationModel? location;

  UpdateTeamRequest({
    this.name,
    this.description,
    this.sportType,
    this.maxRosterSize,
    this.maxPendingJoinRequests,
    this.logo,
    this.coverImages,
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
  final String? description;
  final TeamSportType sportType;
  final LocationModel? location;
  final TeamVisibility visibility;
  final TeamJoinMode joinMode;
  @JsonKey(name: 'createdBy')
  @UserConverter()
  final dynamic createdBy;
  @JsonKey(name: 'ownerIds', fromJson: _ownerIdsFromJson, defaultValue: <String>[])
  final List<String> ownerIds;
  @JsonKey(defaultValue: '')
  final String logo;
  @JsonKey(defaultValue: <String>[])
  final List<String> coverImages;
  @JsonKey(name: 'maxRosterSize')
  final int maxRosterSize;
  @JsonKey(name: 'maxPendingJoinRequests')
  final int maxPendingJoinRequests;
  final TeamStatus status;
  @JsonKey(name: 'createdAt')
  final String? createdAt;
  @JsonKey(name: 'updatedAt')
  final String? updatedAt;

  TeamModel({
    this.id,
    required this.name,
    this.description,
    required this.sportType,
    this.location,
    required this.visibility,
    required this.joinMode,
    this.createdBy,
    this.ownerIds = const [],
    this.logo = '',
    this.coverImages = const [],
    required this.maxRosterSize,
    required this.maxPendingJoinRequests,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) =>
      _$TeamModelFromJson(json);

  Map<String, dynamic> toJson() => _$TeamModelToJson(this);

  UserFieldInstance? _createdByHelper;
  UserFieldInstance get createdByHelper {
    _createdByHelper ??= UserFieldInstance(createdBy);
    return _createdByHelper!;
  }

  bool isOwner(String userId) => ownerIds.contains(userId);
}
