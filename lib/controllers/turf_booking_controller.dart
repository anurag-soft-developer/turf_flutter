import 'package:get/get.dart';
import '../models/turf_booking_model.dart';
import '../services/turf_booking_service.dart';
import '../utils/exception_handler.dart';

class TurfBookingController extends GetxController {
  static TurfBookingController get instance => Get.find();

  final TurfBookingService _bookingService = TurfBookingService();

  // Observable variables
  final RxBool _isLoading = false.obs;
  final RxBool _isBookingLoading = false.obs;
  final RxList<TurfBookingModel> _userBookings = <TurfBookingModel>[].obs;
  final RxList<TurfBookingModel> _turfOwnerBookings = <TurfBookingModel>[].obs;
  final RxList<TurfBookingModel> _upcomingBookings = <TurfBookingModel>[].obs;
  final Rxn<TurfBookingModel> _selectedBooking = Rxn<TurfBookingModel>();

  // Pagination
  final RxInt _currentPage = 1.obs;
  final RxBool _hasMoreData = true.obs;
  final int _limitPerPage = 10;

  // Filters
  final Rxn<TurfBookingStatus> _statusFilter = Rxn<TurfBookingStatus>();
  final Rxn<PaymentStatus> _paymentStatusFilter = Rxn<PaymentStatus>();

  // Getters - Return observables for reactivity
  RxBool get isLoading => _isLoading;
  RxBool get isBookingLoading => _isBookingLoading;
  RxList<TurfBookingModel> get userBookings => _userBookings;
  RxList<TurfBookingModel> get turfOwnerBookings => _turfOwnerBookings;
  RxList<TurfBookingModel> get upcomingBookings => _upcomingBookings;
  Rxn<TurfBookingModel> get selectedBooking => _selectedBooking;
  RxInt get currentPage => _currentPage;
  RxBool get hasMoreData => _hasMoreData;
  Rxn<TurfBookingStatus> get statusFilter => _statusFilter;
  Rxn<PaymentStatus> get paymentStatusFilter => _paymentStatusFilter;

  @override
  void onInit() {
    super.onInit();
    loadUserBookings();
    loadUpcomingBookings();
  }

  /// Create a new booking
  Future<TurfBookingModel?> createBooking({
    required String turfId,
    required DateTime startTime,
    required DateTime endTime,
    int? playerCount,
    String? notes,
  }) async {
    try {
      _isBookingLoading.value = true;

      final request = CreateTurfBookingRequest(
        turf: turfId,
        startTime: startTime.toIso8601String(),
        endTime: endTime.toIso8601String(),
        playerCount: playerCount,
        notes: notes,
      );

      final booking = await _bookingService.createBooking(request);

      if (booking != null) {
        _userBookings.insert(0, booking);
        ExceptionHandler.showSuccessToast('Booking created successfully');
        // Refresh upcoming bookings
        loadUpcomingBookings();
      }

      return booking;
    } catch (e) {
      ExceptionHandler.showErrorToast('Failed to create booking');
      return null;
    } finally {
      _isBookingLoading.value = false;
    }
  }

  /// Check if time slot is available
  Future<bool> checkTimeSlotAvailability({
    required String turfId,
    required DateTime startTime,
    required DateTime endTime,
    String? excludeBookingId,
  }) async {
    try {
      final request = CheckTurfAvailabilityRequest(
        turf: turfId,
        startTime: startTime.toIso8601String(),
        endTime: endTime.toIso8601String(),
        excludeBookingId: excludeBookingId,
      );

      return await _bookingService.checkTimeSlotAvailability(request);
    } catch (e) {
      ExceptionHandler.showErrorToast('Failed to check availability');
      return false;
    }
  }

  /// Load user's bookings
  Future<void> loadUserBookings({bool refresh = false}) async {
    try {
      if (refresh) {
        _currentPage.value = 1;
        _hasMoreData.value = true;
        _userBookings.clear();
      }

      if (!_hasMoreData.value) return;

      _isLoading.value = true;

      final bookings = await _bookingService.findUserBookings(
        page: _currentPage.value,
        limit: _limitPerPage,
        status: _statusFilter.value,
        paymentStatus: _paymentStatusFilter.value,
      );

      if (bookings.length < _limitPerPage) {
        _hasMoreData.value = false;
      }

      if (refresh) {
        _userBookings.assignAll(bookings);
      } else {
        _userBookings.addAll(bookings);
      }

      _currentPage.value++;
    } catch (e) {
      ExceptionHandler.showErrorToast('Failed to load bookings');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Load turf owner's bookings
  Future<void> loadTurfOwnerBookings({bool refresh = false}) async {
    try {
      if (refresh) {
        _turfOwnerBookings.clear();
      }

      _isLoading.value = true;

      final bookings = await _bookingService.findTurfOwnerBookings();
      _turfOwnerBookings.assignAll(bookings);
    } catch (e) {
      ExceptionHandler.showErrorToast('Failed to load turf bookings');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Load upcoming bookings
  Future<void> loadUpcomingBookings() async {
    try {
      final bookings = await _bookingService.getUpcomingBookings(limit: 5);
      _upcomingBookings.assignAll(bookings);
    } catch (e) {
      // Silent fail for upcoming bookings
    }
  }

  /// Get booking by ID
  Future<void> getBookingById(String bookingId) async {
    try {
      _isLoading.value = true;

      final booking = await _bookingService.findById(bookingId);
      if (booking != null) {
        _selectedBooking.value = booking;
      }
    } catch (e) {
      ExceptionHandler.showErrorToast('Failed to load booking details');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Cancel booking
  Future<bool> cancelBooking(String bookingId, String cancelReason) async {
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
  Future<bool> deleteBooking(String bookingId) async {
    try {
      _isBookingLoading.value = true;

      final success = await _bookingService.deleteBooking(bookingId);

      if (success) {
        _removeBookingFromLists(bookingId);
        ExceptionHandler.showSuccessToast('Booking deleted successfully');
        return true;
      }

      return false;
    } catch (e) {
      ExceptionHandler.showErrorToast('Failed to delete booking');
      return false;
    } finally {
      _isBookingLoading.value = false;
    }
  }

  /// Apply filters
  void applyFilters({TurfBookingStatus? status, PaymentStatus? paymentStatus}) {
    _statusFilter.value = status;
    _paymentStatusFilter.value = paymentStatus;
    loadUserBookings(refresh: true);
  }

  /// Clear filters
  void clearFilters() {
    _statusFilter.value = null;
    _paymentStatusFilter.value = null;
    loadUserBookings(refresh: true);
  }

  /// Helper method to update booking in all lists
  void _updateBookingInLists(TurfBookingModel updatedBooking) {
    // Update in user bookings
    final userIndex = _userBookings.indexWhere(
      (b) => b.id == updatedBooking.id,
    );
    if (userIndex != -1) {
      _userBookings[userIndex] = updatedBooking;
    }

    // Update in turf owner bookings
    final ownerIndex = _turfOwnerBookings.indexWhere(
      (b) => b.id == updatedBooking.id,
    );
    if (ownerIndex != -1) {
      _turfOwnerBookings[ownerIndex] = updatedBooking;
    }

    // Update in upcoming bookings
    final upcomingIndex = _upcomingBookings.indexWhere(
      (b) => b.id == updatedBooking.id,
    );
    if (upcomingIndex != -1) {
      _upcomingBookings[upcomingIndex] = updatedBooking;
    }

    // Update selected booking
    if (_selectedBooking.value?.id == updatedBooking.id) {
      _selectedBooking.value = updatedBooking;
    }
  }

  /// Helper method to remove booking from all lists
  void _removeBookingFromLists(String bookingId) {
    _userBookings.removeWhere((booking) => booking.id == bookingId);
    _turfOwnerBookings.removeWhere((booking) => booking.id == bookingId);
    _upcomingBookings.removeWhere((booking) => booking.id == bookingId);

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
      return await _bookingService.findTurfBookings(
        turfId,
        status: status,
        paymentStatus: paymentStatus,
      );
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
    loadUserBookings(refresh: true);
    loadTurfOwnerBookings(refresh: true);
    loadUpcomingBookings();
  }

  @override
  void onClose() {
    super.onClose();
  }
}
