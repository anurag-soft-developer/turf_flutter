import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Disk cache for remote images. RAM cache is left to Flutter and is released
/// when the app process exits.
class AppImageCache {
  static const key = 'appImageCache';

  static final CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 200,
    ),
  );

  static Future<void> clear() => instance.emptyCache();
}
