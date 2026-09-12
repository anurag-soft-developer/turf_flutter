import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/config/constants.dart';
import '../../engagement/engagement_entity.dart';
import '../../engagement/like_store.dart';

class ExploreLikeButton extends StatelessWidget {
  const ExploreLikeButton({
    super.key,
    required this.entityType,
    required this.entityId,
  });

  final EngagementEntityType entityType;
  final String entityId;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final key = LikeStore.keyFor(entityType, entityId);
      final liked = LikeStore.instance.likedKeys.contains(key);
      final count = LikeStore.instance.likeCounts[key] ?? 0;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: liked ? 'Unlike' : 'Like',
            onPressed: entityId.isEmpty
                ? null
                : () => LikeStore.instance.toggle(entityType, entityId),
            icon: Icon(
              liked ? Icons.favorite : Icons.favorite_border,
              color: liked
                  ? const Color(AppColors.primaryColor)
                  : const Color(AppColors.textSecondaryColor),
            ),
          ),
          if (count > 0)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: liked
                      ? const Color(AppColors.primaryColor)
                      : const Color(AppColors.textSecondaryColor),
                ),
              ),
            ),
        ],
      );
    });
  }
}
