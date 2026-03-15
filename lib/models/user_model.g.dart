// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

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

GoogleSignInRequest _$GoogleSignInRequestFromJson(Map<String, dynamic> json) =>
    GoogleSignInRequest(idToken: json['idToken'] as String);

Map<String, dynamic> _$GoogleSignInRequestToJson(
  GoogleSignInRequest instance,
) => <String, dynamic>{'idToken': instance.idToken};
