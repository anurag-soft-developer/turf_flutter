import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../config/constants.dart';

enum SearchHistoryScope { explore, turfs, matchUp }

class SearchHistoryStore {
  SearchHistoryStore(this.scope);

  final SearchHistoryScope scope;

  static const int maxItems = 10;
  static const String _legacyExploreKey = 'explore_search_history';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  String get _key {
    final keys = AppConstants.storageKeys;
    return switch (scope) {
      SearchHistoryScope.explore => keys.searchHistoryExplore,
      SearchHistoryScope.turfs => keys.searchHistoryTurfs,
      SearchHistoryScope.matchUp => keys.searchHistoryMatchUp,
    };
  }

  Future<List<String>> load() async {
    final prefs = await _prefs;
    await _migrateLegacyExploreIfNeeded(prefs);

    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<String>()
          .where((s) => s.trim().isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> add(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final current = await load();
    final next = [
      trimmed,
      ...current.where((item) => item.toLowerCase() != trimmed.toLowerCase()),
    ].take(maxItems).toList();

    final prefs = await _prefs;
    await prefs.setString(_key, jsonEncode(next));
  }

  Future<void> remove(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final current = await load();
    final next = current
        .where((item) => item.toLowerCase() != trimmed.toLowerCase())
        .toList();

    final prefs = await _prefs;
    await prefs.setString(_key, jsonEncode(next));
  }

  Future<void> clear() async {
    final prefs = await _prefs;
    await prefs.remove(_key);
  }

  Future<void> _migrateLegacyExploreIfNeeded(SharedPreferences prefs) async {
    if (scope != SearchHistoryScope.explore) return;
    if (prefs.containsKey(_key)) return;

    final legacy = prefs.getString(_legacyExploreKey);
    if (legacy == null || legacy.isEmpty) return;

    await prefs.setString(_key, legacy);
    await prefs.remove(_legacyExploreKey);
  }
}
