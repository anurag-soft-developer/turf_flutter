import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/turf_booking_controller.dart';
import '../../models/turf_booking_model.dart';
import '../../components/shared/app_drawer.dart';
import '../../components/shared/loading_overlay.dart';
import '../../components/booking/booking_card.dart';
import '../../config/constants.dart';

class OwnerBookingsScreen extends StatelessWidget {
  const OwnerBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookingController = TurfBookingController.instance;

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: const Text(
          'Turf Bookings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(AppColors.primaryColor),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Filter and Stats Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Quick Stats
                Obx(
                  () => Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Total Bookings',
                          value: bookingController.turfOwnerBookings.length
                              .toString(),
                          icon: Icons.book_online,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Pending',
                          value: bookingController.turfOwnerBookings
                              .where((b) => b.isPending)
                              .length
                              .toString(),
                          icon: Icons.pending,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Confirmed',
                          value: bookingController.turfOwnerBookings
                              .where((b) => b.isConfirmed)
                              .length
                              .toString(),
                          icon: Icons.check_circle,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Filter Row
                Container(
                  width: double.infinity,
                  child: Column(
                    children: [
                      DropdownButtonFormField<TurfBookingStatus?>(
                        value:
                            null, // TODO: Add filter state for turf owner bookings
                        decoration: const InputDecoration(
                          labelText: 'Filter by Status',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All'),
                          ),
                          ...TurfBookingStatus.values.map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(status.name.toUpperCase()),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          // TODO: Implement filter for turf owner bookings
                        },
                      ),

                      const SizedBox(height: 12),

                      Container(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            bookingController.loadTurfOwnerBookings(
                              refresh: true,
                            );
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              AppColors.primaryColor,
                            ),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bookings List
          Expanded(
            child: Stack(
              children: [
                Obx(() {
                  if (bookingController.turfOwnerBookings.isEmpty &&
                      !bookingController.isLoading.value) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No Bookings Found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No customers have booked your turfs yet.\nMake sure your turfs are properly listed.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () =>
                        bookingController.loadTurfOwnerBookings(refresh: true),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: bookingController.turfOwnerBookings.length,
                      itemBuilder: (context, index) {
                        final booking =
                            bookingController.turfOwnerBookings[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: BookingCard(
                            booking: booking,
                            isOwnerView: true,
                            onConfirm: (bookingId) {
                              _showConfirmDialog(context, bookingId);
                            },
                            onCancel: (bookingId) {
                              _showCancelDialog(context, bookingId);
                            },
                            onComplete: (bookingId) {
                              _showCompleteDialog(context, bookingId);
                            },
                          ),
                        );
                      },
                    ),
                  );
                }),

                // Loading overlay for initial load
                Obx(
                  () => LoadingOverlay(
                    isLoading:
                        bookingController.isLoading.value &&
                        bookingController.turfOwnerBookings.isEmpty,
                    child: const SizedBox(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showConfirmDialog(BuildContext context, String bookingId) {
    Get.dialog(
      AlertDialog(
        title: const Text('Confirm Booking'),
        content: const Text('Are you sure you want to confirm this booking?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('No')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              TurfBookingController.instance.confirmBooking(bookingId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Confirm'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, String bookingId) {
    final reasonController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Cancel Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to cancel this booking?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Cancellation Reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('No')),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                Get.back();
                TurfBookingController.instance.cancelBooking(
                  bookingId,
                  reasonController.text.trim(),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _showCompleteDialog(BuildContext context, String bookingId) {
    Get.dialog(
      AlertDialog(
        title: const Text('Complete Booking'),
        content: const Text(
          'Are you sure you want to mark this booking as completed?',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('No')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              TurfBookingController.instance.completeBooking(bookingId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(AppColors.primaryColor),
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Complete'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
