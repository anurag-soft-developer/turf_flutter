import 'package:flutter_application_1/notification/notification_socket_service.dart';
import 'package:flutter_application_1/notification/push_notification_service.dart';
import 'package:get/get.dart';

/// Owns push + socket lifecycle for an authenticated session.
class NotificationSessionController extends GetxController {
  static NotificationSessionController get instance => Get.find();

  final PushNotificationService _push = Get.find<PushNotificationService>();
  final NotificationSocketService _socket =
      Get.find<NotificationSocketService>();

  Future<void> startForSession() async {
    // Services are idempotent; always attempt so a prior soft-fail can recover.
    await Future.wait([
      _push.start(),
      _socket.start(),
    ]);
  }

  Future<void> stopSession() async {
    // Remove FCM device while auth token is still valid.
    await _push.stop();
    await _socket.stop();
  }
}
