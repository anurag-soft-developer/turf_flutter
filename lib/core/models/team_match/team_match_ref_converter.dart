import 'package:json_annotation/json_annotation.dart';

import '../../../match_up/model/team_match_model.dart';

/// Lean id ([String]) or populated [TeamMatchModel] for `teamMatchId` on scoring docs.
class TeamMatchRefConverter implements JsonConverter<dynamic, dynamic> {
  const TeamMatchRefConverter();

  @override
  dynamic fromJson(dynamic json) {
    if (json == null) return null;
    if (json is String) return json;
    if (json is Map<String, dynamic>) {
      return TeamMatchModel.fromJson(json);
    }
    if (json is Map) {
      return TeamMatchModel.fromJson(Map<String, dynamic>.from(json));
    }
    throw FormatException(
      'Invalid type for team match ref: ${json.runtimeType}',
    );
  }

  @override
  dynamic toJson(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is TeamMatchModel) return value.toJson();
    return value;
  }
}
