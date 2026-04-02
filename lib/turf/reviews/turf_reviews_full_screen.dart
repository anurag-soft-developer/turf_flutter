import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../components/turf_review/turf_review_stats_summary.dart';
import '../../components/turf_review/turf_review_tile.dart';
import '../../core/config/constants.dart';
import 'turf_reviews_list_controller.dart';

class TurfReviewsFullScreen extends StatelessWidget {
  const TurfReviewsFullScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final raw = Get.arguments;
    final id = raw is Map<String, dynamic> ? raw['turfId'] as String? : null;
    if (id == null ||
        !Get.isRegistered<TurfReviewsListController>(
          tag: turfReviewsFullTag(id),
        )) {
      return Scaffold(
        backgroundColor: const Color(AppColors.backgroundColor),
        appBar: AppBar(title: const Text('Reviews')),
        body: const Center(child: Text('Unable to open reviews for this turf.')),
      );
    }

    final TurfReviewsListController controller =
        Get.find<TurfReviewsListController>(tag: turfReviewsFullTag(id));

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: const Text('All reviews'),
        backgroundColor: const Color(AppColors.primaryColor),
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.reviews.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Color(AppColors.primaryColor),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.reload,
          color: const Color(AppColors.primaryColor),
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.pixels >=
                  notification.metrics.maxScrollExtent - 160) {
                controller.loadMore();
              }
              return false;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                Obx(
                  () => TurfReviewStatsSummary(
                    stats: controller.stats.value,
                    isLoading:
                        controller.isLoading.value && controller.reviews.isEmpty,
                  ),
                ),
                const SizedBox(height: 16),
                if (controller.errorMessage.value != null &&
                    controller.reviews.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Could not load reviews',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ...controller.reviews.map(
                  (r) => TurfReviewTile(review: r),
                ),
                Obx(
                  () => controller.isLoadingMore.value
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
