import 'package:flutter/material.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../core/utils/exception_handler.dart';
import 'model/turf_booking_model.dart';
import 'turf_booking_service.dart';

enum BookingsTab { upcoming, pending, archive }

/// UI + mutation state. List fetching is owned by flutter_query on the screen.
class TurfBookingController extends GetxController {
  static TurfBookingController get instance => Get.find();
  final TurfBookingService _bookingService = TurfBookingService();

  final RxBool _isBookingLoading = false.obs;
  final Rxn<TurfBookingModel> _selectedBooking = Rxn<TurfBookingModel>();
  final Rx<BookingsTab> _selectedTab = BookingsTab.upcoming.obs;
  final Rxn<PaymentStatus> _paymentStatusFilter = Rxn<PaymentStatus>();

  RxBool get isBookingLoading => _isBookingLoading;
  Rxn<TurfBookingModel> get selectedBooking => _selectedBooking;
  Rx<BookingsTab> get selectedTab => _selectedTab;
  Rxn<PaymentStatus> get paymentStatusFilter => _paymentStatusFilter;

  Future<TurfBookingModel?> createBooking({
    required String turfId,
    required List<TimeSlot> timeSlots,
    int? playerCount,
    String? notes,
  }) async {
    try {
      _isBookingLoading.value = true;

      final request = CreateTurfBookingRequest(
        turf: turfId,
        timeSlots: timeSlots,
        playerCount: playerCount,
        notes: notes,
      );

      final bookingOrder = await _bookingService.createBookingOrder(request);

      if (bookingOrder != null) {
        await _invalidateBookings();
        ExceptionHandler.showSuccessToast('Booking created successfully');
      }

      return bookingOrder?.booking;
    } catch (e) {
      debugPrint('Error creating booking: $e');
      ExceptionHandler.showErrorToast('Failed to create booking');
      return null;
    } finally {
      _isBookingLoading.value = false;
    }
  }

  Future<bool> checkTimeSlotsAvailability({
    required String turfId,
    required List<TimeSlot> timeSlots,
    String? excludeBookingId,
  }) async {
    try {
      final request = CheckTurfAvailabilityRequest(
        turf: turfId,
        timeSlots: timeSlots,
        excludeBookingId: excludeBookingId,
      );

      return await _bookingService.checkTimeSlotsAvailability(request);
    } catch (e) {
      debugPrint('Error checking time slots availability: $e');
      ExceptionHandler.showErrorToast('Failed to check availability');
      return false;
    }
  }

  Future<bool> updatePaymentStatus(
    String bookingId,
    PaymentStatus paymentStatus, {
    String? razorpayPaymentId,
  }) async {
    try {
      _isBookingLoading.value = true;

      final updatedBooking = await _bookingService.updatePaymentStatus(
        bookingId,
        paymentStatus,
        razorpayPaymentId: razorpayPaymentId,
      );

      if (updatedBooking != null) {
        if (_selectedBooking.value?.id == updatedBooking.id) {
          _selectedBooking.value = updatedBooking;
        }
        await _invalidateBookings();
        ExceptionHandler.showSuccessToast(
          'Payment status updated successfully',
        );
        return true;
      }

      return false;
    } catch (e) {
      ExceptionHandler.showErrorToast('Failed to update payment status');
      return false;
    } finally {
      _isBookingLoading.value = false;
    }
  }

  void applyFilters({PaymentStatus? paymentStatus}) {
    _paymentStatusFilter.value = paymentStatus;
  }

  void clearFilters() {
    _paymentStatusFilter.value = null;
  }

  void switchTab(BookingsTab tab) {
    if (_selectedTab.value == tab) return;
    _selectedTab.value = tab;
  }

  Future<void> _invalidateBookings() async {
    if (!Get.isRegistered<QueryClient>()) return;
    await Get.find<QueryClient>().invalidateQueries(queryKey: ['bookings']);
  }
}
