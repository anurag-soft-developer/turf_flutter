import 'package:json_annotation/json_annotation.dart';

import '../../../core/models/team/team_ref_converter.dart';
import '../../../core/models/team/team_ref_field_instance.dart';
import '../../../core/models/user_field_converters.dart';
import '../../../core/models/user_field_instance.dart';

part 'announced_player_model.g.dart';

/// Backend [AnnouncedPlayerRole].
enum AnnouncedPlayerRole {
  batsman,
  bowler,
  allrounder,
  @JsonValue('wicket_keeper')
  wicketKeeper,
}

/// Backend embedded `announcedPlayers[]` item ([AnnouncedPlayer]).
@JsonSerializable(explicitToJson: true)
class AnnouncedPlayerModel {
  /// Lean id or populated team subset ([TeamMemberFieldInstance]).
  @JsonKey(name: 'teamId')
  @TeamRefConverter()
  final dynamic teamId;

  final String name;
  final String? avatar;
  final String? email;

  /// Lean id or populated user subset.
  @JsonKey(name: 'userId')
  @UserConverter()
  final dynamic userId;

  @JsonKey(name: 'is_substitute', defaultValue: false)
  final bool isSubstitute;

  final AnnouncedPlayerRole role;

  @JsonKey(defaultValue: false)
  final bool isCaption;

  @JsonKey(defaultValue: false)
  final bool isWiseCaption;

  const AnnouncedPlayerModel({
    required this.teamId,
    required this.name,
    this.avatar,
    this.email,
    required this.userId,
    this.isSubstitute = false,
    required this.role,
    this.isCaption = false,
    this.isWiseCaption = false,
  });

  factory AnnouncedPlayerModel.fromJson(Map<String, dynamic> json) =>
      _$AnnouncedPlayerModelFromJson(json);

  Map<String, dynamic> toJson() => _$AnnouncedPlayerModelToJson(this);

  TeamRefFieldInstance get teamIdHelper => TeamRefFieldInstance(teamId);

  UserFieldInstance get userIdHelper => UserFieldInstance(userId);
}

String _announcedPlayerRoleApiValue(AnnouncedPlayerRole role) {
  switch (role) {
    case AnnouncedPlayerRole.batsman:
      return 'batsman';
    case AnnouncedPlayerRole.bowler:
      return 'bowler';
    case AnnouncedPlayerRole.allrounder:
      return 'allrounder';
    case AnnouncedPlayerRole.wicketKeeper:
      return 'wicket_keeper';
  }
}

/// Row for `POST /matchmaking/:matchId/announced-players` (`players[]`).
class AnnouncedPlayerCreatePayload {
  final String name;
  final String? avatar;
  final String? email;
  final String userId;
  final bool isSubstitute;
  final AnnouncedPlayerRole role;
  final bool isCaption;
  final bool isWiseCaption;

  const AnnouncedPlayerCreatePayload({
    required this.name,
    this.avatar,
    this.email,
    required this.userId,
    this.isSubstitute = false,
    required this.role,
    this.isCaption = false,
    this.isWiseCaption = false,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name,
    if (avatar != null && avatar!.isNotEmpty) 'avatar': avatar,
    if (email != null && email!.isNotEmpty) 'email': email,
    'userId': userId,
    'is_substitute': isSubstitute,
    'role': _announcedPlayerRoleApiValue(role),
    'isCaption': isCaption,
    'isWiseCaption': isWiseCaption,
  };
}

/// Row for `PATCH /matchmaking/:matchId/announced-players` (`updates[]`).
class AnnouncedPlayerUpdatePayload {
  final String userId;
  final String? name;
  final String? avatar;
  final String? email;
  final bool? isSubstitute;
  final AnnouncedPlayerRole? role;
  final bool? isCaption;
  final bool? isWiseCaption;

  const AnnouncedPlayerUpdatePayload({
    required this.userId,
    this.name,
    this.avatar,
    this.email,
    this.isSubstitute,
    this.role,
    this.isCaption,
    this.isWiseCaption,
  });

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{'userId': userId};
    if (name != null) m['name'] = name;
    if (avatar != null) m['avatar'] = avatar;
    if (email != null) m['email'] = email;
    if (isSubstitute != null) m['is_substitute'] = isSubstitute;
    if (role != null) m['role'] = _announcedPlayerRoleApiValue(role!);
    if (isCaption != null) m['isCaption'] = isCaption;
    if (isWiseCaption != null) m['isWiseCaption'] = isWiseCaption;
    return m;
  }
}
