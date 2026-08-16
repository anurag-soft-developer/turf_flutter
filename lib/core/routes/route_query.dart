import 'package:get/get.dart';

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
