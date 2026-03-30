import 'package:flutter_application_1/settings/settings_controller.dart';

import '../turf_booking/model/turf_booking_model.dart';
import '../core/models/paginated_response.dart';
import '../core/config/api_constants.dart';
import 'api_service.dart';

class TurfBookingService {
  static final TurfBookingService _instance = TurfBookingService._internal();
  factory TurfBookingService() => _instance;
  TurfBookingService._internal();

  final ApiService _apiService = ApiService();

  /// Create a new turf booking
  Future<TurfBookingModel?> createBooking(
    CreateTurfBookingRequest request,
  ) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.turfBooking.create,
      data: request.toJson(),
    );

    if (response == null) {
      return null;
    }

    final booking = TurfBookingModel.fromJson(response);
    return booking;
  }

  /// Get all bookings with optional filters
  // Future<List<TurfBookingModel>> findAll({
  //   String? turf,
  //   String? bookedBy,
  //   TurfBookingStatus? status,
  //   PaymentStatus? paymentStatus,
  //   String? startDate,
  //   String? endDate,
  //   int page = 1,
  //   int limit = 10,
  //   String sortBy = 'createdAt',
  //   String sortOrder = 'desc',
  // }) async {
  //   final queryParams = <String, dynamic>{};

  //   if (turf != null) queryParams['turf'] = turf;
  //   if (bookedBy != null) queryParams['bookedBy'] = bookedBy;
  //   if (status != null) {
  //     queryParams['status'] = status.toString().split('.').last;
  //   }
  //   if (paymentStatus != null) {
  //     queryParams['paymentStatus'] = paymentStatus.toString().split('.').last;
  //   }
  //   if (startDate != null) queryParams['startDate'] = startDate;
  //   if (endDate != null) queryParams['endDate'] = endDate;
  //   queryParams['page'] = page.toString();
  //   queryParams['limit'] = limit.toString();
  //   queryParams['sortBy'] = sortBy;
  //   queryParams['sortOrder'] = sortOrder;

  //   final response = await _apiService.get<List<dynamic>>(
  //     ApiConstants.turfBooking.bookings,
  //     queryParameters: queryParams,
  //   );

  //   if (response == null) {
  //     return [];
  //   }

  //   final bookings = response
  //       .map(
  //         (bookingJson) =>
  //             TurfBookingModel.fromJson(bookingJson as Map<String, dynamic>),
  //       )
  //       .toList();

  //   return bookings;
  // }

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

  /// Get bookings for turfs owned by current user
  // Future<PaginatedResponse<TurfBookingModel>?> findTurfOwnerBookings({
  //   String? turf,
  //   TurfBookingStatus? status,
  //   PaymentStatus? paymentStatus,
  //   String? startDate,
  //   String? endDate,
  //   int page = 1,
  //   int limit = 10,
  //   String sortBy = 'createdAt',
  //   String sortOrder = 'desc',
  // }) async {
  //   final queryParams = <String, dynamic>{};

  //   if (turf != null) queryParams['turf'] = turf;
  //   if (status != null) {
  //     queryParams['status'] = status.toString().split('.').last;
  //   }
  //   if (paymentStatus != null) {
  //     queryParams['paymentStatus'] = paymentStatus.toString().split('.').last;
  //   }
  //   if (startDate != null) queryParams['startDate'] = startDate;
  //   if (endDate != null) queryParams['endDate'] = endDate;
  //   queryParams['page'] = page.toString();
  //   queryParams['limit'] = limit.toString();
  //   queryParams['sortBy'] = sortBy;
  //   queryParams['sortOrder'] = sortOrder;

  //   final response = await _apiService.get<Map<String, dynamic>>(
  //     ApiConstants.turfBooking.myTurfBookings,
  //     queryParameters: queryParams,
  //   );

  //   if (response == null) {
  //     return null;
  //   }

  //   return PaginatedResponse.fromJson(
  //     response,
  //     (json) => TurfBookingModel.fromJson(json),
  //   );
  // }

  /// Get bookings for a specific turf
  // Future<PaginatedResponse<TurfBookingModel>?> findTurfBookings(
  //   String turfId, {
  //   TurfBookingStatus? status,
  //   PaymentStatus? paymentStatus,
  //   String? startDate,
  //   String? endDate,
  //   int page = 1,
  //   int limit = 10,
  //   String sortBy = 'createdAt',
  //   String sortOrder = 'desc',
  // }) async {
  //   final queryParams = <String, dynamic>{};

  //   if (status != null) {
  //     queryParams['status'] = status.toString().split('.').last;
  //   }
  //   if (paymentStatus != null) {
  //     queryParams['paymentStatus'] = paymentStatus.toString().split('.').last;
  //   }
  //   if (startDate != null) queryParams['startDate'] = startDate;
  //   if (endDate != null) queryParams['endDate'] = endDate;
  //   queryParams['page'] = page.toString();
  //   queryParams['limit'] = limit.toString();
  //   queryParams['sortBy'] = sortBy;
  //   queryParams['sortOrder'] = sortOrder;

  //   final response = await _apiService.get<Map<String, dynamic>>(
  //     ApiConstants.turfBooking.turfBookings(turfId),
  //     queryParameters: queryParams,
  //   );

  //   if (response == null) {
  //     return null;
  //   }

  //   return PaginatedResponse.fromJson(
  //     response,
  //     (json) => TurfBookingModel.fromJson(json),
  //   );
  // }

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

  /// Delete a booking
  // Future<bool> deleteBooking(String bookingId) async {
  //   final response = await _apiService.delete(
  //     ApiConstants.turfBooking.bookingById(bookingId),
  //   );
  //   return response != null;
  // }

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

  /// Get upcoming bookings for current user
  // Future<List<TurfBookingModel>> getUpcomingBookings({int limit = 10}) async {
  //   final now = DateTime.now();
  //   final startDate = now.toIso8601String();

  //   final response = await findBookings(
  //     startDate: startDate,
  //     status: [TurfBookingStatus.confirmed],
  //     limit: limit,
  //     sortBy: 'timeSlots.0.startTime', // Sort by first time slot start time
  //     sortOrder: 'asc',
  //   );

  //   return response?.data ?? [];
  // }

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

  /// Get today's bookings for a specific turf
  // Future<List<TurfBookingModel>> getTodaysBookings(String turfId) async {
  //   final today = DateTime.now();
  //   final startOfDay = DateTime(today.year, today.month, today.day);
  //   final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

  //   final response = await findTurfBookings(
  //     turfId,
  //     startDate: startOfDay.toIso8601String(),
  //     endDate: endOfDay.toIso8601String(),
  //     sortBy: 'timeSlots.0.startTime', // Sort by first time slot start time
  //     sortOrder: 'asc',
  //   );

  //   return response?.data ?? [];
  // }

  // /// Get weekly bookings for a specific turf
  // Future<List<TurfBookingModel>> getWeeklyBookings(String turfId) async {
  //   final today = DateTime.now();
  //   final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
  //   final endOfWeek = startOfWeek.add(const Duration(days: 6));

  //   final response = await findTurfBookings(
  //     turfId,
  //     startDate: startOfWeek.toIso8601String(),
  //     endDate: endOfWeek.toIso8601String(),
  //     sortBy: 'timeSlots.0.startTime', // Sort by first time slot start time
  //     sortOrder: 'asc',
  //   );

  //   return response?.data ?? [];
  // }
}
