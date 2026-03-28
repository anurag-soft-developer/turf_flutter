import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/turf_booking_controller.dart';
import '../../models/turf_booking_model.dart';
import '../../components/shared/app_drawer.dart';
import '../../components/shared/loading_overlay.dart';
import '../../components/booking/booking_card.dart';
import '../../config/constants.dart';

class PlayerBookingsScreen extends StatelessWidget {
  const PlayerBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookingController = TurfBookingController.instance;

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: const Text(
          'My Bookings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(AppColors.primaryColor),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Filter Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Dropdown filter
                Obx(
                  () => DropdownButtonFormField<TurfBookingStatus?>(
                    value: bookingController.statusFilter.value,
                    decoration: const InputDecoration(
                      labelText: 'Filter by Status',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All')),
                      ...TurfBookingStatus.values.map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.name.toUpperCase()),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      bookingController.applyFilters(status: value);
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // Clear button
                Container(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      bookingController.clearFilters();
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear Filters'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      foregroundColor: Colors.grey[700],
                    ),
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
                  if (bookingController.userBookings.isEmpty &&
                      !bookingController.isLoading.value) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.book_online, size: 64, color: Colors.grey),
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
                            'You haven\'t made any turf bookings yet.\nStart by browsing available turfs.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () =>
                        bookingController.loadUserBookings(refresh: true),
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (scrollInfo) {
                        // Load more data when reaching the end
                        if (scrollInfo.metrics.pixels ==
                                scrollInfo.metrics.maxScrollExtent &&
                            bookingController.hasMoreData.value &&
                            !bookingController.isLoading.value) {
                          bookingController.loadUserBookings();
                        }
                        return false;
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount:
                            bookingController.userBookings.length +
                            (bookingController.hasMoreData.value ? 1 : 0),
                        itemBuilder: (context, index) {
                          // Show loading indicator at the end if there's more data
                          if (index == bookingController.userBookings.length) {
                            return Obx(
                              () => bookingController.isLoading.value
                                  ? const Padding(
                                      padding: EdgeInsets.all(20),
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    )
                                  : const SizedBox(),
                            );
                          }

                          final booking = bookingController.userBookings[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: BookingCard(
                              booking: booking,
                              isOwnerView: false,
                              onCancel: (bookingId) {
                                _showCancelDialog(context, bookingId);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }),

                // Loading overlay for initial load
                Obx(
                  () => LoadingOverlay(
                    isLoading:
                        bookingController.isLoading.value &&
                        bookingController.userBookings.isEmpty,
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
}
