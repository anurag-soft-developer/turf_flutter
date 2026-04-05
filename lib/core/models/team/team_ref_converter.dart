import 'package:json_annotation/json_annotation.dart';

import 'team_member_field_instance.dart';

/// Handles `team` as an id ([String]) or populated [TeamMemberFieldInstance].
class TeamRefConverter implements JsonConverter<dynamic, dynamic> {
  const TeamRefConverter();

  @override
  dynamic fromJson(dynamic json) {
    if (json == null) return null;
    if (json is String) return json;
    if (json is Map<String, dynamic>) {
      return TeamMemberFieldInstance.fromJson(json);
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
