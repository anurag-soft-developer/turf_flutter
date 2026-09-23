import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/config/constants.dart';
import '../../turf_booking/model/turf_booking_model.dart';
import '../../turf_booking/turf_booking_controller.dart';
import '../booking/compact_booking_card.dart';

class DashboardUpcomingBookingsSection extends StatelessWidget {
  const DashboardUpcomingBookingsSection({
    super.key,
    required this.bookings,
  });

  final List<TurfBookingModel> bookings;

  void _openAllBookings() {
    if (Get.isRegistered<TurfBookingController>()) {
      Get.find<TurfBookingController>().switchTab(BookingsTab.upcoming);
    }
    Get.toNamed(AppConstants.routes.myBookings);
  }

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Upcoming bookings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(AppColors.textColor),
                  ),
                ),
              ),
              TextButton(
                onPressed: _openAllBookings,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(AppColors.primaryColor),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'View all',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 72,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            itemCount: bookings.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              return CompactBookingCard(booking: bookings[index]);
            },
          ),
        ),
      ],
    );
  }
}
