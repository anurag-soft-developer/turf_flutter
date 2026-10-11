import 'package:get/get.dart';

import '../../team/model/team_model.dart';

/// Path (or query) values from the current GetX route (`:id`).
String? routeParam(String key) {
  final value = Get.parameters[key]?.trim();
  if (value == null || value.isEmpty) return null;
  return value;
}

bool? routeParamBool(String key) {
  final value = routeParam(key);
  if (value == null) return null;
  if (value == 'true' || value == '1') return true;
  if (value == 'false' || value == '0') return false;
  return null;
}

/// Optional sport from route parameters or [Get.arguments] map.
TeamSportType? optionalTeamSportFromRoute({String key = 'sport'}) {
  String? raw;
  final args = Get.arguments;
  if (args is Map) {
    raw = args[key]?.toString().trim();
  }
  raw ??= routeParam(key);
  if (raw == null || raw.isEmpty) return null;
  for (final candidate in TeamSportType.values) {
    if (candidate.name == raw) return candidate;
  }
  return null;
}
