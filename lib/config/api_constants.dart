import 'package:flutter_application_1/config/env_config.dart';

class ApiConstants {
  static final String baseUrl = EnvConfig.baseApiUrl;

  // Endpoint groups
  static const auth = AuthEndpoints();
  static const user = UserEndpoints();
  static const turfBooking = TurfBookingEndpoints();

  // Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Request timeout
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration connectTimeout = Duration(seconds: 5);
}

class AuthEndpoints {
  const AuthEndpoints();

  String get login => '/auth/login';
  String get register => '/auth/register';
  String get refreshToken => '/auth/refresh';
  String get logout => '/auth/logout';
  String get forgotPassword => '/auth/forgot-password';
  String get resetPassword => '/auth/reset-password';
  String get verifyEmail => '/auth/verify-email';
}

class UserEndpoints {
  const UserEndpoints();

  String get profile => '/users/profile';
  String get updateProfile => '/users/profile';
  String get changePassword => '/users/change-password';
  String get deleteAccount => '/users/delete';
}

class TurfBookingEndpoints {
  const TurfBookingEndpoints();

  String get bookings => '/turf-bookings';
  String get create => '/turf-bookings';
  String get myBookings => '/turf-bookings/my-bookings';
  String get myTurfBookings => '/turf-bookings/my-turf-bookings';
  String get checkAvailability => '/turf-bookings/check-availability';

  String bookingById(String id) => '/turf-bookings/$id';
  String turfBookings(String turfId) => '/turf-bookings/turf/$turfId';
}
