import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/config/constants.dart';
import '../../explore/model/content_post_model.dart';
import '../../explore/post_service.dart';
import '../../explore/widgets/tagged_posts_grid.dart';
import '../../turf/details/turf_detail_controller.dart';
import '../turf_review/turf_detail_reviews_section.dart';
import 'booking_components.dart';
import 'detail_info_section.dart';

/// Shared scroll body for public turf detail and owner manage flows.
class TurfDetailScrollContent extends StatelessWidget {
  final TurfDetailController controller;
  final bool showBookingSection;
  final bool showReviewList;
  final Widget? belowReviews;

  const TurfDetailScrollContent({
    super.key,
    required this.controller,
    this.showBookingSection = true,
    this.showReviewList = true,
    this.belowReviews,
  });

  @override
  Widget build(BuildContext context) {
    final turfId = controller.turf.value?.id ?? controller.turfId;
    final hasTurfId = turfId != null && turfId.isNotEmpty;

    return CustomScrollView(
      slivers: [
        TurfImageCarousel(controller: controller),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TurfInfoSection(controller: controller),
              if (showBookingSection) ...[
                TimeSlotsGrid(controller: controller),
                Obx(
                  () => controller.selectedTimeSlots.isNotEmpty
                      ? BookingSummaryCard(controller: controller)
                      : const SizedBox(),
                ),
              ],
              if (hasTurfId)
                TurfDetailReviewsSection(
                  turfId: turfId,
                  showReviewList: showReviewList,
                ),
              if (belowReviews != null) belowReviews!,
              if (hasTurfId)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
                  child: Text(
                    'Photos',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(AppColors.textColor),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (hasTurfId)
          TaggedPostsGrid(
            filter: PostFilterQuery(
              turf: turfId,
              status: PostStatus.published,
              limit: PostService.userPostsPageSize,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}
