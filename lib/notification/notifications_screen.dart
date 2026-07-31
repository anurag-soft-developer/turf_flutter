import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/config/constants.dart';
import 'package:flutter_application_1/core/models/paginated_response.dart';
import 'package:flutter_application_1/core/models/user/user_model.dart';
import 'package:flutter_application_1/core/query/query_keys.dart';
import '../core/query/query_retry.dart';
import 'package:flutter_application_1/core/utils/app_snackbar.dart';
import 'package:flutter_application_1/dashboard/player/player_dashboard_controller.dart';
import 'package:flutter_application_1/notification/model/notification_model.dart';
import 'package:flutter_application_1/notification/notification_router.dart';
import 'package:flutter_application_1/notification/notification_service.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends HookWidget {
  const NotificationsScreen({super.key});

  static const Color _primary = Color(AppColors.primaryColor);
  static const int _pageSize = 20;

  @override
  Widget build(BuildContext context) {
    final service = useMemoized(NotificationService.new);
    final tappingId = useState<String?>(null);

    final query =
        useInfiniteQuery<PaginatedResponse<AppNotification>, Object, int>(
      QueryKeys.notifications,
      (ctx) async {
        final result = await service.list(page: ctx.pageParam, limit: _pageSize);
        return result ?? EmptyPaginatedResponse<AppNotification>();
      },
      initialPageParam: 1,
      retry: noRetry,
      nextPageParamBuilder: (data) {
        final last = data.pages.isNotEmpty ? data.pages.last : null;
        if (last == null || !last.hasNextPage) return null;
        return last.page + 1;
      },
    );

    final items = query.data?.pages.expand((p) => p.data).toList() ??
        const <AppNotification>[];

    Future<void> invalidateNotifications() async {
      if (!Get.isRegistered<QueryClient>()) {
        await query.refetch();
        return;
      }
      await Get.find<QueryClient>().invalidateQueries(
        queryKey: QueryKeys.notifications,
      );
    }

    void patchNotificationInCache(AppNotification updated) {
      if (!Get.isRegistered<QueryClient>()) return;
      Get.find<QueryClient>().setQueryData<
          InfiniteData<PaginatedResponse<AppNotification>, int>,
          Object>(
        QueryKeys.notifications,
        (previous) {
          if (previous == null) return null;
          return InfiniteData(
            [
              for (final page in previous.pages)
                page.copyWith(
                  data: [
                    for (final n in page.data)
                      if (n.id == updated.id) updated else n,
                  ],
                ),
            ],
            previous.pageParams,
          );
        },
      );
    }

    void adjustDashboardUnread(void Function(PlayerDashboardController c) fn) {
      if (!Get.isRegistered<PlayerDashboardController>()) return;
      fn(Get.find<PlayerDashboardController>());
    }

    void markAllReadInCache() {
      if (!Get.isRegistered<QueryClient>()) return;
      final now = DateTime.now().toUtc().toIso8601String();
      Get.find<QueryClient>().setQueryData<
          InfiniteData<PaginatedResponse<AppNotification>, int>,
          Object>(
        QueryKeys.notifications,
        (previous) {
          if (previous == null) return null;
          return InfiniteData(
            [
              for (final page in previous.pages)
                page.copyWith(
                  data: [
                    for (final n in page.data)
                      if (n.isRead)
                        n
                      else
                        AppNotification(
                          id: n.id,
                          recipientUserId: n.recipientUserId,
                          module: n.module,
                          title: n.title,
                          body: n.body,
                          data: n.data,
                          sourceType: n.sourceType,
                          sourceId: n.sourceId,
                          readAt: now,
                          createdAt: n.createdAt,
                          updatedAt: n.updatedAt,
                        ),
                  ],
                ),
            ],
            previous.pageParams,
          );
        },
      );
    }

    Future<void> onTap(AppNotification n) async {
      if (tappingId.value == n.id) return;
      tappingId.value = n.id;

      try {
        if (!n.isRead) {
          final optimistic = AppNotification(
            id: n.id,
            recipientUserId: n.recipientUserId,
            module: n.module,
            title: n.title,
            body: n.body,
            data: n.data,
            sourceType: n.sourceType,
            sourceId: n.sourceId,
            readAt: DateTime.now().toUtc().toIso8601String(),
            createdAt: n.createdAt,
            updatedAt: n.updatedAt,
          );
          patchNotificationInCache(optimistic);
          adjustDashboardUnread((c) => c.decrementUnreadNotificationCount());

          final updated = await service.markRead(n.id);
          if (updated != null) {
            patchNotificationInCache(updated);
          } else {
            adjustDashboardUnread((c) => c.unreadNotificationCount.value++);
            await invalidateNotifications();
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
      markAllReadInCache();
      adjustDashboardUnread((c) => c.clearUnreadNotificationCount());
      final res = await service.markAllRead();
      if (res != null) {
        await invalidateNotifications();
        AppSnackbar.success(
          title: 'Notifications',
          message: 'Marked ${res.updatedCount} as read.',
        );
      } else {
        adjustDashboardUnread(
          (c) => c.unreadNotificationCount.value = previousUnread,
        );
        await invalidateNotifications();
        AppSnackbar.error(
          title: 'Notifications',
          message: 'Could not mark all as read.',
        );
      }
    }

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (items.any((e) => !e.isRead))
            TextButton(
              onPressed: markAllRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _NotificationsBody(
        query: query,
        items: items,
        onRefresh: () => query.refetch(),
        onTap: onTap,
      ),
    );
  }
}

class _NotificationsBody extends StatelessWidget {
  const _NotificationsBody({
    required this.query,
    required this.items,
    required this.onRefresh,
    required this.onTap,
  });

  final InfiniteQueryResult<PaginatedResponse<AppNotification>, Object, int>
      query;
  final List<AppNotification> items;
  final Future<void> Function() onRefresh;
  final Future<void> Function(AppNotification n) onTap;

  static const Color _primary = Color(AppColors.primaryColor);
  static const Color _textSecondary = Color(AppColors.textSecondaryColor);

  @override
  Widget build(BuildContext context) {
    if (query.isLoading || (query.isFetching && items.isEmpty)) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_primary),
        ),
      );
    }

    if (query.isError && items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: _textSecondary),
              const SizedBox(height: 16),
              Text(
                'Could not load notifications',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '${query.error}',
                style: const TextStyle(color: _textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => query.refetch(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (items.isEmpty) {
      return RefreshIndicator(
        color: _primary,
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Icon(
              Icons.notifications_none_rounded,
              size: 64,
              color: _textSecondary,
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                'No notifications yet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(AppColors.textColor),
                ),
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'When something needs your attention, it will show up here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _textSecondary, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _primary,
      onRefresh: onRefresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.pixels >=
              notification.metrics.maxScrollExtent - 240) {
            if (query.hasNextPage && !query.isFetchingNextPage) {
              query.fetchNextPage();
            }
          }
          return false;
        },
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: items.length + (query.isFetchingNextPage ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= items.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }
            final n = items[index];
            final timeStr = _formatTime(n);
            return Material(
              color: n.isRead
                  ? Colors.transparent
                  : _primary.withValues(alpha: 0.06),
              child: InkWell(
                onTap: () => onTap(n),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!n.isRead)
                        Padding(
                          padding: const EdgeInsets.only(top: 6, right: 10),
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: _primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _moduleLabel(n.module),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              n.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: n.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                                color: const Color(AppColors.textColor),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              n.body,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.35,
                                color: _textSecondary,
                              ),
                            ),
                            if (timeStr != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                timeStr,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _moduleLabel(NotificationModule m) {
    return switch (m) {
      NotificationModule.turfBooking => 'Turf booking',
      NotificationModule.matchmaking => 'Matchmaking',
      NotificationModule.eventBooking => 'Event booking',
      NotificationModule.teams => 'Teams',
      NotificationModule.connections => 'Connections',
      NotificationModule.withdrawals => 'Withdrawals',
      NotificationModule.turfApproval => 'Turf approval',
    };
  }

  String? _formatTime(AppNotification n) {
    final dt = n.createdAtDate ?? n.updatedAtDate;
    if (dt == null) return null;
    return DateFormat('MMM d, y • h:mm a').format(dt.toLocal());
  }
}
