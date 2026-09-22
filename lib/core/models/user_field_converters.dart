import 'package:json_annotation/json_annotation.dart';
import '../utils/mongo_id_util.dart';
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

    // Map: populated User, or bare ObjectId / Extended JSON.
    if (json is Map) {
      final map = Map<String, dynamic>.from(json);
      final looksLikeUser = map.containsKey('email') ||
          map.containsKey('fullName') ||
          map.containsKey('firstName') ||
          map.containsKey('avatar') ||
          map.containsKey('phoneNumber');
      if (looksLikeUser) {
        return UserModel.fromJson(map);
      }
      final id = mongoIdFromJsonNullable(map);
      if (id != null) return id;
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
