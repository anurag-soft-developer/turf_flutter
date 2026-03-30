// import 'package:flutter/material.dart';
// import 'package:flutter_application_1/components/booking/filter_bottom_sheet.dart';
// import 'package:get/get.dart';
// import '../player/turf_booking_controller.dart';
// import '../model/turf_booking_model.dart';
// import '../../components/shared/app_drawer.dart';
// import '../../components/shared/loading_overlay.dart';
// import '../../components/booking/booking_card.dart';
// import '../../core/config/constants.dart';

// class OwnerBookingsScreen extends StatelessWidget {
//   const OwnerBookingsScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final bookingController = TurfBookingController.instance;

//     return Scaffold(
//       backgroundColor: const Color(AppColors.backgroundColor),
//       appBar: AppBar(
//         title: const Text(
//           'Turf Bookings',
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         backgroundColor: const Color(AppColors.primaryColor),
//         foregroundColor: Colors.white,
//         elevation: 0,
//         actions: [
//           IconButton(
//             onPressed: () =>
//                 BookingFilterBottomSheet.show(context, bookingController),
//             icon: const Icon(Icons.filter_list),
//           ),
//         ],
//       ),
//       // drawer: const AppDrawer(),
//       body: Column(
//         children: [
//           // Bookings List
//           Expanded(
//             child: Stack(
//               children: [
//                 Obx(() {
//                   if (bookingController.bookings.isEmpty &&
//                       !bookingController.isLoading.value) {
//                     return const Center(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(
//                             Icons.calendar_today,
//                             size: 64,
//                             color: Colors.grey,
//                           ),
//                           SizedBox(height: 16),
//                           Text(
//                             'No Bookings Found',
//                             style: TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.w500,
//                               color: Colors.grey,
//                             ),
//                           ),
//                           SizedBox(height: 8),
//                           Text(
//                             'No customers have booked your turfs yet.\nMake sure your turfs are properly listed.',
//                             textAlign: TextAlign.center,
//                             style: TextStyle(color: Colors.grey),
//                           ),
//                         ],
//                       ),
//                     );
//                   }

//                   return RefreshIndicator(
//                     onRefresh: () =>
//                         bookingController.loadBookings(refresh: true),
//                     child: ListView.builder(
//                       padding: const EdgeInsets.all(16),
//                       itemCount: bookingController.bookings.length,
//                       itemBuilder: (context, index) {
//                         final booking = bookingController.bookings[index];
//                         return Padding(
//                           padding: const EdgeInsets.only(bottom: 12),
//                           child: BookingCard(
//                             booking: booking,
//                             isOwnerView: true,
//                             onConfirm: (bookingId) {
//                               _showConfirmDialog(context, bookingId);
//                             },
//                             onCancel: (bookingId) {
//                               _showCancelDialog(context, bookingId);
//                             },
//                             onComplete: (bookingId) {
//                               _showCompleteDialog(context, bookingId);
//                             },
//                           ),
//                         );
//                       },
//                     ),
//                   );
//                 }),

//                 // Loading overlay for initial load
//                 Obx(
//                   () => LoadingOverlay(
//                     isLoading:
//                         bookingController.isLoading.value &&
//                         bookingController.bookings.isEmpty,
//                     child: const SizedBox(),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showConfirmDialog(BuildContext context, String bookingId) {
//     Get.dialog(
//       AlertDialog(
//         title: const Text('Confirm Booking'),
//         content: const Text('Are you sure you want to confirm this booking?'),
//         actions: [
//           Row(
//             children: [
//               Expanded(
//                 child: ElevatedButton(
//                   onPressed: () => Get.back(),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.red,
//                     foregroundColor: Colors.white,
//                   ),
//                   child: const Text('No'),
//                 ),
//               ),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: ElevatedButton(
//                   onPressed: () {
//                     Get.back();
//                     TurfBookingController.instance.confirmBooking(bookingId);
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.green,
//                     foregroundColor: Colors.white,
//                   ),
//                   child: const Text('Confirm'),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   // void _showCancelDialog(BuildContext context, String bookingId) {
//   //   final reasonController = TextEditingController();

//   //   Get.dialog(
//   //     AlertDialog(
//   //       title: const Text('Cancel Booking'),
//   //       content: Column(
//   //         mainAxisSize: MainAxisSize.min,
//   //         children: [
//   //           const Text('Are you sure you want to cancel this booking?'),
//   //           const SizedBox(height: 16),
//   //           TextField(
//   //             controller: reasonController,
//   //             decoration: const InputDecoration(
//   //               labelText: 'Cancellation Reason',
//   //               border: OutlineInputBorder(),
//   //             ),
//   //             maxLines: 3,
//   //           ),
//   //         ],
//   //       ),
//   //       actions: [
//   //         Row(
//   //           children: [
//   //             Expanded(
//   //               child: ElevatedButton(
//   //                 onPressed: () => Get.back(),
//   //                 style: ElevatedButton.styleFrom(
//   //                   backgroundColor: Colors.red,
//   //                   foregroundColor: Colors.white,
//   //                 ),
//   //                 child: const Text('No'),
//   //               ),
//   //             ),
//   //             const SizedBox(width: 8),
//   //             Expanded(
//   //               child: ElevatedButton(
//   //                 onPressed: () {
//   //                   if (reasonController.text.trim().isNotEmpty) {
//   //                     Get.back();
//   //                     TurfBookingController.instance.cancelBooking(
//   //                       bookingId,
//   //                       reasonController.text.trim(),
//   //                     );
//   //                   }
//   //                 },
//   //                 style: ElevatedButton.styleFrom(
//   //                   backgroundColor: Colors.red,
//   //                   foregroundColor: Colors.white,
//   //                 ),
//   //                 child: const Text('Yes, Cancel'),
//   //               ),
//   //             ),
//   //           ],
//   //         ),
//   //       ],
//   //     ),
//   //   );
//   // }

//   // void _showCompleteDialog(BuildContext context, String bookingId) {
//   //   Get.dialog(
//   //     AlertDialog(
//   //       title: const Text('Complete Booking'),
//   //       content: const Text(
//   //         'Are you sure you want to mark this booking as completed?',
//   //       ),
//   //       actions: [
//   //         Row(
//   //           children: [
//   //             Expanded(
//   //               child: ElevatedButton(
//   //                 onPressed: () => Get.back(),
//   //                 style: ElevatedButton.styleFrom(
//   //                   backgroundColor: Colors.red,
//   //                   foregroundColor: Colors.white,
//   //                 ),
//   //                 child: const Text('No'),
//   //               ),
//   //             ),
//   //             Expanded(
//   //               child: ElevatedButton(
//   //                 onPressed: () {
//   //                   Get.back();
//   //                   TurfBookingController.instance.completeBooking(bookingId);
//   //                 },
//   //                 style: ElevatedButton.styleFrom(
//   //                   backgroundColor: const Color(AppColors.primaryColor),
//   //                   foregroundColor: Colors.white,
//   //                 ),
//   //                 child: const Text('Yes, Complete'),
//   //               ),
//   //             ),
//   //           ],
//   //         ),
//   //       ],
//   //     ),
//   //   );
//   // }
// }

// // class _StatCard extends StatelessWidget {
// //   final String title;
// //   final String value;
// //   final IconData icon;
// //   final Color color;

// //   const _StatCard({
// //     required this.title,
// //     required this.value,
// //     required this.icon,
// //     required this.color,
// //   });

// //   @override
// //   Widget build(BuildContext context) {
// //     return Container(
// //       padding: const EdgeInsets.all(12),
// //       decoration: BoxDecoration(
// //         color: color.withValues(alpha: .1),
// //         borderRadius: BorderRadius.circular(8),
// //         border: Border.all(color: color.withValues(alpha: 0.3)),
// //       ),
// //       child: Column(
// //         children: [
// //           Icon(icon, color: color, size: 24),
// //           const SizedBox(height: 4),
// //           Text(
// //             value,
// //             style: TextStyle(
// //               fontSize: 18,
// //               fontWeight: FontWeight.bold,
// //               color: color,
// //             ),
// //           ),
// //           Text(
// //             title,
// //             style: TextStyle(fontSize: 12, color: color),
// //             textAlign: TextAlign.center,
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
