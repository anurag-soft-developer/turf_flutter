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
      final liked = LikeStore.instance.likedKeys.contains(
        LikeStore.keyFor(entityType, entityId),
      );
      return IconButton(
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
      );
    });
  }
}
