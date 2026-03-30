import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/constants.dart';
import '../../controllers/turf_booking_controller.dart';
import '../../models/turf_booking_model.dart';

class BookingFilterBottomSheet extends StatelessWidget {
  final TurfBookingController controller;

  const BookingFilterBottomSheet({super.key, required this.controller});

  static void show(BuildContext context, TurfBookingController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => BookingFilterBottomSheet(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      maxChildSize: 0.6,
      minChildSize: 0.3,
      expand: false,
      builder: (context, scrollController) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [_buildStatusFilter(), const SizedBox(height: 20)],
                ),
              ),
            ),
            _buildApplyButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Filter',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                controller.clearFilters();
                Get.back();
              },
              child: const Text('Clear All'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Booking Status',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Obx(
          () => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TurfBookingStatus.values
                .map(
                  (status) => FilterChip(
                    label: Text(status.name.toUpperCase()),
                    selected: controller.selectedStatusFilters.contains(status),
                    onSelected: (_) => controller.toggleStatusFilter(status),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildApplyButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Get.back();
          // The filter is already applied when selected, so just close
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(AppColors.primaryColor),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Apply Filters',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
