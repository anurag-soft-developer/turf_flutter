import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../components/turf/booking_components.dart';
import '../../core/config/constants.dart';
import 'turf_detail_controller.dart';

class TurfSlotSelectionScreen extends StatelessWidget {
  const TurfSlotSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TurfDetailController>();

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(title: const Text('Select slots')),
      body: ListView(
        children: [
          TimeSlotsGrid(controller: controller),
          Obx(
            () => controller.selectedTimeSlots.isNotEmpty
                ? BookingSummaryCard(controller: controller)
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 100),
        ],
      ),
      floatingActionButton: BookingFloatingButton(controller: controller),
    );
  }
}
