import 'package:flutter/material.dart';
import 'package:flutter_application_1/settings/settings_controller.dart';
import 'package:get/get.dart';
import 'model/turf_booking_model.dart';
import '../components/shared/app_segmented_tabs/segmented_tab_cache_controller.dart';
import 'turf_booking_service.dart';
import '../core/utils/exception_handler.dart';

class TurfBookingController extends GetxController
    with SegmentedTabCacheController<TurfBookingStatus?, TurfBookingModel> {
  static TurfBookingController get instance => Get.find();
  final settingController = Get.find<SettingsController>();
  final TurfBookingService _bookingService = TurfBookingService();

  // Observable variables
  final RxBool _isBookingLoading = false.obs;
  final Rxn<TurfBookingModel> _selectedBooking = Rxn<TurfBookingModel>();
  final Rxn<TurfBookingStatus> _selectedStatusTab = Rxn<TurfBookingStatus>();
  final int _limitPerPage = 50;

  // Filters
  final Rxn<PaymentStatus> _paymentStatusFilter = Rxn<PaymentStatus>();

  // Getters - Return observables for reactivity
  RxBool get isBookingLoading => _isBookingLoading;
  Rxn<TurfBookingModel> get selectedBooking => _selectedBooking;
  Rxn<TurfBookingStatus> get selectedStatusTab => _selectedStatusTab;
  RxList<TurfBookingStatus> get selectedStatusFilters => RxList.unmodifiable(
    _selectedStatusTab.value == null
        ? const <TurfBookingStatus>[]
        : <TurfBookingStatus>[_selectedStatusTab.value!],
  );
  Rxn<PaymentStatus> get paymentStatusFilter => _paymentStatusFilter;

  @override
  List<TurfBookingStatus?> get tabKeys => [null, ...TurfBookingStatus.values];

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

      final bookingOrder = await _bookingService.createBookingOrder(request);

      if (bookingOrder != null) {
        final allState = tabStateFor(null);
        setTabState(
          null,
          allState.copyWith(items: [bookingOrder.booking, ...allState.items]),
        );
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
    await ensureTabLoaded(_selectedStatusTab.value, force: refresh);
  }

  /// Get booking by ID
  Future<void> getBookingById(String bookingId) async {
    try {
      final booking = await _bookingService.findById(bookingId);
      if (booking != null) {
        _selectedBooking.value = booking;
      }
    } catch (e) {
      debugPrint('Error loading booking by ID: $e');
      ExceptionHandler.showErrorToast('Failed to load booking details');
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

  /// Toggle status filter
  void toggleStatusFilter(TurfBookingStatus status) {
    if (_selectedStatusTab.value == status) {
      _selectedStatusTab.value = null;
    } else {
      _selectedStatusTab.value = status;
    }
    ensureTabLoaded(_selectedStatusTab.value, force: true);
  }

  /// Apply filters (kept for backward compatibility)
  void applyFilters({TurfBookingStatus? status, PaymentStatus? paymentStatus}) {
    _selectedStatusTab.value = status;
    _paymentStatusFilter.value = paymentStatus;
    ensureTabLoaded(_selectedStatusTab.value, force: true);
  }

  /// Clear filters
  void clearFilters() {
    _selectedStatusTab.value = null;
    _paymentStatusFilter.value = null;
    ensureTabLoaded(_selectedStatusTab.value, force: true);
  }

  /// Helper method to update booking in all lists
  void _updateBookingInLists(TurfBookingModel updatedBooking) {
    for (final key in tabKeys) {
      final state = tabStateFor(key);
      final index = state.items.indexWhere((b) => b.id == updatedBooking.id);
      if (index == -1) continue;
      final updated = [...state.items];
      updated[index] = updatedBooking;
      setTabState(key, state.copyWith(items: updated));
    }

    // Update selected booking
    if (_selectedBooking.value?.id == updatedBooking.id) {
      _selectedBooking.value = updatedBooking;
    }
  }

  /// Get bookings for a specific turf
  Future<List<TurfBookingModel>> getTurfBookings(
    String turfId, {
    TurfBookingStatus? status,
    PaymentStatus? paymentStatus,
  }) async {
    try {
      final response = await _bookingService.findBookings(
        settingController.currentMode.value,
        turf: turfId,
        status: status != null ? [status] : null,
        paymentStatus: paymentStatus,
      );

      return response?.data ?? [];
    } catch (e) {
      ExceptionHandler.showErrorToast('Failed to load turf bookings');
      return [];
    }
  }

  /// Refresh all data
  void refreshAll() {
    for (final key in tabKeys) {
      setTabState(key, const SegmentedTabDataState<TurfBookingModel>());
    }
    ensureTabLoaded(_selectedStatusTab.value);
  }

  Future<void> switchStatusTab(TurfBookingStatus? status) async {
    if (_selectedStatusTab.value == status) return;
    _selectedStatusTab.value = status;
    await ensureTabLoaded(status);
  }

  @override
  Future<List<TurfBookingModel>> fetchTabItems(TurfBookingStatus? status) async {
    final response = await _bookingService.findBookings(
      settingController.currentMode.value,
      page: 1,
      limit: _limitPerPage,
      status: status == null ? null : [status],
      paymentStatus: _paymentStatusFilter.value,
    );
    return response?.data ?? <TurfBookingModel>[];
  }

  @override
  String mapFetchError(Object error) => 'Failed to load bookings';

  /// Validate booking for check-in (scanner functionality)
  Future<TurfBookingModel?> validateBookingForCheckIn(String bookingId) async {
    try {
      final booking = await _bookingService.findById(bookingId);

      if (booking == null) {
        return null;
      }

      // Check if booking is valid for check-in (confirmed status)
      if (booking.status != TurfBookingStatus.confirmed) {
        throw Exception('Booking is not in confirmed status');
      }

      // Additional validation can be added here
      // For example, check if booking is for today or future date

      return booking;
    } catch (e) {
      debugPrint('Error validating booking for check-in: $e');
      throw Exception('Invalid booking or not eligible for check-in');
    }
  }

  /// Check-in booking (for proprietors)
  Future<bool> checkInBooking(String bookingId) async {
    try {
      _isBookingLoading.value = true;

      // For now, we'll mark booking as completed when checked in
      // You can add a specific "checked-in" status if needed in the backend
      final updatedBooking = await _bookingService.completeBooking(bookingId);

      if (updatedBooking != null) {
        _updateBookingInLists(updatedBooking);
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error checking in booking: $e');
      throw Exception('Failed to check in booking');
    } finally {
      _isBookingLoading.value = false;
    }
  }
}
