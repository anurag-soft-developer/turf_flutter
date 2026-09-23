import 'package:json_annotation/json_annotation.dart';

import '../../../core/models/team/team_ref_converter.dart';
import '../../../core/models/team/team_ref_field_instance.dart';
import '../../../core/models/user_field_converters.dart';
import '../../../core/models/user_field_instance.dart';
import '../../../core/utils/mongo_id_util.dart';

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

  /// Lean id or populated user subset. Null for walk-in guests.
  @JsonKey(name: 'userId')
  @UserConverter()
  final dynamic userId;

  @JsonKey(defaultValue: false)
  final bool isGuest;

  /// Server-generated walk-in id. Used as the scoring participant id.
  @JsonKey(name: 'guestId', fromJson: mongoIdFromJsonNullable)
  final String? guestId;

  @JsonKey(name: 'is_substitute', defaultValue: false)
  final bool isSubstitute;

  /// True once involved in any live substitution (off or on).
  @JsonKey(name: 'is_substituted', defaultValue: false)
  final bool isSubstituted;

  /// Times involved in a substitution (off or on).
  @JsonKey(name: 'substitute_count', defaultValue: 0)
  final int substituteCount;

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
    this.userId,
    this.isGuest = false,
    this.guestId,
    this.isSubstitute = false,
    this.isSubstituted = false,
    this.substituteCount = 0,
    required this.role,
    this.isCaption = false,
    this.isWiseCaption = false,
  });

  factory AnnouncedPlayerModel.fromJson(Map<String, dynamic> json) =>
      _$AnnouncedPlayerModelFromJson(json);

  Map<String, dynamic> toJson() => _$AnnouncedPlayerModelToJson(this);

  AnnouncedPlayerModel copyWith({
    dynamic teamId,
    String? name,
    String? avatar,
    String? email,
    dynamic userId,
    bool? isGuest,
    String? guestId,
    bool? isSubstitute,
    bool? isSubstituted,
    int? substituteCount,
    AnnouncedPlayerRole? role,
    bool? isCaption,
    bool? isWiseCaption,
  }) {
    return AnnouncedPlayerModel(
      teamId: teamId ?? this.teamId,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      email: email ?? this.email,
      userId: userId ?? this.userId,
      isGuest: isGuest ?? this.isGuest,
      guestId: guestId ?? this.guestId,
      isSubstitute: isSubstitute ?? this.isSubstitute,
      isSubstituted: isSubstituted ?? this.isSubstituted,
      substituteCount: substituteCount ?? this.substituteCount,
      role: role ?? this.role,
      isCaption: isCaption ?? this.isCaption,
      isWiseCaption: isWiseCaption ?? this.isWiseCaption,
    );
  }

  TeamRefFieldInstance get teamIdHelper => TeamRefFieldInstance(teamId);

  UserFieldInstance get userIdHelper => UserFieldInstance(userId);

  /// Registered `userId`, otherwise walk-in `guestId`.
  String? get participantId {
    final uid = userIdHelper.getId();
    if (uid != null && uid.isNotEmpty) return uid;
    if (guestId != null && guestId!.isNotEmpty) return guestId;
    return null;
  }
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
  final String? userId;
  final bool isGuest;
  final bool isSubstitute;
  final AnnouncedPlayerRole role;
  final bool isCaption;
  final bool isWiseCaption;

  const AnnouncedPlayerCreatePayload({
    required this.name,
    this.avatar,
    this.email,
    this.userId,
    this.isGuest = false,
    this.isSubstitute = false,
    required this.role,
    this.isCaption = false,
    this.isWiseCaption = false,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name,
    if (avatar != null && avatar!.isNotEmpty) 'avatar': avatar,
    if (email != null && email!.isNotEmpty) 'email': email,
    if (userId != null && userId!.isNotEmpty) 'userId': userId,
    if (isGuest) 'isGuest': true,
    'is_substitute': isSubstitute,
    'role': _announcedPlayerRoleApiValue(role),
    'isCaption': isCaption,
    'isWiseCaption': isWiseCaption,
  };
}

/// Row for `PATCH /matchmaking/:matchId/announced-players` (`updates[]`).
class AnnouncedPlayerUpdatePayload {
  final String? userId;
  final String? guestId;
  final String? name;
  final String? avatar;
  final String? email;
  final bool? isSubstitute;
  final AnnouncedPlayerRole? role;
  final bool? isCaption;
  final bool? isWiseCaption;

  const AnnouncedPlayerUpdatePayload({
    this.userId,
    this.guestId,
    this.name,
    this.avatar,
    this.email,
    this.isSubstitute,
    this.role,
    this.isCaption,
    this.isWiseCaption,
  });

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{};
    if (userId != null && userId!.isNotEmpty) m['userId'] = userId;
    if (guestId != null && guestId!.isNotEmpty) m['guestId'] = guestId;
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
