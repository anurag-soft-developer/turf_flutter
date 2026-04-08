import 'package:flutter_application_1/core/config/env_config.dart';

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

  final String login = '/login';
  final String signup = '/signup';
  final String forgotPassword = '/forgot-password';
  final String dashboard = '/dashboard';
  final String profile = '/profile';
  final String settings = '/settings';
  final String accessDenied = '/access-denied';
  final String turfList = '/turf-list';
  final String turfDetail = '/turf-detail';
  final String manageTurf = '/manage-turf';
  final String myTurfs = '/my-turfs';
  final String createTurf = '/create-turf';
  final String editTurf = '/edit-turf';
  final String myBookings = '/my-bookings';
  final String turfReviews = '/turf-reviews';
  // final String turfBookings = '/turf-bookings';
  final String myTeams = '/my-teams';
  final String myTeam = '/my-team';
  final String teamsRanking = '/teams-ranking';
  final String addTeam = '/add-team';
  final String editTeam = '/edit-team';
  final String teamProfile = '/team-profile';
  final String teamMemberProfile = '/team-member-profile';
  final String editProfile = '/edit-profile';
  final String matchUp = '/match-up';
  final String playerRanking = '/player-ranking';
}

class StorageKeys {
  const StorageKeys();

  final String userToken = 'user_token';
  final String userData = 'user_data';
  final String isLoggedIn = 'is_logged_in';
}

class ErrorMessages {
  const ErrorMessages();

  final String network = 'Network error occurred';
  final String unknown = 'An unknown error occurred';
  final String authentication = 'Authentication failed';
  final String invalidCredentials = 'Invalid credentials';
  final String userNotFound = 'User not found';
  final String weakPassword = 'Password is too weak';
  final String emailAlreadyExists = 'Email already exists';
  final String invalidEmail = 'Invalid email format';
}

class SuccessMessages {
  const SuccessMessages();

  final String login = 'Login successful';
  final String signup = 'Account created successfully';
  final String logout = 'Logged out successfully';
  final String profileUpdate = 'Profile updated successfully';
  final String otpSent = 'OTP sent to your email';
  final String passwordReset = 'Password reset successfully';
}

class OtpConstants {
  const OtpConstants();

  final int length = 6;
  final int timeoutSeconds = 300; // 5 minutes
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
  static const int dividerColor = 0xFFD7D8DA;
}
