import 'package:json_annotation/json_annotation.dart';

import 'player_stats_models.dart';

export 'player_stats_models.dart';

part 'user_model.g.dart';

/// Backend `NotificationModule` string values (`turfBooking`, `matchmaking`).
enum NotificationModule {
  turfBooking,
  matchmaking,
}

extension NotificationModuleApi on NotificationModule {
  /// JSON object key sent to the API for [notificationModules].
  String get apiKey => switch (this) {
        NotificationModule.turfBooking => 'turfBooking',
        NotificationModule.matchmaking => 'matchmaking',
      };
}

NotificationModule? notificationModuleFromApiString(String key) {
  switch (key) {
    case 'turfBooking':
      return NotificationModule.turfBooking;
    case 'matchmaking':
      return NotificationModule.matchmaking;
    default:
      return null;
  }
}

Map<NotificationModule, bool>? notificationModulesFromJson(Object? json) {
  if (json == null) return null;
  if (json is! Map) return null;
  final out = <NotificationModule, bool>{};
  json.forEach((key, value) {
    final k = key?.toString();
    if (k == null || value is! bool) return;
    final mod = notificationModuleFromApiString(k);
    if (mod != null) out[mod] = value;
  });
  return out;
}

Object? notificationModulesToJson(Map<NotificationModule, bool>? map) {
  if (map == null) return null;
  return {for (final e in map.entries) e.key.apiKey: e.value};
}

/// Registered FCM device entry (also used in [UserModel.fcmTokens]).
@JsonSerializable()
class FcmTokenEntry {
  final String deviceKey;
  final String token;
  final String? platform;
  @JsonKey(name: 'updatedAt')
  final String? updatedAt;

  const FcmTokenEntry({
    required this.deviceKey,
    required this.token,
    this.platform,
    this.updatedAt,
  });

  factory FcmTokenEntry.fromJson(Map<String, dynamic> json) =>
      _$FcmTokenEntryFromJson(json);

  Map<String, dynamic> toJson() => _$FcmTokenEntryToJson(this);

  DateTime? get updatedAtDate {
    if (updatedAt == null || updatedAt!.isEmpty) return null;
    try {
      return DateTime.parse(updatedAt!);
    } catch (_) {
      return null;
    }
  }
}

@JsonSerializable(explicitToJson: true)
class UserModel {
  @JsonKey(name: '_id')
  final String? id;
  final String? email;
  final String? role;
  @JsonKey(name: 'fullName')
  final String? fullName;
  final String? bio;
  final String? avatar;
  @JsonKey(name: 'isActive')
  final bool? isActive;
  @JsonKey(name: 'isVerified')
  final bool? isVerified;
  @JsonKey(name: 'isEmailVerified')
  final bool? isEmailVerified;
  final String? phone;
  @JsonKey(name: 'lastLogin')
  final String? lastLogin;
  @JsonKey(name: 'createdAt')
  final String? createdAt;
  @JsonKey(name: 'updatedAt')
  final String? updatedAt;
  @JsonKey(name: 'playerSportStats', defaultValue: [])
  final List<PlayerSportEntry> playerSportStats;
  @JsonKey(name: 'badges', defaultValue: [])
  final List<EarnedBadge> badges;
  @JsonKey(name: 'isPasswordExists')
  final bool? isPasswordExists;
  @JsonKey(name: 'twoFactorEnabled')
  final bool? twoFactorEnabled;
  @JsonKey(name: 'emailNotificationsEnabled')
  final bool? emailNotificationsEnabled;
  @JsonKey(name: 'smsNotificationsEnabled')
  final bool? smsNotificationsEnabled;
  @JsonKey(name: 'notificationsEnabled')
  final bool? notificationsEnabled;
  @JsonKey(name: 'notificationModules', fromJson: notificationModulesFromJson, toJson: notificationModulesToJson)
  final Map<NotificationModule, bool>? notificationModules;
  @JsonKey(name: 'fcmTokens', defaultValue: [])
  final List<FcmTokenEntry> fcmTokens;

  UserModel({
    this.id,
    this.email,
    this.role,
    this.fullName,
    this.bio,
    this.avatar,
    this.isActive,
    this.isVerified,
    this.isEmailVerified,
    this.phone,
    this.lastLogin,
    this.createdAt,
    this.updatedAt,
    this.playerSportStats = const [],
    this.badges = const [],
    this.isPasswordExists,
    this.twoFactorEnabled,
    this.emailNotificationsEnabled,
    this.smsNotificationsEnabled,
    this.notificationsEnabled,
    this.notificationModules,
    this.fcmTokens = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  UserModel copyWith({
    String? id,
    String? email,
    String? role,
    String? fullName,
    String? bio,
    String? avatar,
    bool? isActive,
    bool? isVerified,
    bool? isEmailVerified,
    String? phone,
    String? lastLogin,
    String? createdAt,
    String? updatedAt,
    List<PlayerSportEntry>? playerSportStats,
    List<EarnedBadge>? badges,
    bool? isPasswordExists,
    bool? twoFactorEnabled,
    bool? emailNotificationsEnabled,
    bool? smsNotificationsEnabled,
    bool? notificationsEnabled,
    Map<NotificationModule, bool>? notificationModules,
    List<FcmTokenEntry>? fcmTokens,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      bio: bio ?? this.bio,
      avatar: avatar ?? this.avatar,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      phone: phone ?? this.phone,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      playerSportStats: playerSportStats ?? this.playerSportStats,
      badges: badges ?? this.badges,
      isPasswordExists: isPasswordExists ?? this.isPasswordExists,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      emailNotificationsEnabled:
          emailNotificationsEnabled ?? this.emailNotificationsEnabled,
      smsNotificationsEnabled:
          smsNotificationsEnabled ?? this.smsNotificationsEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationModules: notificationModules ?? this.notificationModules,
    );
  }

  // Helper getter for backward compatibility and display
  String get displayName => fullName ?? email?.split('@').first ?? 'User';

  // Helper getter for created date parsing
  DateTime? get createdAtDate {
    if (createdAt == null) return null;
    try {
      return DateTime.parse(createdAt!);
    } catch (e) {
      return null;
    }
  }

  // Helper getter for updated date parsing
  DateTime? get updatedAtDate {
    if (updatedAt == null) return null;
    try {
      return DateTime.parse(updatedAt!);
    } catch (e) {
      return null;
    }
  }

  // Helper getter for last login date parsing
  DateTime? get lastLoginDate {
    if (lastLogin == null) return null;
    try {
      return DateTime.parse(lastLogin!);
    } catch (e) {
      return null;
    }
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, fullName: $fullName)';
  }
}

@JsonSerializable()
class AuthResponse {
  final UserModel user;
  @JsonKey(name: 'accessToken')
  final String accessToken;
  @JsonKey(name: 'refreshToken')
  final String refreshToken;

  AuthResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}

@JsonSerializable()
class LoginOtpChallengeResponse {
  final String message;
  @JsonKey(name: 'requiresOtp')
  final bool requiresOtp;
  final String email;

  LoginOtpChallengeResponse({
    required this.message,
    required this.requiresOtp,
    required this.email,
  });

  factory LoginOtpChallengeResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginOtpChallengeResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LoginOtpChallengeResponseToJson(this);
}

class LoginResult {
  final UserModel? user;
  final LoginOtpChallengeResponse? otpChallenge;

  const LoginResult._({this.user, this.otpChallenge});

  bool get requiresOtp => otpChallenge?.requiresOtp == true;

  factory LoginResult.authenticated(UserModel user) =>
      LoginResult._(user: user);

  factory LoginResult.challenge(LoginOtpChallengeResponse challenge) =>
      LoginResult._(otpChallenge: challenge);
}

@JsonSerializable()
class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);

  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

@JsonSerializable()
class RegisterRequest {
  final String email;
  final String password;
  @JsonKey(name: 'fullName')
  final String fullName;
  final String? phone;

  RegisterRequest({
    required this.email,
    required this.password,
    required this.fullName,
    this.phone,
  });

  factory RegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterRequestToJson(this);
}

@JsonSerializable()
class VerifyLoginOtpRequest {
  final String email;
  final String otp;

  VerifyLoginOtpRequest({required this.email, required this.otp});

  factory VerifyLoginOtpRequest.fromJson(Map<String, dynamic> json) =>
      _$VerifyLoginOtpRequestFromJson(json);

  Map<String, dynamic> toJson() => _$VerifyLoginOtpRequestToJson(this);
}

@JsonSerializable()
class UpdateTwoFactorRequest {
  final bool enabled;
  final String otp;

  UpdateTwoFactorRequest({required this.enabled, required this.otp});

  factory UpdateTwoFactorRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateTwoFactorRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateTwoFactorRequestToJson(this);
}

@JsonSerializable()
class GoogleSignInRequest {
  @JsonKey(name: 'idToken')
  final String idToken;

  GoogleSignInRequest({required this.idToken});

  factory GoogleSignInRequest.fromJson(Map<String, dynamic> json) =>
      _$GoogleSignInRequestFromJson(json);

  Map<String, dynamic> toJson() => _$GoogleSignInRequestToJson(this);
}

