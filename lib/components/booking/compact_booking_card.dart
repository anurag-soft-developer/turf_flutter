import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/config/constants.dart';
import '../../turf_booking/model/turf_booking_model.dart';

/// Compact horizontal booking tile for dashboard carousel.
class CompactBookingCard extends StatelessWidget {
  const CompactBookingCard({super.key, required this.booking});

  final TurfBookingModel booking;

  bool get _hasTicket =>
      booking.status == TurfBookingStatus.confirmed ||
      booking.status == TurfBookingStatus.completed;

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        booking.startDateTime?.toString().split(' ').first ?? '';

    return Material(
      color: const Color(AppColors.surfaceColor),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _openTicketIfAvailable,
        child: Container(
          width: 260,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(AppColors.dividerColor).withValues(alpha: 0.65),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(AppColors.primaryColor).withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.grass_rounded,
                  size: 20,
                  color: Color(AppColors.primaryColor),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      booking.turfDisplayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(AppColors.textColor),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (dateLabel.isNotEmpty) dateLabel,
                        booking.bookingTimeDisplay,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(AppColors.textSecondaryColor),
                      ),
                    ),
                  ],
                ),
              ),
              if (_hasTicket)
                const Icon(
                  Icons.confirmation_number_outlined,
                  size: 20,
                  color: Color(AppColors.primaryColor),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openTicketIfAvailable() {
    if (!_hasTicket || (booking.id ?? '').isEmpty) return;
    Get.toNamed(
      AppConstants.routes.bookingTicket,
      arguments: {
        'bookingId': booking.id,
        'booking': booking,
      },
    );
  }
}
