import 'package:flutter_application_1/core/config/env_config.dart';

class ApiConstants {
  static final String baseUrl = EnvConfig.baseApiUrl;

  // Endpoint groups
  static const auth = AuthEndpoints();
  static const user = UserEndpoints();
  static const turfBooking = TurfBookingEndpoints();
  static const turfReview = TurfReviewEndpoints();
  static const team = TeamEndpoints();
  static const teamMember = TeamMemberEndpoints();
  static const teamMembershipSelf = TeamMembershipSelfEndpoints();

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
  String get verifyLoginOtp => '/auth/login/verify-otp';
  String get register => '/auth/register';
  String get refreshToken => '/auth/refresh';
  String get logout => '/auth/logout';
  String get forgotPassword => '/auth/forgot-password';
  String get resetPassword => '/auth/reset-password';
  String get changePassword => '/auth/change-password';
  String get verifyEmail => '/auth/verify-email';
  String get sendChangePasswordOtp => '/auth/change-password/send-otp';
  String get sendTwoFactorOtp => '/auth/2fa-setting/send-otp';
  String get updateTwoFactor => '/auth/2fa-setting';
}

class UserEndpoints {
  const UserEndpoints();

  String get profile => '/users/profile';
  String get updateProfile => '/users/profile';
  String get notificationSettings => '/users/notification-settings';
  String get publicProfiles => '/users/profiles';
  String publicProfileByIdentifier(String identifier) =>
      '/users/profile/$identifier';
}

class TurfBookingEndpoints {
  const TurfBookingEndpoints();

  String get bookings => '/turf-bookings';
  String get create => '/turf-bookings';
  String get playerBookings => '/turf-bookings/player-bookings';
  String get ownerBookings => '/turf-bookings/owner-bookings';
  String get checkAvailability => '/turf-bookings/check-availability';

  String bookingById(String id) => '/turf-bookings/$id';
  String turfBookings(String turfId) => '/turf-bookings/turf/$turfId';
}

class TurfReviewEndpoints {
  const TurfReviewEndpoints();

  String get base => '/turf-reviews';
  String get myReviews => '/turf-reviews/my-reviews';
  String turfReviews(String turfId) => '/turf-reviews/turf/$turfId';
  String turfReviewStats(String turfId) => '/turf-reviews/turf/$turfId/stats';
  String byId(String id) => '/turf-reviews/$id';
  String vote(String id) => '/turf-reviews/$id/vote';
  String report(String id) => '/turf-reviews/$id/report';
  String moderate(String id) => '/turf-reviews/$id/moderate';
}

class TeamEndpoints {
  const TeamEndpoints();

  String get base => '/teams';

  String byId(String id) => '/teams/$id';

  String promoteOwner(String teamId) => '/teams/$teamId/owners';

  String demoteOwner(String teamId, String userId) =>
      '/teams/$teamId/owners/$userId';
}

class TeamMemberEndpoints {
  const TeamMemberEndpoints();

  String membersBase(String teamId) => '/teams/$teamId/members';

  String join(String teamId) => '/teams/$teamId/members/join';

  String leave(String teamId) => '/teams/$teamId/members/leave';

  String member(String teamId, String membershipId) =>
      '/teams/$teamId/members/$membershipId';

  String accept(String teamId, String membershipId) =>
      '/teams/$teamId/members/$membershipId/accept';

  String reject(String teamId, String membershipId) =>
      '/teams/$teamId/members/$membershipId/reject';

  String suspend(String teamId, String membershipId) =>
      '/teams/$teamId/members/$membershipId/suspend';

  String unsuspend(String teamId, String membershipId) =>
      '/teams/$teamId/members/$membershipId/unsuspend';

  String removeUser(String teamId, String targetUserId) =>
      '/teams/$teamId/members/users/$targetUserId';
}

class TeamMembershipSelfEndpoints {
  const TeamMembershipSelfEndpoints();

  String get myMemberships => '/team-members/me';
}
