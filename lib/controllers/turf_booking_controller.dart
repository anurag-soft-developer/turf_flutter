import 'package:flutter/material.dart';
import 'package:flutter_application_1/controllers/settings_controller.dart';
import 'package:get/get.dart';
import '../models/turf_booking_model.dart';
import '../models/common/paginated_response.dart';
import '../services/turf_booking_service.dart';
import '../utils/exception_handler.dart';

class TurfBookingController extends GetxController {
  static TurfBookingController get instance => Get.find();
  final settingController = Get.find<SettingsController>();
  final TurfBookingService _bookingService = TurfBookingService();

  // Observable variables
  final RxBool _isLoading = false.obs;
  final RxBool _isBookingLoading = false.obs;
  final RxList<TurfBookingModel> _bookings = <TurfBookingModel>[].obs;
  // final RxList<TurfBookingModel> _turfOwnerBookings = <TurfBookingModel>[].obs;
  // final RxList<TurfBookingModel> _upcomingBookings = <TurfBookingModel>[].obs;
  final Rxn<TurfBookingModel> _selectedBooking = Rxn<TurfBookingModel>();

  // Pagination
  final RxInt _currentPage = 1.obs;
  final RxBool _hasMoreData = true.obs;
  final int _limitPerPage = 10;

  // Filters
  final RxList<TurfBookingStatus> _selectedStatusFilters =
      <TurfBookingStatus>[].obs;
  final Rxn<PaymentStatus> _paymentStatusFilter = Rxn<PaymentStatus>();

  // Getters - Return observables for reactivity
  RxBool get isLoading => _isLoading;
  RxBool get isBookingLoading => _isBookingLoading;
  RxList<TurfBookingModel> get bookings => _bookings;
  // RxList<TurfBookingModel> get turfOwnerBookings => _turfOwnerBookings;
  // RxList<TurfBookingModel> get upcomingBookings => _upcomingBookings;
  Rxn<TurfBookingModel> get selectedBooking => _selectedBooking;
  RxInt get currentPage => _currentPage;
  RxBool get hasMoreData => _hasMoreData;
  RxList<TurfBookingStatus> get selectedStatusFilters => _selectedStatusFilters;
  Rxn<PaymentStatus> get paymentStatusFilter => _paymentStatusFilter;

  @override
  void onInit() {
    super.onInit();
    refreshAll();
  }

  /// Create a new booking
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

      final booking = await _bookingService.createBooking(request);

      if (booking != null) {
        _bookings.insert(0, booking);
        ExceptionHandler.showSuccessToast('Booking created successfully');
        // Refresh upcoming bookings
        // loadUpcomingBookings();
      }

      return booking;
    } catch (e) {
      debugPrint('Error creating booking: $e');
      ExceptionHandler.showErrorToast('Failed to create booking');
      return null;
    } finally {
      _isBookingLoading.value = false;
    }
  }

  /// Check if time slots are available
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

  /// Load user's bookings
  Future<void> loadBookings({bool refresh = false}) async {
    try {
      if (refresh) {
        _currentPage.value = 1;
        _hasMoreData.value = true;
        _bookings.clear();
      }

      if (!_hasMoreData.value) return;

      _isLoading.value = true;

      final response = settingController.isPlayerMode
          ? await _bookingService.findPlayerBookings(
              page: _currentPage.value,
              limit: _limitPerPage,
              status: _selectedStatusFilters.isNotEmpty
                  ? _selectedStatusFilters
                  : null,
              paymentStatus: _paymentStatusFilter.value,
            )
          : await _bookingService.findTurfOwnerBookings();

      if (response == null) {
        _hasMoreData.value = false;
        return;
      }

      _hasMoreData.value = response.hasNextPage;

      if (refresh) {
        _bookings.assignAll(response.data);
      } else {
        _bookings.addAll(response.data);
      }

      _currentPage.value++;
    } catch (e) {
      debugPrint('Error loading bookings: $e');
      ExceptionHandler.showErrorToast('Failed to load bookings');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Load turf owner's bookings
  // Future<void> loadTurfOwnerBookings({bool refresh = false}) async {
  //   try {
  //     if (refresh) {
  //       _turfOwnerBookings.clear();
  //     }

  //     _isLoading.value = true;

  //     final response = await _bookingService.findTurfOwnerBookings();

  //     if (response != null) {
  //       _turfOwnerBookings.assignAll(response.data);
  //     }
  //     debugPrint('response iop: $response');
  //   } catch (e) {
  //     debugPrint('Error loading turf owner bookings: $e');
  //     ExceptionHandler.showErrorToast('Failed to load turf bookings');
  //   } finally {
  //     _isLoading.value = false;
  //   }
  // }

  /// Load upcoming bookings
  // Future<void> loadUpcomingBookings() async {
  //   try {
  //     final bookings = await _bookingService.getUpcomingBookings(limit: 5);
  //     _upcomingBookings.assignAll(bookings);
  //   } catch (e) {
  //     debugPrint('Error loading upcoming bookings: $e');
  //     // Silent fail for upcoming bookings
  //   }
  // }

  /// Get booking by ID
  Future<void> getBookingById(String bookingId) async {
    try {
      _isLoading.value = true;

      final booking = await _bookingService.findById(bookingId);
      if (booking != null) {
        _selectedBooking.value = booking;
      }
    } catch (e) {
      debugPrint('Error loading booking by ID: $e');
      ExceptionHandler.showErrorToast('Failed to load booking details');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Cancel booking
  Future<bool> cancelBooking(String bookingId, String? cancelReason) async {
    try {
      _isBookingLoading.value = true;

      final updatedBooking = await _bookingService.cancelBooking(
        bookingId,
        cancelReason,
      );

      if (updatedBooking != null) {
        // Update the booking in lists
        _updateBookingInLists(updatedBooking);
        ExceptionHandler.showSuccessToast('Booking cancelled successfully');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error cancelling booking: $e');
      ExceptionHandler.showErrorToast('Failed to cancel booking');
      return false;
    } finally {
      _isBookingLoading.value = false;
    }
  }

  /// Confirm booking (for turf owners)
  Future<bool> confirmBooking(String bookingId) async {
    try {
      _isBookingLoading.value = true;

      final updatedBooking = await _bookingService.confirmBooking(bookingId);

      if (updatedBooking != null) {
        _updateBookingInLists(updatedBooking);
        ExceptionHandler.showSuccessToast('Booking confirmed successfully');
        return true;
      }

      return false;
    } catch (e) {
      ExceptionHandler.showErrorToast('Failed to confirm booking');
      return false;
    } finally {
      _isBookingLoading.value = false;
    }
  }

  /// Complete booking
  Future<bool> completeBooking(String bookingId) async {
    try {
      _isBookingLoading.value = true;

      final updatedBooking = await _bookingService.completeBooking(bookingId);

      if (updatedBooking != null) {
        _updateBookingInLists(updatedBooking);
        ExceptionHandler.showSuccessToast('Booking completed successfully');
        return true;
      }

      return false;
    } catch (e) {
      ExceptionHandler.showErrorToast('Failed to complete booking');
      return false;
    } finally {
      _isBookingLoading.value = false;
    }
  }

  /// Update payment status
  Future<bool> updatePaymentStatus(
    String bookingId,
    PaymentStatus paymentStatus, {
    String? paymentId,
  }) async {
    try {
      _isBookingLoading.value = true;

      final updatedBooking = await _bookingService.updatePaymentStatus(
        bookingId,
        paymentStatus,
        paymentId: paymentId,
      );

      if (updatedBooking != null) {
        _updateBookingInLists(updatedBooking);
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

  /// Delete booking
  // Future<bool> deleteBooking(String bookingId) async {
  //   try {
  //     _isBookingLoading.value = true;

  //     final success = await _bookingService.deleteBooking(bookingId);

  //     if (success) {
  //       _removeBookingFromLists(bookingId);
  //       ExceptionHandler.showSuccessToast('Booking deleted successfully');
  //       return true;
  //     }

  //     return false;
  //   } catch (e) {
  //     ExceptionHandler.showErrorToast('Failed to delete booking');
  //     return false;
  //   } finally {
  //     _isBookingLoading.value = false;
  //   }
  // }

  /// Toggle status filter
  void toggleStatusFilter(TurfBookingStatus status) {
    if (_selectedStatusFilters.contains(status)) {
      _selectedStatusFilters.remove(status);
    } else {
      _selectedStatusFilters.add(status);
    }
    loadBookings(refresh: true);
  }

  /// Apply filters (kept for backward compatibility)
  void applyFilters({TurfBookingStatus? status, PaymentStatus? paymentStatus}) {
    if (status != null) {
      _selectedStatusFilters.clear();
      _selectedStatusFilters.add(status);
    }
    _paymentStatusFilter.value = paymentStatus;
    loadBookings(refresh: true);
  }

  /// Clear filters
  void clearFilters() {
    _selectedStatusFilters.clear();
    _paymentStatusFilter.value = null;
    loadBookings(refresh: true);
  }

  /// Helper method to update booking in all lists
  void _updateBookingInLists(TurfBookingModel updatedBooking) {
    // Update in user bookings
    final userIndex = _bookings.indexWhere((b) => b.id == updatedBooking.id);
    if (userIndex != -1) {
      _bookings[userIndex] = updatedBooking;
    }

    // Update in turf owner bookings
    // final ownerIndex = _turfOwnerBookings.indexWhere(
    //   (b) => b.id == updatedBooking.id,
    // );
    // if (ownerIndex != -1) {
    //   _turfOwnerBookings[ownerIndex] = updatedBooking;
    // }

    // Update in upcoming bookings
    // final upcomingIndex = _upcomingBookings.indexWhere(
    //   (b) => b.id == updatedBooking.id,
    // );
    // if (upcomingIndex != -1) {
    //   _upcomingBookings[upcomingIndex] = updatedBooking;
    // }

    // Update selected booking
    if (_selectedBooking.value?.id == updatedBooking.id) {
      _selectedBooking.value = updatedBooking;
    }
  }

  /// Helper method to remove booking from all lists
  void _removeBookingFromLists(String bookingId) {
    _bookings.removeWhere((booking) => booking.id == bookingId);
    // _turfOwnerBookings.removeWhere((booking) => booking.id == bookingId);
    // _upcomingBookings.removeWhere((booking) => booking.id == bookingId);

    if (_selectedBooking.value?.id == bookingId) {
      _selectedBooking.value = null;
    }
  }

  /// Get bookings for a specific turf
  Future<List<TurfBookingModel>> getTurfBookings(
    String turfId, {
    TurfBookingStatus? status,
    PaymentStatus? paymentStatus,
  }) async {
    try {
      final response = await _bookingService.findTurfBookings(
        turfId,
        status: status,
        paymentStatus: paymentStatus,
      );

      return response?.data ?? [];
    } catch (e) {
      ExceptionHandler.showErrorToast('Failed to load turf bookings');
      return [];
    }
  }

  /// Get today's bookings for a turf
  Future<List<TurfBookingModel>> getTodaysBookings(String turfId) async {
    try {
      return await _bookingService.getTodaysBookings(turfId);
    } catch (e) {
      ExceptionHandler.showErrorToast('Failed to load today\'s bookings');
      return [];
    }
  }

  /// Refresh all data
  void refreshAll() {
    // if (settingController.isPlayerMode) {
    loadBookings(refresh: true);
    //   debugPrint('Refreshing user bookings');
    // } else {
    //   // loadTurfOwnerBookings(refresh: true);
    //   debugPrint('Refreshing turf owner bookings');
    // }
    // loadUpcomingBookings();
  }

  @override
  void onClose() {
    super.onClose();
  }
}
