import 'package:flutter_application_1/config/env_config.dart';

class AppConstants {
  static final String appName = EnvConfig.appName;

  // Route Names
  static const routes = Routes();

  // Storage Keys
  static const storageKeys = StorageKeys();

  // Error Messages
  static const errorMessages = ErrorMessages();

  // Success Messages
  static const successMessages = SuccessMessages();

  // OTP Constants
  static const otp = OtpConstants();
}

class Routes {
  const Routes();

  String get login => '/login';
  String get signup => '/signup';
  String get forgotPassword => '/forgot-password';
  String get dashboard => '/dashboard';
  String get profile => '/profile';
  String get settings => '/settings';
}

class StorageKeys {
  const StorageKeys();

  String get userToken => 'user_token';
  String get userData => 'user_data';
  String get isLoggedIn => 'is_logged_in';
}

class ErrorMessages {
  const ErrorMessages();

  String get network => 'Network error occurred';
  String get unknown => 'An unknown error occurred';
  String get authentication => 'Authentication failed';
  String get invalidCredentials => 'Invalid credentials';
  String get userNotFound => 'User not found';
  String get weakPassword => 'Password is too weak';
  String get emailAlreadyExists => 'Email already exists';
  String get invalidEmail => 'Invalid email format';
}

class SuccessMessages {
  const SuccessMessages();

  String get login => 'Login successful';
  String get signup => 'Account created successfully';
  String get logout => 'Logged out successfully';
  String get profileUpdate => 'Profile updated successfully';
  String get otpSent => 'OTP sent to your email';
  String get passwordReset => 'Password reset successfully';
}

class OtpConstants {
  const OtpConstants();

  int get length => 6;
  int get timeoutSeconds => 300; // 5 minutes
}

class AppColors {
  static const int primaryColor = 0xFF6366F1;
  static const int secondaryColor = 0xFF8B5CF6;
  static const int accentColor = 0xFFF59E0B;
  static const int backgroundColor = 0xFFF9FAFB;
  static const int surfaceColor = 0xFFFFFFFF;
  static const int errorColor = 0xFFEF4444;
  static const int successColor = 0xFF10B981;
  static const int textColor = 0xFF111827;
  static const int textSecondaryColor = 0xFF6B7280;
}
