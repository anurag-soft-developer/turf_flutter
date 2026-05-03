// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FcmTokenEntry _$FcmTokenEntryFromJson(Map<String, dynamic> json) =>
    FcmTokenEntry(
      deviceKey: json['deviceKey'] as String,
      token: json['token'] as String,
      platform: json['platform'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );

Map<String, dynamic> _$FcmTokenEntryToJson(FcmTokenEntry instance) =>
    <String, dynamic>{
      'deviceKey': instance.deviceKey,
      'token': instance.token,
      'platform': instance.platform,
      'updatedAt': instance.updatedAt,
    };

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: json['_id'] as String?,
  email: json['email'] as String?,
  role: json['role'] as String?,
  fullName: json['fullName'] as String?,
  bio: json['bio'] as String?,
  avatar: json['avatar'] as String?,
  isActive: json['isActive'] as bool?,
  isVerified: json['isVerified'] as bool?,
  isEmailVerified: json['isEmailVerified'] as bool?,
  phone: json['phone'] as String?,
  lastLogin: json['lastLogin'] as String?,
  createdAt: json['createdAt'] as String?,
  updatedAt: json['updatedAt'] as String?,
  playerSportStats:
      (json['playerSportStats'] as List<dynamic>?)
          ?.map((e) => PlayerSportEntry.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  badges:
      (json['badges'] as List<dynamic>?)
          ?.map((e) => EarnedBadge.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  isPasswordExists: json['isPasswordExists'] as bool?,
  twoFactorEnabled: json['twoFactorEnabled'] as bool?,
  emailNotificationsEnabled: json['emailNotificationsEnabled'] as bool?,
  smsNotificationsEnabled: json['smsNotificationsEnabled'] as bool?,
  notificationsEnabled: json['notificationsEnabled'] as bool?,
  notificationModules: notificationModulesFromJson(json['notificationModules']),
  fcmTokens:
      (json['fcmTokens'] as List<dynamic>?)
          ?.map((e) => FcmTokenEntry.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  '_id': instance.id,
  'email': instance.email,
  'role': instance.role,
  'fullName': instance.fullName,
  'bio': instance.bio,
  'avatar': instance.avatar,
  'isActive': instance.isActive,
  'isVerified': instance.isVerified,
  'isEmailVerified': instance.isEmailVerified,
  'phone': instance.phone,
  'lastLogin': instance.lastLogin,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
  'playerSportStats': instance.playerSportStats.map((e) => e.toJson()).toList(),
  'badges': instance.badges.map((e) => e.toJson()).toList(),
  'isPasswordExists': instance.isPasswordExists,
  'twoFactorEnabled': instance.twoFactorEnabled,
  'emailNotificationsEnabled': instance.emailNotificationsEnabled,
  'smsNotificationsEnabled': instance.smsNotificationsEnabled,
  'notificationsEnabled': instance.notificationsEnabled,
  'notificationModules': notificationModulesToJson(
    instance.notificationModules,
  ),
  'fcmTokens': instance.fcmTokens.map((e) => e.toJson()).toList(),
};

AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) => AuthResponse(
  user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
  accessToken: json['accessToken'] as String,
  refreshToken: json['refreshToken'] as String,
);

Map<String, dynamic> _$AuthResponseToJson(AuthResponse instance) =>
    <String, dynamic>{
      'user': instance.user,
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
    };

LoginOtpChallengeResponse _$LoginOtpChallengeResponseFromJson(
  Map<String, dynamic> json,
) => LoginOtpChallengeResponse(
  message: json['message'] as String,
  requiresOtp: json['requiresOtp'] as bool,
  email: json['email'] as String,
);

Map<String, dynamic> _$LoginOtpChallengeResponseToJson(
  LoginOtpChallengeResponse instance,
) => <String, dynamic>{
  'message': instance.message,
  'requiresOtp': instance.requiresOtp,
  'email': instance.email,
};

LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) => LoginRequest(
  email: json['email'] as String,
  password: json['password'] as String,
);

Map<String, dynamic> _$LoginRequestToJson(LoginRequest instance) =>
    <String, dynamic>{'email': instance.email, 'password': instance.password};

RegisterRequest _$RegisterRequestFromJson(Map<String, dynamic> json) =>
    RegisterRequest(
      email: json['email'] as String,
      password: json['password'] as String,
      fullName: json['fullName'] as String,
      phone: json['phone'] as String?,
    );

Map<String, dynamic> _$RegisterRequestToJson(RegisterRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
      'fullName': instance.fullName,
      'phone': instance.phone,
    };

VerifyLoginOtpRequest _$VerifyLoginOtpRequestFromJson(
  Map<String, dynamic> json,
) => VerifyLoginOtpRequest(
  email: json['email'] as String,
  otp: json['otp'] as String,
);

Map<String, dynamic> _$VerifyLoginOtpRequestToJson(
  VerifyLoginOtpRequest instance,
) => <String, dynamic>{'email': instance.email, 'otp': instance.otp};

UpdateTwoFactorRequest _$UpdateTwoFactorRequestFromJson(
  Map<String, dynamic> json,
) => UpdateTwoFactorRequest(
  enabled: json['enabled'] as bool,
  otp: json['otp'] as String,
);

Map<String, dynamic> _$UpdateTwoFactorRequestToJson(
  UpdateTwoFactorRequest instance,
) => <String, dynamic>{'enabled': instance.enabled, 'otp': instance.otp};

GoogleSignInRequest _$GoogleSignInRequestFromJson(Map<String, dynamic> json) =>
    GoogleSignInRequest(idToken: json['idToken'] as String);

Map<String, dynamic> _$GoogleSignInRequestToJson(
  GoogleSignInRequest instance,
) => <String, dynamic>{'idToken': instance.idToken};
