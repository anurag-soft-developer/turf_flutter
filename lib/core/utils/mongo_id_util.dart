/// Parses MongoDB ObjectIds from API JSON.
///
/// Handles:
/// - plain string ids
/// - Extended JSON `{ "\$oid": "..." }`
/// - populated docs `{ "_id": "...", ... }` / `{ "id": "..." }`
String mongoIdFromJson(dynamic json) {
  if (json == null) return '';
  if (json is String) return json;
  if (json is Map) {
    final oid = json[r'$oid'] ?? json['oid'] ?? json['_id'] ?? json['id'];
    if (oid != null) {
      if (oid is String) return oid;
      // Nested map (e.g. populated `_id: { $oid: ... }`).
      return mongoIdFromJson(oid);
    }
  }
  return json.toString();
}

/// Like [mongoIdFromJson], but returns `null` for missing/empty values.
String? mongoIdFromJsonNullable(dynamic json) {
  if (json == null) return null;
  final id = mongoIdFromJson(json);
  return id.isEmpty ? null : id;
}
