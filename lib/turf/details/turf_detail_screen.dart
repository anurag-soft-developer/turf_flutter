import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'turf_detail_controller.dart';
import '../../components/shared/loading_overlay.dart';
import '../../components/turf/detail_info_section.dart';
import '../../components/turf/booking_components.dart';
import '../../core/config/constants.dart';

class TurfDetailScreen extends StatelessWidget {
  const TurfDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TurfDetailController controller = Get.find();

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      body: Stack(
        children: [
          // Main content
          Obx(
            () => controller.turf.value == null
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(AppColors.primaryColor),
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: controller.refreshData,
                    child: CustomScrollView(
                      slivers: [
                        TurfImageCarousel(controller: controller),
                        SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TurfInfoSection(controller: controller),
                              DateSelector(controller: controller),
                              TimeSlotsGrid(controller: controller),
                              Obx(
                                () => controller.selectedTimeSlots.isNotEmpty
                                    ? BookingSummaryCard(controller: controller)
                                    : const SizedBox(),
                              ),
                              const SizedBox(
                                height: 100,
                              ), // Bottom spacing for floating button
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          // Loading overlay
          Obx(
            () => controller.isLoading.value
                ? const LoadingOverlay(isLoading: true, child: SizedBox())
                : const SizedBox(),
          ),
        ],
      ),
      floatingActionButton: BookingFloatingButton(controller: controller),
    );
  }
}
