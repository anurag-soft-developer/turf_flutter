import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'turf_detail_controller.dart';
import '../../components/turf/turf_detail_scroll_content.dart';
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
                    child: TurfDetailScrollContent(
                      controller: controller,
                      showBookingSection: true,
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: BookingFloatingButton(controller: controller),
    );
  }
}
