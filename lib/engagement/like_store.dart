import 'package:get/get.dart';

import 'engagement_entity.dart';
import 'engagement_service.dart';

/// Session-local like state. Explore payloads do not include `likedByMe`.
class LikeStore {
  static final LikeStore instance = LikeStore._();
  LikeStore._();

  final RxSet<String> likedKeys = <String>{}.obs;
  final Set<String> _inFlight = {};

  static String keyFor(EngagementEntityType type, String entityId) =>
      '${type.apiValue}:$entityId';

  bool isLiked(EngagementEntityType type, String entityId) =>
      likedKeys.contains(keyFor(type, entityId));

  Future<void> toggle(EngagementEntityType type, String entityId) async {
    if (entityId.isEmpty) return;
    final key = keyFor(type, entityId);
    if (_inFlight.contains(key)) return;
    _inFlight.add(key);

    final wasLiked = likedKeys.contains(key);
    if (wasLiked) {
      likedKeys.remove(key);
    } else {
      likedKeys.add(key);
    }

    try {
      final ok = wasLiked
          ? await EngagementService().unlike(
              entityType: type,
              entityId: entityId,
            )
          : await EngagementService().like(
              entityType: type,
              entityId: entityId,
            );
      if (!ok) {
        if (wasLiked) {
          likedKeys.add(key);
        } else {
          likedKeys.remove(key);
        }
      }
    } finally {
      _inFlight.remove(key);
    }
  }
}
