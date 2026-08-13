import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/constants.dart';

class ExploreSearchHistoryStore {
  ExploreSearchHistoryStore._();
  static final ExploreSearchHistoryStore instance = ExploreSearchHistoryStore._();

  static const int maxItems = 10;

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<List<String>> load() async {
    final prefs = await _prefs;
    final raw = prefs.getString(AppConstants.storageKeys.exploreSearchHistory);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded.whereType<String>().where((s) => s.trim().isNotEmpty).toList();
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
    await prefs.setString(
      AppConstants.storageKeys.exploreSearchHistory,
      jsonEncode(next),
    );
  }

  Future<void> remove(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final current = await load();
    final next = current
        .where((item) => item.toLowerCase() != trimmed.toLowerCase())
        .toList();

    final prefs = await _prefs;
    await prefs.setString(
      AppConstants.storageKeys.exploreSearchHistory,
      jsonEncode(next),
    );
  }

  Future<void> clear() async {
    final prefs = await _prefs;
    await prefs.remove(AppConstants.storageKeys.exploreSearchHistory);
  }
}
