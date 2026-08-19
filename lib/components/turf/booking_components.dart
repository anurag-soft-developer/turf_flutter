import 'package:flutter/material.dart';
import 'package:flutter_application_1/turf_booking/model/turf_booking_model.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/config/constants.dart';
import '../../core/query/query_keys.dart';
import '../../core/query/query_retry.dart';
import '../../turf/details/turf_detail_controller.dart';
import '../../turf_booking/turf_booking_service.dart';

class TimeSlotsGrid extends StatelessWidget {
  final TurfDetailController controller;

  const TimeSlotsGrid({super.key, required this.controller});

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.selectedDate.value,
      firstDate: controller.minSelectableDate,
      lastDate: controller.maxSelectableDate,
    );
    if (picked != null) {
      controller.changeSelectedDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Time Slots',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(AppColors.textColor),
                  ),
                ),
              ),
              Obx(
                () => BookingDatePickerChip(
                  date: controller.selectedDate.value,
                  onTap: () => _pickDate(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() {
            final turfId = controller.turfId;
            final dateKey = controller.selectedDateKey;
            if (turfId == null || turfId.isEmpty) {
              return const SizedBox.shrink();
            }
            return _TimeSlotsQueryBody(
              key: ValueKey('$turfId|$dateKey'),
              controller: controller,
              turfId: turfId,
              dateKey: dateKey,
              date: controller.selectedDate.value,
            );
          }),
        ],
      ),
    );
  }
}

class _TimeSlotsQueryBody extends HookWidget {
  const _TimeSlotsQueryBody({
    super.key,
    required this.controller,
    required this.turfId,
    required this.dateKey,
    required this.date,
  });

  final TurfDetailController controller;
  final String turfId;
  final String dateKey;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final slotsQuery = useQuery<List<TurfTimeSlotListing>, Object>(
      QueryKeys.turfSlots(turfId, dateKey),
      (_) => TurfBookingService().getTimeSlotsForDate(turfId, date),
      retry: noRetry,
    );

    if (slotsQuery.isLoading ||
        (slotsQuery.isFetching && slotsQuery.data == null)) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (slotsQuery.isError && slotsQuery.data == null) {
      return Center(
        child: TextButton(
          onPressed: () => slotsQuery.refetch(),
          child: const Text('Retry loading slots'),
        ),
      );
    }

    final timeSlots = slotsQuery.data ?? const <TurfTimeSlotListing>[];

    if (timeSlots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'No time slots available for this date',
            style: TextStyle(
              color: Color(AppColors.textSecondaryColor),
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: timeSlots.length,
      itemBuilder: (context, index) {
        final slot = timeSlots[index];

        return Obx(() {
          final isSelected = controller.selectedTimeSlots.contains(slot);

          return TimeSlotCard(
            slot: slot,
            isSelected: isSelected,
            onTap: () => controller.toggleTimeSlot(slot),
          );
        });
      },
    );
  }
}

class BookingDatePickerChip extends StatelessWidget {
  const BookingDatePickerChip({
    super.key,
    required this.date,
    required this.onTap,
  });

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(AppColors.primaryColor).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(
                AppColors.primaryColor,
              ).withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 15,
                color: Color(AppColors.primaryColor),
              ),
              const SizedBox(width: 6),
              Text(
                DateFormat('EEE, d MMM').format(date),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(AppColors.primaryColor),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: Color(AppColors.primaryColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TimeSlotCard extends StatelessWidget {
  final TurfTimeSlotListing slot;
  final bool isSelected;
  final VoidCallback onTap;

  const TimeSlotCard({
    super.key,
    required this.slot,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isBooked = slot.isBooked;
    final isHeld = slot.isHeld && !isBooked;
    final isDisabled = !slot.isAvailable || isBooked || isHeld;

    Color? backgroundColor;
    Color borderColor;
    Color primaryTextColor;
    Color priceColor;

    if (isBooked) {
      backgroundColor = Colors.red[50];
      borderColor = Colors.red[200]!;
      primaryTextColor = Colors.red[700]!;
      priceColor = Colors.red[700]!;
    } else if (isHeld) {
      backgroundColor = Colors.orange[50];
      borderColor = Colors.orange[200]!;
      primaryTextColor = Colors.orange[800]!;
      priceColor = Colors.orange[800]!;
    } else if (!slot.isAvailable) {
      backgroundColor = Colors.grey[100];
      borderColor = Colors.grey[300]!;
      primaryTextColor = Colors.grey[600]!;
      priceColor = Colors.grey[600]!;
    } else if (isSelected) {
      backgroundColor = const Color(AppColors.primaryColor);
      borderColor = const Color(AppColors.primaryColor);
      primaryTextColor = Colors.white;
      priceColor = Colors.white;
    } else {
      backgroundColor = Colors.white;
      borderColor = Colors.grey[300]!;
      primaryTextColor = const Color(AppColors.textColor);
      priceColor = const Color(AppColors.primaryColor);
    }

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              slot.timeDisplay,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '₹${slot.price.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 13,
                color: priceColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isBooked)
              Text(
                'Booked',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.red[700],
                  fontWeight: FontWeight.w600,
                ),
              )
            else if (isHeld)
              Text(
                'On hold',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.orange[800],
                  fontWeight: FontWeight.w600,
                ),
              )
            else if (!slot.isAvailable)
              Text(
                'Unavailable',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class BookingSummaryCard extends StatelessWidget {
  final TurfDetailController controller;

  const BookingSummaryCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Booking Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(AppColors.textColor),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Date:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(AppColors.textColor),
                ),
              ),
              Text(
                '${controller.selectedDate.value.day}/${controller.selectedDate.value.month}/${controller.selectedDate.value.year}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(AppColors.textColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Time:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(AppColors.textColor),
                ),
              ),
              Text(
                controller.bookingSummary,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(AppColors.textColor),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(AppColors.primaryColor),
                ),
              ),
              Text(
                '₹${controller.totalPrice.value.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(AppColors.primaryColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BookingFloatingButton extends StatelessWidget {
  final TurfDetailController controller;
  final bool opensSlotPicker;

  const BookingFloatingButton({
    super.key,
    required this.controller,
    this.opensSlotPicker = false,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoading = controller.isBookingLoading.value;
      return FloatingActionButton.extended(
        onPressed: isLoading ? null : _onPressed,
        backgroundColor: const Color(AppColors.primaryColor),
        foregroundColor: Colors.white,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(opensSlotPicker ? Icons.event_available : Icons.book_online),
        label: Text(
          isLoading ? 'Booking...' : 'Book Now',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    });
  }

  void _onPressed() {
    if (opensSlotPicker) {
      Get.toNamed(AppConstants.routes.turfSlotSelection);
      return;
    }
    controller.bookTimeSlots();
  }
}
