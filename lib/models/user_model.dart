import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
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
class GoogleSignInRequest {
  @JsonKey(name: 'idToken')
  final String idToken;

  GoogleSignInRequest({required this.idToken});

  factory GoogleSignInRequest.fromJson(Map<String, dynamic> json) =>
      _$GoogleSignInRequestFromJson(json);

  Map<String, dynamic> toJson() => _$GoogleSignInRequestToJson(this);
}
