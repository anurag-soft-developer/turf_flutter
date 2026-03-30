import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/config/constants.dart';
import '../../turf/details/turf_detail_controller.dart';

class DateSelector extends StatelessWidget {
  final TurfDetailController controller;

  const DateSelector({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Date',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(AppColors.textColor),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: controller.availableDates.length,
              itemBuilder: (context, index) {
                final date = controller.availableDates[index];

                return Obx(() {
                  final isSelected =
                      date.day == controller.selectedDate.value.day &&
                      date.month == controller.selectedDate.value.month &&
                      date.year == controller.selectedDate.value.year;

                  return DateCard(
                    date: date,
                    isSelected: isSelected,
                    onTap: () => controller.changeSelectedDate(date),
                  );
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

class DateCard extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final VoidCallback onTap;

  const DateCard({
    super.key,
    required this.date,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(AppColors.primaryColor)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(AppColors.primaryColor)
                : Colors.grey[300]!,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _getDayName(date.weekday),
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date.day.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
            Text(
              _getMonthName(date.month),
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'Jan';
      case 2:
        return 'Feb';
      case 3:
        return 'Mar';
      case 4:
        return 'Apr';
      case 5:
        return 'May';
      case 6:
        return 'Jun';
      case 7:
        return 'Jul';
      case 8:
        return 'Aug';
      case 9:
        return 'Sep';
      case 10:
        return 'Oct';
      case 11:
        return 'Nov';
      case 12:
        return 'Dec';
      default:
        return '';
    }
  }
}

class TimeSlotsGrid extends StatelessWidget {
  final TurfDetailController controller;

  const TimeSlotsGrid({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available Time Slots',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(AppColors.textColor),
            ),
          ),
          const SizedBox(height: 12),
          Obx(() {
            if (controller.timeSlots.isEmpty) {
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
              itemCount: controller.timeSlots.length,
              itemBuilder: (context, index) {
                final slot = controller.timeSlots[index];

                return Obx(() {
                  final isSelected = controller.selectedTimeSlots.contains(
                    slot,
                  );

                  return TimeSlotCard(
                    slot: slot,
                    isSelected: isSelected,
                    onTap: () => controller.toggleTimeSlot(slot),
                  );
                });
              },
            );
          }),
        ],
      ),
    );
  }
}

class TimeSlotCard extends StatelessWidget {
  final TimeSlot slot;
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: !slot.isAvailable
              ? Colors.grey[100]
              : isSelected
              ? const Color(AppColors.primaryColor)
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: !slot.isAvailable
                ? Colors.grey[300]!
                : isSelected
                ? const Color(AppColors.primaryColor)
                : Colors.grey[300]!,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              slot.timeRange,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: !slot.isAvailable
                    ? Colors.grey[600]
                    : isSelected
                    ? Colors.white
                    : const Color(AppColors.textColor),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '₹${slot.price.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 13,
                color: !slot.isAvailable
                    ? Colors.grey[600]
                    : isSelected
                    ? Colors.white
                    : const Color(AppColors.primaryColor),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!slot.isAvailable)
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

  const BookingFloatingButton({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => controller.selectedTimeSlots.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: controller.isBookingLoading.value
                  ? null
                  : controller.bookTimeSlots,
              backgroundColor: const Color(AppColors.primaryColor),
              foregroundColor: Colors.white,
              icon: controller.isBookingLoading.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.book_online),
              label: Text(
                controller.isBookingLoading.value ? 'Booking...' : 'Book Now',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
