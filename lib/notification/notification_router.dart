import 'package:flutter_application_1/core/config/constants.dart';
import 'package:flutter_application_1/core/models/user/user_model.dart';
import 'package:flutter_application_1/core/utils/app_snackbar.dart';
import 'package:flutter_application_1/match_up/match_challenges/match_challenge_detail_screen.dart';
import 'package:flutter_application_1/notification/model/notification_model.dart';
import 'package:flutter_application_1/notification/notification_navigation.dart';
import 'package:get/get.dart';

class NotificationRouter {
  NotificationRouter._();

  static Future<void> open(AppNotification notification) async {
    final kind = notification.kind;

    switch (notification.module) {
      case NotificationModule.turfBooking:
        return _openTurfBooking(notification, kind);
      case NotificationModule.matchmaking:
        return _openMatchmaking(notification);
      case NotificationModule.teams:
        return _openTeams(notification, kind);
      case NotificationModule.turfApproval:
        return _openTurfApproval(notification);
      case NotificationModule.connections:
        return _openConnections(notification, kind);
      case NotificationModule.eventBooking:
      case NotificationModule.withdrawals:
        return _fallback(notification.module, kind);
    }
  }

  static Future<void> _openTurfBooking(
    AppNotification notification,
    String? kind,
  ) async {
    final id = notification.bookingId;
    if (id == null || id.isEmpty) {
      return _fallback(notification.module, kind);
    }

    if (kind == 'booking_cancelled' ||
        kind == 'payment_failed' ||
        kind == 'booking_hold_expired') {
      await Get.toNamed(AppConstants.routes.myBookings);
      return;
    }

    await Get.toNamed(
      AppConstants.routes.bookingTicket,
      arguments: {'bookingId': id},
    );
  }

  static Future<void> _openMatchmaking(AppNotification notification) async {
    final id = notification.matchId;
    if (id == null || id.isEmpty) {
      return _fallback(notification.module, notification.kind);
    }

    await openMatchChallengeDetail(matchId: id);
  }

  static Future<void> _openTeams(
    AppNotification notification,
    String? kind,
  ) async {
    final teamId = notification.teamId;

    switch (kind) {
      case 'team_join_request':
        if (teamId == null || teamId.isEmpty) {
          return _fallback(notification.module, kind);
        }
        await Get.toNamed(
          AppConstants.routes.teamJoinRequests,
          arguments: {'teamId': teamId},
        );
        return;
      case 'team_join_accepted':
        if (teamId == null || teamId.isEmpty) {
          return _fallback(notification.module, kind);
        }
        await Get.toNamed(
          AppConstants.routes.teamProfile,
          arguments: {'teamId': teamId},
        );
        return;
      case 'team_join_rejected':
        await Get.toNamed(AppConstants.routes.myJoinRequests);
        return;
      default:
        if (teamId == null || teamId.isEmpty) {
          return _fallback(notification.module, kind);
        }
        await Get.toNamed(
          AppConstants.routes.teamProfile,
          arguments: {'teamId': teamId},
        );
    }
  }

  static Future<void> _openTurfApproval(AppNotification notification) async {
    final id = notification.turfId;
    if (id == null || id.isEmpty) {
      return _fallback(notification.module, notification.kind);
    }

    await Get.toNamed(
      AppConstants.routes.turfDetail,
      arguments: {'turfId': id},
    );
  }

  static Future<void> _openConnections(
    AppNotification notification,
    String? kind,
  ) async {
    if (kind == 'connection_request') {
      final userId = notification.actorUserId;
      if (userId == null || userId.isEmpty) {
        return _fallback(notification.module, kind);
      }
      await Get.toNamed(
        AppConstants.routes.teamMemberProfile,
        arguments: {'userId': userId},
      );
      return;
    }

    return _fallback(notification.module, kind);
  }

  static Future<void> _fallback(NotificationModule module, String? kind) async {
    switch (module) {
      case NotificationModule.eventBooking:
        AppSnackbar.info(
          title: 'Notifications',
          message: "Event bookings aren't available in the app yet.",
        );
        return;
      case NotificationModule.connections:
        AppSnackbar.info(
          title: 'Notifications',
          message: 'Connection details are not available here yet.',
        );
        await Get.toNamed(AppConstants.routes.profile);
        return;
      case NotificationModule.withdrawals:
        AppSnackbar.info(
          title: 'Notifications',
          message: "Withdrawal details aren't available here yet.",
        );
        await Get.toNamed(AppConstants.routes.settings);
        return;
      default:
        AppSnackbar.error(
          title: 'Notifications',
          message: "Couldn't open this notification.",
        );
    }
  }
}
