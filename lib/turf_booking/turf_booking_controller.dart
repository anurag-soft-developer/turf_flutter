import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'model/turf_booking_model.dart';
import '../components/shared/app_segmented_tabs/segmented_tab_cache_controller.dart';
import 'turf_booking_service.dart';
import '../core/utils/exception_handler.dart';

enum BookingsTab { upcoming, pending, archive }

class TurfBookingController extends GetxController
    with SegmentedTabCacheController<BookingsTab, TurfBookingModel> {
  static TurfBookingController get instance => Get.find();
  final TurfBookingService _bookingService = TurfBookingService();

  // Observable variables
  final RxBool _isBookingLoading = false.obs;
  final Rxn<TurfBookingModel> _selectedBooking = Rxn<TurfBookingModel>();
  final Rx<BookingsTab> _selectedTab = BookingsTab.upcoming.obs;
  static const int _pageSize = 20;

  // Filters
  final Rxn<PaymentStatus> _paymentStatusFilter = Rxn<PaymentStatus>();

  // Getters - Return observables for reactivity
  RxBool get isBookingLoading => _isBookingLoading;
  Rxn<TurfBookingModel> get selectedBooking => _selectedBooking;
  Rx<BookingsTab> get selectedTab => _selectedTab;
  Rxn<PaymentStatus> get paymentStatusFilter => _paymentStatusFilter;

  @override
  List<BookingsTab> get tabKeys => BookingsTab.values;

  @override
  bool get paginatedTabs => true;

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
        final pendingState = tabStateFor(BookingsTab.pending);
        setTabState(
          BookingsTab.pending,
          pendingState.copyWith(
            items: [bookingOrder.booking, ...pendingState.items],
          ),
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
    await ensureTabLoaded(_selectedTab.value, force: refresh);
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
  // Future<bool> cancelBooking(String bookingId, String? cancelReason) async {
  //   try {
  //     _isBookingLoading.value = true;

  //     final updatedBooking = await _bookingService.cancelBooking(
  //       bookingId,
  //       cancelReason,
  //     );

  //     if (updatedBooking != null) {
  //       // Update the booking in lists
  //       _updateBookingInLists(updatedBooking);
  //       ExceptionHandler.showSuccessToast('Booking cancelled successfully');
  //       return true;
  //     }

  //     return false;
  //   } catch (e) {
  //     debugPrint('Error cancelling booking: $e');
  //     ExceptionHandler.showErrorToast('Failed to cancel booking');
  //     return false;
  //   } finally {
  //     _isBookingLoading.value = false;
  //   }
  // }

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

  /// Apply filters (kept for backward compatibility)
  void applyFilters({PaymentStatus? paymentStatus}) {
    _paymentStatusFilter.value = paymentStatus;
    refreshAll();
  }

  /// Clear filters
  void clearFilters() {
    _paymentStatusFilter.value = null;
    refreshAll();
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
    ensureTabLoaded(_selectedTab.value);
  }

  Future<void> switchTab(BookingsTab tab) async {
    if (_selectedTab.value == tab) return;
    _selectedTab.value = tab;
    await ensureTabLoaded(tab);
  }

  Future<void> loadMore(BookingsTab key) => loadMoreTab(key);

  @override
  Future<List<TurfBookingModel>> fetchTabItems(BookingsTab key) async {
    return (await fetchTabPage(key, 1)).items;
  }

  @override
  Future<SegmentedTabPageResult<TurfBookingModel>> fetchTabPage(
    BookingsTab key,
    int page,
  ) async {
    final statuses = switch (key) {
      BookingsTab.upcoming => const [TurfBookingStatus.confirmed],
      BookingsTab.pending => const [TurfBookingStatus.pending],
      BookingsTab.archive => null,
    };
    final upcoming = switch (key) {
      BookingsTab.upcoming => true,
      BookingsTab.pending => true,
      BookingsTab.archive => false,
    };
    final sortBy = key == BookingsTab.archive ? 'updatedAt' : 'createdAt';
    final sortOrder = key == BookingsTab.archive ? 'desc' : 'asc';

    final response = await _bookingService.findBookings(
      page: page,
      limit: _pageSize,
      status: statuses,
      upcoming: upcoming,
      paymentStatus: _paymentStatusFilter.value,
      sortBy: sortBy,
      sortOrder: sortOrder,
    );

    return SegmentedTabPageResult(
      items: response?.data ?? <TurfBookingModel>[],
      page: response?.page ?? page,
      hasMore: response?.hasNextPage ?? false,
    );
  }

  @override
  String mapFetchError(Object error) => 'Failed to load bookings';
}
