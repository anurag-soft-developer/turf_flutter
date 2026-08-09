import 'package:get/get.dart';

/// Dashboard-scoped UI state. Location readiness lives on [SettingsController].
class PlayerDashboardController extends GetxController {
  /// Unread inbox count from the latest player dashboard payload.
  final RxInt unreadNotificationCount = 0.obs;

  void decrementUnreadNotificationCount([int by = 1]) {
    if (by <= 0) return;
    final next = unreadNotificationCount.value - by;
    unreadNotificationCount.value = next < 0 ? 0 : next;
  }

  void incrementUnreadNotificationCount([int by = 1]) {
    if (by <= 0) return;
    unreadNotificationCount.value += by;
  }

  void clearUnreadNotificationCount() {
    unreadNotificationCount.value = 0;
  }
}
