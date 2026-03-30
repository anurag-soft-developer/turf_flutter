import 'package:json_annotation/json_annotation.dart';
import 'user/user_model.dart';

// Custom converter for user fields to handle both ID and populated data
class UserConverter implements JsonConverter<dynamic, dynamic> {
  const UserConverter();

  @override
  dynamic fromJson(dynamic json) {
    if (json == null) {
      return null;
    }

    // If it's a String, it's just the user ID
    if (json is String) {
      return json;
    }

    // If it's a Map, it's a populated user object
    if (json is Map<String, dynamic>) {
      return UserModel.fromJson(json);
    }

    throw FormatException('Invalid type for user field: ${json.runtimeType}');
  }

  @override
  dynamic toJson(dynamic user) {
    if (user == null) return null;
    if (user is String) return user;
    if (user is UserModel) return user.toJson();
    return user;
  }
}
