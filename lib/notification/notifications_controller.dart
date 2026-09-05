import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/core/utils/app_snackbar.dart';
import 'package:flutter_application_1/dashboard/player/player_dashboard_controller.dart';
import 'package:flutter_application_1/notification/model/notification_model.dart';
import 'package:flutter_application_1/notification/notification_inbox_cache.dart';
import 'package:flutter_application_1/notification/notification_router.dart';
import 'package:flutter_application_1/notification/notification_service.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

class NotificationsController extends GetxController {
  final NotificationService _service = NotificationService();

  final RxnString tappingId = RxnString();
  final RxBool isSelecting = false.obs;
  final selectedIds = <String>{}.obs;
  final RxBool isDeleting = false.obs;
  final _inFlightIds = <String>{};

  bool allSelected(List<AppNotification> items) =>
      items.isNotEmpty && selectedIds.length == items.length;

  void exitSelection() {
    isSelecting.value = false;
    selectedIds.clear();
  }

  void enterSelection(String id) {
    isSelecting.value = true;
    selectedIds
      ..clear()
      ..add(id);
  }

  void toggleSelected(String id) {
    if (selectedIds.contains(id)) {
      selectedIds.remove(id);
    } else {
      selectedIds.add(id);
    }
  }

  void toggleSelectAll(List<AppNotification> items) {
    if (allSelected(items)) {
      selectedIds.clear();
    } else {
      selectedIds.assignAll(items.map((e) => e.id));
      isSelecting.value = true;
    }
  }

  void onLongPress(AppNotification n) {
    if (isSelecting.value) {
      toggleSelected(n.id);
    } else {
      enterSelection(n.id);
    }
  }

  Future<void> onTap(AppNotification n) async {
    if (isSelecting.value) {
      toggleSelected(n.id);
      return;
    }
    if (tappingId.value == n.id) return;
    tappingId.value = n.id;

    try {
      if (!n.isRead) {
        final optimistic = n.copyWith(
          readAt: DateTime.now().toUtc().toIso8601String(),
        );
        NotificationInboxCache.patch(optimistic);
        _adjustDashboardUnread((c) => c.decrementUnreadNotificationCount());

        final updated = await _service.markRead(n.id);
        if (updated != null) {
          NotificationInboxCache.patch(updated);
        } else {
          _adjustDashboardUnread((c) => c.unreadNotificationCount.value++);
          await _invalidate();
        }
      }

      debugPrint('notification: ${n.toJson()}');
      await NotificationRouter.open(n);
    } finally {
      tappingId.value = null;
    }
  }

  Future<void> markAllRead() async {
    final previousUnread = Get.isRegistered<PlayerDashboardController>()
        ? Get.find<PlayerDashboardController>().unreadNotificationCount.value
        : 0;
    NotificationInboxCache.markAllRead();
    _adjustDashboardUnread((c) => c.clearUnreadNotificationCount());
    final res = await _service.markAllRead();
    if (res != null) {
      await _invalidate();
      AppSnackbar.success(
        title: 'Notifications',
        message: 'Marked ${res.updatedCount} as read.',
      );
    } else {
      _adjustDashboardUnread(
        (c) => c.unreadNotificationCount.value = previousUnread,
      );
      await _invalidate();
      AppSnackbar.error(
        title: 'Notifications',
        message: 'Could not mark all as read.',
      );
    }
  }

  Future<void> deleteSelected(List<AppNotification> items) async {
    await deleteIds(selectedIds.toSet(), items);
  }

  Future<void> deleteIds(Set<String> ids, List<AppNotification> items) async {
    final toDelete = ids.where((id) => !_inFlightIds.contains(id)).toSet();
    if (toDelete.isEmpty) return;

    final unreadDeleted =
        items.where((n) => toDelete.contains(n.id) && !n.isRead).length;
    final previousUnread = Get.isRegistered<PlayerDashboardController>()
        ? Get.find<PlayerDashboardController>().unreadNotificationCount.value
        : 0;

    _inFlightIds.addAll(toDelete);
    isDeleting.value = true;
    NotificationInboxCache.removeIds(toDelete);
    if (unreadDeleted > 0) {
      _adjustDashboardUnread(
        (c) => c.decrementUnreadNotificationCount(unreadDeleted),
      );
    }
    selectedIds.removeAll(toDelete);
    if (selectedIds.isEmpty) {
      isSelecting.value = false;
    }

    try {
      final res = await _service.delete(toDelete.toList());
      if (res != null && res.deleted) {
        AppSnackbar.success(
          title: 'Notifications',
          message: res.deletedCount <= 1
              ? 'Notification deleted.'
              : 'Deleted ${res.deletedCount} notifications.',
        );
        await _invalidate();
      } else {
        _adjustDashboardUnread(
          (c) => c.unreadNotificationCount.value = previousUnread,
        );
        await _invalidate();
        AppSnackbar.error(
          title: 'Notifications',
          message: 'Could not delete notifications.',
        );
      }
    } finally {
      _inFlightIds.removeAll(toDelete);
      isDeleting.value = _inFlightIds.isNotEmpty;
    }
  }

  void _adjustDashboardUnread(void Function(PlayerDashboardController c) fn) {
    if (!Get.isRegistered<PlayerDashboardController>()) return;
    fn(Get.find<PlayerDashboardController>());
  }

  Future<void> _invalidate() async {
    if (Get.isRegistered<QueryClient>()) {
      await NotificationInboxCache.invalidate();
      return;
    }
  }
}
