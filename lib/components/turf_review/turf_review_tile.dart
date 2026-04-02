import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/utils/date_util.dart';
import 'package:get/get.dart';

import '../../core/auth/auth_state_controller.dart';
import '../../core/config/constants.dart';
import '../../turf/model/turf_review_model.dart';
import '../../turf/reviews/turf_review_service.dart';
import '../../turf/reviews/turf_reviews_list_controller.dart';

class TurfReviewTile extends StatelessWidget {
  const TurfReviewTile({super.key, required this.review});

  final TurfReviewModel review;

  bool get _isCurrentUserOwner {
    final userId = Get.find<AuthStateController>().user?.id;
    final authorId = review.reviewedByHelper.getId();
    if (userId == null || authorId == null || review.id == null) {
      return false;
    }
    return userId == authorId;
  }

  Future<void> _confirmAndDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete review?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(AppColors.errorColor),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || review.id == null) return;

    final ok = await TurfReviewService().deleteReview(review.id!);
    if (!context.mounted) return;
    if (ok) {
      final turfId = review.turfHelper.getId();
      if (turfId != null) reloadTurfReviewListsIfRegistered(turfId);
      Get.snackbar('Removed', 'Your review was deleted');
    } else {
      Get.snackbar('Error', 'Could not delete review');
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = review.reviewedByHelper.getDisplayName();
    final profilePicture = review.reviewedByHelper.getAvatar();
    final title = review.title;
    final comment = review.comment;
    final date = review.createdAt;

    return Card(
      color: Color(AppColors.surfaceColor),
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(
                    AppColors.primaryColor,
                  ).withValues(alpha: 0.15),
                  child: ClipOval(
                    child: profilePicture != null
                        ? Image.network(
                            profilePicture,
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                color: Color(AppColors.primaryColor),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        : Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: Color(AppColors.primaryColor),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(AppColors.textColor),
                        ),
                      ),
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (i) => Icon(
                              i < review.rating
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 16,
                              color: const Color(0xFFFBBF24),
                            ),
                          ),
                          if (review.isVerifiedBooking) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  AppColors.successColor,
                                ).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Verified',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(AppColors.successColor),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (_isCurrentUserOwner)
                  IconButton(
                    tooltip: 'Delete review',
                    icon: const Icon(Icons.delete_outline),
                    color: const Color(AppColors.errorColor),
                    onPressed: () => _confirmAndDelete(context),
                  ),
              ],
            ),
            if (title != null && title.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Color(AppColors.textColor),
                ),
              ),
            ],
            if (comment != null && comment.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                comment,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(AppColors.textSecondaryColor),
                  height: 1.35,
                ),
              ),
            ],
            if (date != null) ...[
              const SizedBox(height: 8),
              Text(
                timeAgo(date),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(AppColors.textSecondaryColor),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
