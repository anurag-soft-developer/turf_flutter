import 'package:json_annotation/json_annotation.dart';

import '../../turf/model/turf_model.dart';

/// Handles turf JSON fields that may be an id ([String]) or a populated [TurfModel].
class TurfConverter implements JsonConverter<dynamic, dynamic> {
  const TurfConverter();

  @override
  dynamic fromJson(dynamic json) {
    if (json == null) {
      return null;
    }
    if (json is String) {
      return json;
    }
    if (json is Map<String, dynamic>) {
      return TurfModel.fromJson(json);
    }
    throw FormatException('Invalid type for turf field: ${json.runtimeType}');
  }

  @override
  dynamic toJson(dynamic turf) {
    if (turf == null) {
      return null;
    }
    if (turf is String) {
      return turf;
    }
    if (turf is TurfModel) {
      return turf.toJson();
    }
    return turf;
  }
}
