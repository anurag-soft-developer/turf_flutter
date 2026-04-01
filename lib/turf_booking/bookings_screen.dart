import 'package:flutter/material.dart';
import 'package:flutter_application_1/settings/settings_controller.dart';
import 'package:get/get.dart';
import 'turf_booking_controller.dart';
import '../components/shared/loading_overlay.dart';
import '../components/booking/booking_action_dialogs.dart';
import '../components/booking/booking_card.dart';
import '../components/booking/filter_bottom_sheet.dart';
import '../components/booking/qr_scanner_screen.dart';
import '../core/config/constants.dart';

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

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
          // Scanner button for proprietor mode
          if (setting.isProprietorMode)
            IconButton(
              onPressed: () => Get.to(() => const QRScannerScreen()),
              icon: const Icon(Icons.qr_code_scanner),
              tooltip: 'Scan QR Code',
            ),
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
                        onCancel: BookingActionDialogs.showCancelBooking,
                        onComplete: BookingActionDialogs.showCompleteBooking,
                        onConfirm: BookingActionDialogs.showConfirmBooking,
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
}
