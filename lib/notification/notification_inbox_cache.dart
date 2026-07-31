import 'package:flutter_application_1/core/models/paginated_response.dart';
import 'package:flutter_application_1/core/models/user/user_model.dart';
import 'package:flutter_application_1/core/query/query_keys.dart';
import 'package:flutter_application_1/dashboard/player/player_dashboard_controller.dart';
import 'package:flutter_application_1/notification/model/notification_model.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

/// Helpers to keep the notifications infinite-query cache in sync with
/// realtime socket / push events.
class NotificationInboxCache {
  NotificationInboxCache._();

  static QueryClient? get _client {
    if (!Get.isRegistered<QueryClient>()) return null;
    return Get.find<QueryClient>();
  }

  /// Prepends [notification] to page 1 of the inbox list (dedupes by id).
  /// Increments the dashboard unread badge when a new unread item is inserted.
  static void prepend(AppNotification notification) {
    var didInsert = false;
    final client = _client;

    if (client == null) {
      didInsert = true;
    } else {
      client.setQueryData<
          InfiniteData<PaginatedResponse<AppNotification>, int>,
          Object>(
        QueryKeys.notifications,
        (previous) {
          if (previous == null || previous.pages.isEmpty) {
            didInsert = true;
            return InfiniteData(
              [
                PaginatedResponse<AppNotification>(
                  data: [notification],
                  totalDocuments: 1,
                  page: 1,
                  limit: 20,
                  totalPages: 1,
                ),
              ],
              [1],
            );
          }

          final first = previous.pages.first;
          if (first.data.any((n) => n.id == notification.id)) {
            return previous;
          }

          didInsert = true;
          final updatedFirst = first.copyWith(
            data: [notification, ...first.data],
            totalDocuments: first.totalDocuments + 1,
          );

          return InfiniteData(
            [updatedFirst, ...previous.pages.skip(1)],
            previous.pageParams,
          );
        },
      );
    }

    if (didInsert && !notification.isRead) {
      if (Get.isRegistered<PlayerDashboardController>()) {
        Get.find<PlayerDashboardController>()
            .incrementUnreadNotificationCount();
      }
    }
  }

  static Future<void> invalidate() async {
    final client = _client;
    if (client == null) return;
    await client.invalidateQueries(queryKey: QueryKeys.notifications);
  }

  /// Builds an [AppNotification] from a Socket.io `notification.push` payload.
  static AppNotification fromPushPayload(Map<String, dynamic> payload) {
    final notificationId =
        payload['notificationId']?.toString() ??
        payload['_id']?.toString() ??
        '';
    final moduleKey = payload['module']?.toString() ?? '';
    final module =
        notificationModuleFromApiString(moduleKey) ??
        NotificationModule.turfBooking;

    Map<String, dynamic>? data;
    final rawData = payload['data'];
    if (rawData is Map) {
      data = rawData.map((k, v) => MapEntry(k.toString(), v));
    }

    final recipient =
        payload['recipientUserId']?.toString() ??
        payload['userId']?.toString() ??
        '';

    return AppNotification(
      id: notificationId,
      recipientUserId: recipient,
      module: module,
      title: payload['title']?.toString() ?? '',
      body: payload['body']?.toString() ?? '',
      data: data,
      sourceId: data?['bookingId']?.toString() ??
          data?['matchId']?.toString() ??
          data?['turfId']?.toString(),
      createdAt: payload['createdAt']?.toString(),
    );
  }
}
