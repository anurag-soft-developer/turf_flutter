import 'package:flutter/material.dart';
import 'package:flutter_application_1/components/shared/custom_confirm_dialog.dart';
import 'package:flutter_application_1/settings/settings_controller.dart';
import 'package:get/get.dart';
import 'turf_booking_controller.dart';
import '../model/turf_booking_model.dart';
import '../../components/shared/app_drawer.dart';
import '../../components/shared/loading_overlay.dart';
import '../../components/booking/booking_card.dart';
import '../../components/booking/filter_bottom_sheet.dart';
import '../../core/config/constants.dart';

class PlayerBookingsScreen extends StatelessWidget {
  const PlayerBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookingController = TurfBookingController.instance;
    final SettingsController setting = Get.find<SettingsController>();

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: Obx(
          () => Text(
            setting.isPlayerMode ? 'My Bookings' : "Turf Bookings",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: const Color(AppColors.primaryColor),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () =>
                BookingFilterBottomSheet.show(context, bookingController),
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      // drawer: const AppDrawer(),
      body: Stack(
        children: [
          // Bookings List
          Obx(() {
            if (bookingController.bookings.isEmpty &&
                !bookingController.isLoading.value) {
              return Center(
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
                      setting.isPlayerMode
                          ? 'You haven\'t made any turf bookings yet.\nStart by browsing available turfs.'
                          : 'No customers have booked your turfs yet.\nMake sure your turfs are properly listed.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => bookingController.loadBookings(refresh: true),
              child: NotificationListener<ScrollNotification>(
                // onNotification: (scrollInfo) {
                //   // Load more data when reaching the end
                //   if (scrollInfo.metrics.pixels ==
                //           scrollInfo.metrics.maxScrollExtent &&
                //       bookingController.hasMoreData.value &&
                //       !bookingController.isLoading.value) {
                //     bookingController.loadBookings();
                //   }
                //   return false;
                // },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount:
                      bookingController.bookings.length +
                      (bookingController.hasMoreData.value ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Show loading indicator at the end if there's more data
                    if (index == bookingController.bookings.length) {
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

                    final booking = bookingController.bookings[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: BookingCard(
                        booking: booking,
                        isOwnerView: setting.isProprietorMode,
                        onCancel: (bookingId) {
                          _showCancelDialog(context, bookingId);
                        },
                        onComplete: (bookingId) {
                          _showCompleteDialog(context, bookingId);
                        },
                        onConfirm: (bookingId) {
                          _showConfirmDialog(context, bookingId);
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
                  bookingController.bookings.isEmpty,
              child: const SizedBox(),
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

  void _showConfirmDialog(BuildContext context, String bookingId) {
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

  //       children: [
  //         Expanded(
  //           child: ElevatedButton(
  //             onPressed: () => Get.back(),
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: Colors.red,
  //               foregroundColor: Colors.white,
  //             ),
  //             child: const Text('No'),
  //           ),
  //         ),
  //         const SizedBox(width: 8),
  //         Expanded(
  //           child: ElevatedButton(
  //             onPressed: () {
  //               Get.back();
  //               TurfBookingController.instance.confirmBooking(bookingId);
  //             },
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: Colors.green,
  //               foregroundColor: Colors.white,
  //             ),
  //             child: const Text('Confirm'),
  //           ),
  //         ),
  //       ],
  //     ),
  //   ],
  // ),
  // );
  // }

  void _showCompleteDialog(BuildContext context, String bookingId) {
    Get.dialog(
      ConfirmDialog(
        title: 'Complete Booking',
        content: 'Are you sure you want to mark this booking as completed?',
        onConfirm: () {
          TurfBookingController.instance.completeBooking(bookingId);
        },
      ),
    );

    // AlertDialog(
    //   title: const Text('Complete Booking'),
    //   content: const Text(
    //     'Are you sure you want to mark this booking as completed?',
    //   ),
    //   actions: [
    //     Row(
    //       children: [
    //         Expanded(
    //           child: ElevatedButton(
    //             onPressed: () => Get.back(),
    //             style: ElevatedButton.styleFrom(
    //               backgroundColor: Colors.red,
    //               foregroundColor: Colors.white,
    //             ),
    //             child: const Text('No'),
    //           ),
    //         ),
    //         Expanded(
    //           child: ElevatedButton(
    //             onPressed: () {
    //               Get.back();
    //               TurfBookingController.instance.completeBooking(bookingId);
    //             },
    //             style: ElevatedButton.styleFrom(
    //               backgroundColor: const Color(AppColors.primaryColor),
    //               foregroundColor: Colors.white,
    //             ),
    //             child: const Text('Yes, Complete'),
    //           ),
    //         ),
    //       ],
    //     ),
    //   ],
    // ),
    // );
  }
}
