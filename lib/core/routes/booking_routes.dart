import 'package:flutter_application_1/bindings/turf_booking_binding.dart';
import 'package:flutter_application_1/components/booking/booking_details_screen.dart';
import 'package:flutter_application_1/components/booking/booking_ticket_screen.dart';
import 'package:flutter_application_1/core/config/constants.dart';
import 'package:flutter_application_1/core/guards/auth_guard.dart';
import 'package:flutter_application_1/turf_booking/bookings_screen.dart';
import 'package:get/get.dart';

final List<GetPage<dynamic>> bookingRoutes = [
  GetPage(
    name: AppConstants.routes.myBookings,
    page: () => const BookingsScreen(),
    binding: TurfBookingBinding(),
    transition: Transition.cupertino,
    middlewares: [AuthGuard()],
  ),
  GetPage(
    name: AppConstants.routes.bookingDetails,
    page: () => const BookingDetailsScreen(),
    transition: Transition.cupertino,
    middlewares: [AuthGuard()],
  ),
  GetPage(
    name: AppConstants.routes.bookingTicket,
    page: () => const BookingTicketScreen(),
    transition: Transition.cupertino,
    middlewares: [AuthGuard()],
  ),
];
