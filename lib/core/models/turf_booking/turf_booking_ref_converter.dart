import 'package:json_annotation/json_annotation.dart';

import '../../../turf_booking/model/turf_booking_model.dart';

/// Lean id ([String]) or populated [TurfBookingModel] for `turfBookingId` refs.
class TurfBookingRefConverter implements JsonConverter<dynamic, dynamic> {
  const TurfBookingRefConverter();

  @override
  dynamic fromJson(dynamic json) {
    if (json == null) return null;
    if (json is String) return json;
    if (json is Map) {
      return TurfBookingModel.fromJson(Map<String, dynamic>.from(json));
    }
    throw FormatException(
      'Invalid type for turf booking ref: ${json.runtimeType}',
    );
  }

  @override
  dynamic toJson(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is TurfBookingModel) return value.toJson();
    return value;
  }
}
