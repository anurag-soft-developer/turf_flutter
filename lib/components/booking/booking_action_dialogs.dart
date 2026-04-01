import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/config/constants.dart';
import '../../turf_booking/turf_booking_controller.dart';
import '../shared/custom_confirm_dialog.dart';

/// Dialog flows for booking actions (cancel / confirm / complete).
/// Keeps [TurfBookingController] calls and copy in one place.
class BookingActionDialogs {
  BookingActionDialogs._();

  static void showCancelBooking(String bookingId) {
    final reasonController = TextEditingController();

    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Cancel Booking',
          style: TextStyle(color: Color(AppColors.textColor)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Are you sure you want to cancel this booking?',
              style: TextStyle(color: Color(AppColors.textSecondaryColor)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              style: const TextStyle(color: Color(AppColors.textColor)),
              decoration: const InputDecoration(
                labelText: 'Reason (Optional)',
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Color(AppColors.textSecondaryColor),
                  ),
                ),
                labelStyle: TextStyle(
                  color: Color(AppColors.textSecondaryColor),
                ),
                fillColor: Colors.white,
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  child: const Text('No'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final reason = reasonController.text.trim();
                    Get.back();
                    TurfBookingController.instance.cancelBooking(
                      bookingId,
                      reason.isEmpty ? null : reason,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Yes, Cancel'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static void showConfirmBooking(String bookingId) {
    Get.dialog(
      ConfirmDialog(
        title: 'Confirm Booking',
        content: 'Are you sure you want to confirm this booking?',
        onConfirm: () {
          TurfBookingController.instance.confirmBooking(bookingId);
        },
      ),
    );
  }

  static void showCompleteBooking(String bookingId) {
    Get.dialog(
      ConfirmDialog(
        title: 'Complete Booking',
        content:
            'Are you sure you want to mark this booking as completed?',
        onConfirm: () {
          TurfBookingController.instance.completeBooking(bookingId);
        },
      ),
    );
  }
}
