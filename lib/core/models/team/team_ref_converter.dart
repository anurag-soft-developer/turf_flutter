import 'package:json_annotation/json_annotation.dart';

import 'team_member_field_instance.dart';

/// Handles `team` as an id ([String]) or populated [TeamMemberFieldInstance].
class TeamRefConverter implements JsonConverter<dynamic, dynamic> {
  const TeamRefConverter();

  @override
  dynamic fromJson(dynamic json) {
    if (json == null) return null;
    if (json is String) return json;
    if (json is Map) {
      final map = Map<String, dynamic>.from(json);
      final sportType = map['sportType'];
      final name = map['name']?.toString();
      if (sportType != null && name != null && name.isNotEmpty) {
        return TeamMemberFieldInstance.fromJson(map);
      }
      final id = map['_id'] ?? map['id'];
      if (id != null) return id.toString();
    }
    throw FormatException('Invalid type for team ref: ${json.runtimeType}');
  }

  @override
  dynamic toJson(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is TeamMemberFieldInstance) return value.toJson();
    return value;
  }
}
