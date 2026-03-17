import 'package:flutter_application_1/config/env_config.dart';

class ApiConstants {
  static final String baseUrl = EnvConfig.baseApiUrl;

  // Endpoint groups
  static const auth = AuthEndpoints();
  static const user = UserEndpoints();

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
