import '../../core/config/env_config.dart';

/// Builds a display URL for team logo/cover paths from the API.
String? resolveTeamMediaUrl(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  final base = EnvConfig.baseApiUrl.trim();
  if (base.isEmpty) return trimmed;
  final normalizedBase = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
  final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
  return '$normalizedBase$path';
}
