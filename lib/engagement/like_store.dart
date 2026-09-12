import 'package:get/get.dart';

import 'engagement_entity.dart';
import 'engagement_service.dart';

/// Session like state (heart + count). Seeded from explore `likedByMe` / `likeCount`.
class LikeStore {
  static final LikeStore instance = LikeStore._();
  LikeStore._();

  final RxSet<String> likedKeys = <String>{}.obs;
  final RxMap<String, int> likeCounts = <String, int>{}.obs;
  final Set<String> _inFlight = {};
  final Set<String> _touched = {};

  static String keyFor(EngagementEntityType type, String entityId) =>
      '${type.apiValue}:$entityId';

  bool isLiked(EngagementEntityType type, String entityId) =>
      likedKeys.contains(keyFor(type, entityId));

  int likeCount(EngagementEntityType type, String entityId) =>
      likeCounts[keyFor(type, entityId)] ?? 0;

  /// Apply server values unless the user already toggled this entity in-session.
  void seed(
    EngagementEntityType type,
    String entityId, {
    required bool likedByMe,
    required int likeCount,
  }) {
    if (entityId.isEmpty) return;
    final key = keyFor(type, entityId);
    if (_touched.contains(key)) return;

    final nextCount = likeCount < 0 ? 0 : likeCount;
    final currentlyLiked = likedKeys.contains(key);
    if (likedByMe != currentlyLiked) {
      if (likedByMe) {
        likedKeys.add(key);
      } else {
        likedKeys.remove(key);
      }
    }
    if (likeCounts[key] != nextCount) {
      likeCounts[key] = nextCount;
    }
  }

  Future<void> toggle(EngagementEntityType type, String entityId) async {
    if (entityId.isEmpty) return;
    final key = keyFor(type, entityId);
    if (_inFlight.contains(key)) return;
    _inFlight.add(key);
    _touched.add(key);

    final wasLiked = likedKeys.contains(key);
    final previousCount = likeCounts[key] ?? 0;
    if (wasLiked) {
      likedKeys.remove(key);
      likeCounts[key] = (previousCount - 1).clamp(0, 1 << 30);
    } else {
      likedKeys.add(key);
      likeCounts[key] = previousCount + 1;
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
        likeCounts[key] = previousCount;
      }
    } finally {
      _inFlight.remove(key);
    }
  }
}
