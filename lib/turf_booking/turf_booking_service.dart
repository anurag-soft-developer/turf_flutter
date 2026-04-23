import 'package:flutter_application_1/settings/settings_controller.dart';

import 'model/turf_booking_model.dart';
import '../core/models/paginated_response.dart';
import '../core/config/api_constants.dart';
import '../core/services/api_service.dart';

class TurfBookingService {
  static final TurfBookingService _instance = TurfBookingService._internal();
  factory TurfBookingService() => _instance;
  TurfBookingService._internal();

  final ApiService _apiService = ApiService();

  /// Create booking order (booking + Razorpay order details).
  Future<CreateBookingOrderResponse?> createBookingOrder(
    CreateTurfBookingRequest request,
  ) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.turfBooking.createOrder,
      data: request.toJson(),
    );

    if (response == null) {
      return null;
    }

    return CreateBookingOrderResponse.fromJson(response);
  }

  /// Verify Razorpay payment for a booking.
  Future<TurfBookingModel?> verifyBookingPayment(
    VerifyRazorpayPaymentRequest request,
  ) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.turfBooking.verifyPayment,
      data: request.toJson(),
    );

    if (response == null) {
      return null;
    }

    return TurfBookingModel.fromJson(response);
  }

  /// Get current user's bookings
  Future<PaginatedResponse<TurfBookingModel>?> findBookings(
    UserMode mode, {
    String? turf,
    List<TurfBookingStatus>? status,
    PaymentStatus? paymentStatus,
    String? startDate,
    String? endDate,
    int page = 1,
    int limit = 10,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    final queryParams = <String, dynamic>{};
    if (turf != null) queryParams['turf'] = turf;
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status
          .map((status) => status.toString().split('.').last)
          .join(',');
    }
    if (paymentStatus != null) {
      queryParams['paymentStatus'] = paymentStatus.toString().split('.').last;
    }
    if (startDate != null) queryParams['startDate'] = startDate;
    if (endDate != null) queryParams['endDate'] = endDate;
    queryParams['page'] = page.toString();
    queryParams['limit'] = limit.toString();
    queryParams['sortBy'] = sortBy;
    queryParams['sortOrder'] = sortOrder;

    final response = await _apiService.get<Map<String, dynamic>>(
      mode == UserMode.player
          ? ApiConstants.turfBooking.playerBookings
          : ApiConstants.turfBooking.ownerBookings,
      queryParameters: queryParams,
    );

    if (response == null) {
      return null;
    }

    return PaginatedResponse.fromJson(
      response,
      (json) => TurfBookingModel.fromJson(json),
    );
  }

  /// Hourly slots for a turf on a calendar day (availability, overlap, pricing).
  Future<List<TurfTimeSlotListing>> getTimeSlotsForDate(
    String turfId,
    DateTime date,
  ) async {
    final response = await _apiService.get<dynamic>(
      ApiConstants.turfBooking.turfTimeSlots(turfId),
      queryParameters: {'date': date.toString()},
    );

    if (response == null) {
      return [];
    }

    final List<dynamic> raw;
    if (response is List<dynamic>) {
      raw = response;
    } else if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is! List<dynamic>) {
        return [];
      }
      raw = data;
    } else {
      return [];
    }

    return raw
        .map((e) => TurfTimeSlotListing.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Check time slots availability for a turf
  Future<bool> checkTimeSlotsAvailability(
    CheckTurfAvailabilityRequest request,
  ) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.turfBooking.checkAvailability,
      data: request.toJson(),
    );

    if (response == null) {
      return false;
    }

    try {
      final availabilityResponse = TurfAvailabilityResponse.fromJson(response);
      return availabilityResponse.data.isAvailable;
    } catch (e) {
      // Fallback: try to parse directly if the response structure is different
      final isAvailable = response['data']?['isAvailable'] as bool?;
      return isAvailable ?? false;
    }
  }

  /// Get a specific booking by ID
  Future<TurfBookingModel?> findById(String bookingId) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiConstants.turfBooking.bookingById(bookingId),
    );

    if (response == null) {
      return null;
    }

    final booking = TurfBookingModel.fromJson(response);
    return booking;
  }

  /// Update a booking
  Future<TurfBookingModel?> updateBooking(
    String bookingId,
    UpdateTurfBookingRequest request,
  ) async {
    final response = await _apiService.patch<Map<String, dynamic>>(
      ApiConstants.turfBooking.bookingById(bookingId),
      data: request.toJson(),
    );

    if (response == null) {
      return null;
    }

    final updatedBooking = TurfBookingModel.fromJson(response);
    return updatedBooking;
  }

  /// Cancel a booking (convenient method)
  Future<TurfBookingModel?> cancelBooking(
    String bookingId,
    String? cancelReason,
  ) async {
    final request = UpdateTurfBookingRequest(
      status: TurfBookingStatus.cancelled,
      cancelReason: cancelReason,
    );

    return await updateBooking(bookingId, request);
  }

  /// Confirm a booking (convenient method for turf owners)
  Future<TurfBookingModel?> confirmBooking(String bookingId) async {
    final request = UpdateTurfBookingRequest(
      status: TurfBookingStatus.confirmed,
    );

    return await updateBooking(bookingId, request);
  }

  /// Complete a booking (convenient method)
  Future<TurfBookingModel?> completeBooking(String bookingId) async {
    final request = UpdateTurfBookingRequest(
      status: TurfBookingStatus.completed,
    );

    return await updateBooking(bookingId, request);
  }

  /// Update payment status (convenient method)
  Future<TurfBookingModel?> updatePaymentStatus(
    String bookingId,
    PaymentStatus paymentStatus, {
    String? paymentId,
  }) async {
    final request = UpdateTurfBookingRequest(
      paymentStatus: paymentStatus,
      paymentId: paymentId,
    );

    return await updateBooking(bookingId, request);
  }

  /// Get booking history for current user
  Future<List<TurfBookingModel>> getBookingHistory(
    UserMode mode, {
    int page = 1,
    int limit = 10,
  }) async {
    final response = await findBookings(
      mode,
      page: page,
      limit: limit,
      sortBy: 'createdAt',
      sortOrder: 'desc',
    );

    return response?.data ?? [];
  }
}
