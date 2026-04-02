import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/config/constants.dart';
import '../../turf/reviews/turf_reviews_list_controller.dart';
import 'turf_review_stats_summary.dart';
import 'turf_review_tile.dart';
import 'turf_review_write_form.dart';

void openTurfReviewWriteSheet(BuildContext context, String turfId) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => TurfReviewWriteForm(turfId: turfId),
  );
}

class TurfDetailReviewsSection extends StatelessWidget {
  const TurfDetailReviewsSection({super.key, required this.turfId});

  final String turfId;

  @override
  Widget build(BuildContext context) {
    final tag = turfReviewsPreviewTag(turfId);
    if (!Get.isRegistered<TurfReviewsListController>(tag: tag)) {
      return const SizedBox.shrink();
    }

    final TurfReviewsListController controller =
        Get.find<TurfReviewsListController>(tag: tag);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Reviews',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(AppColors.textColor),
                ),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(AppColors.primaryColor),
                ),
                onPressed: () => openTurfReviewWriteSheet(context, turfId),
                icon: const Icon(Icons.edit_outlined, size: 15),
                label: const Text('Write'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Obx(
            () => TurfReviewStatsSummary(
              stats: controller.stats.value,
              isLoading: controller.isLoading.value,
            ),
          ),
          Obx(() {
            final loading = controller.isLoading.value;
            final err = controller.errorMessage.value;
            final list = controller.reviews;

            if (err != null && list.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Could not load reviews',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              );
            }
            if (list.isEmpty && !loading) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No reviews yet. Be the first to share your experience.',
                  style: TextStyle(color: Color(AppColors.textSecondaryColor)),
                ),
              );
            }
            if (list.isEmpty) {
              return const SizedBox.shrink();
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                const SizedBox(height: 10),
                ...list.map((r) => TurfReviewTile(review: r)),
              ],
            );
          }),
          const SizedBox(height: 8),
          Obx(() {
            final list = controller.reviews;
            if (list.isEmpty) return const SizedBox.shrink();
            final total = controller.stats.value?.totalReviews ?? 0;
            final showViewAll =
                total > list.length || (total == 0 && list.length >= 3);
            if (!showViewAll) return const SizedBox.shrink();
            return Center(
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(AppColors.primaryColor),
                ),
                onPressed: () => Get.toNamed(
                  AppConstants.routes.turfReviews,
                  arguments: {'turfId': turfId},
                ),
                child: const Text(
                  'View all reviews',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
