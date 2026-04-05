import 'package:json_annotation/json_annotation.dart';

import '../../../core/models/team/team_member_field_instance.dart';
import '../../../core/models/team/team_ref_converter.dart';
import '../../../core/models/user_field_converters.dart';
import '../../../core/models/user_field_instance.dart';

export '../../../core/models/location_model.dart';
export '../../../core/models/team/team_member_field_instance.dart';
export '../../../core/models/team/team_ref_converter.dart';
export '../../model/team_model.dart' show TeamSportType;

part 'team_member_model.g.dart';

/// Backend [TeamMemberStatus].
enum TeamMemberStatus {
  pending,
  active,
  resigned,
  removed,
  rejected,
}

/// Backend [LeadershipRole].
enum LeadershipRole {
  captain,
  @JsonValue('vice_captain')
  viceCaptain,
}

/// Backend [LineupCategory].
enum LineupCategory {
  starter,
  substitute,
}

/// Query for `GET /teams/:teamId/members` ([TeamMemberFilterDto]).
class TeamMemberRosterFilterQuery {
  final TeamMemberStatus? status;
  final int page;
  final int limit;

  const TeamMemberRosterFilterQuery({
    this.status,
    this.page = 1,
    this.limit = 20,
  });

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (status != null) params['status'] = status!.name;
    return params;
  }
}

/// Query for `GET /team-members/me` ([MyMembershipsFilterDto]).
class MyTeamMembershipsFilterQuery {
  final TeamMemberStatus? status;
  final int page;
  final int limit;

  const MyTeamMembershipsFilterQuery({
    this.status,
    this.page = 1,
    this.limit = 20,
  });

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (status != null) params['status'] = status!.name;
    return params;
  }
}

/// `POST /teams/:teamId/members/leave` success payload.
class LeaveTeamResponse {
  final String message;
  final bool success;

  const LeaveTeamResponse({required this.message, required this.success});

  factory LeaveTeamResponse.fromJson(Map<String, dynamic> json) {
    return LeaveTeamResponse(
      message: json['message'] as String? ?? '',
      success: json['success'] as bool? ?? false,
    );
  }
}

@JsonSerializable(explicitToJson: true)
class UpdateTeamMemberRequest {
  final LeadershipRole? leadershipRole;
  final String? playingPosition;
  final LineupCategory? lineupCategory;

  UpdateTeamMemberRequest({
    this.leadershipRole,
    this.playingPosition,
    this.lineupCategory,
  });

  factory UpdateTeamMemberRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateTeamMemberRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateTeamMemberRequestToJson(this);
}

@JsonSerializable(explicitToJson: true)
class TeamMemberModel {
  @JsonKey(name: '_id')
  final String? id;

  @TeamRefConverter()
  final dynamic team;

  @JsonKey(name: 'user')
  @UserConverter()
  final dynamic user;

  final TeamMemberStatus status;

  @JsonKey(name: 'leadershipRole')
  final LeadershipRole? leadershipRole;

  @JsonKey(name: 'playingPosition')
  final String? playingPosition;

  @JsonKey(name: 'lineupCategory', defaultValue: LineupCategory.starter)
  final LineupCategory lineupCategory;

  @JsonKey(name: 'joinedAt')
  final String? joinedAt;

  @JsonKey(name: 'leftAt')
  final String? leftAt;

  @JsonKey(name: 'reviewedBy')
  @UserConverter()
  final dynamic reviewedBy;

  @JsonKey(name: 'reviewedAt')
  final String? reviewedAt;

  @JsonKey(name: 'createdAt')
  final String? createdAt;

  @JsonKey(name: 'updatedAt')
  final String? updatedAt;

  TeamMemberModel({
    this.id,
    this.team,
    this.user,
    required this.status,
    this.leadershipRole,
    this.playingPosition,
    this.lineupCategory = LineupCategory.starter,
    this.joinedAt,
    this.leftAt,
    this.reviewedBy,
    this.reviewedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory TeamMemberModel.fromJson(Map<String, dynamic> json) =>
      _$TeamMemberModelFromJson(json);

  Map<String, dynamic> toJson() => _$TeamMemberModelToJson(this);

  UserFieldInstance? _userHelper;
  UserFieldInstance get userHelper {
    _userHelper ??= UserFieldInstance(user);
    return _userHelper!;
  }

  UserFieldInstance? _reviewedByHelper;
  UserFieldInstance get reviewedByHelper {
    _reviewedByHelper ??= UserFieldInstance(reviewedBy);
    return _reviewedByHelper!;
  }

  /// Resolved team id whether [team] is a raw id or [TeamMemberFieldInstance].
  String? get teamId {
    final t = team;
    if (t is String) return t;
    if (t is TeamMemberFieldInstance) return t.id;
    return null;
  }
}
