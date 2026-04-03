import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
    return CustomScrollView(
      slivers: [
        TurfImageCarousel(controller: controller),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TurfInfoSection(controller: controller),
              if (showBookingSection) ...[
                DateSelector(controller: controller),
                TimeSlotsGrid(controller: controller),
                Obx(
                  () => controller.selectedTimeSlots.isNotEmpty
                      ? BookingSummaryCard(controller: controller)
                      : const SizedBox(),
                ),
              ],
              if (controller.turfId != null)
                TurfDetailReviewsSection(
                  turfId:
                      controller.turf.value?.id ?? controller.turfId!,
                  showReviewList: showReviewList,
                ),
              if (belowReviews != null) belowReviews!,
              SizedBox(height: showBookingSection ? 100 : 24),
            ],
          ),
        ),
      ],
    );
  }
}
