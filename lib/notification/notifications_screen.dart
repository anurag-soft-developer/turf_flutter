import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/components/scroll/floating_sliver_app_bar.dart';
import 'package:flutter_application_1/core/config/constants.dart';
import 'package:flutter_application_1/core/models/paginated_response.dart';
import 'package:flutter_application_1/core/query/query_keys.dart';
import 'package:flutter_application_1/core/query/query_retry.dart';
import 'package:flutter_application_1/notification/model/notification_model.dart';
import 'package:flutter_application_1/notification/notification_service.dart';
import 'package:flutter_application_1/notification/notifications_controller.dart';
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

    final query =
        useInfiniteQuery<PaginatedResponse<AppNotification>, Object, int>(
      QueryKeys.notifications,
      (ctx) async {
        final result = await service.list(
          page: ctx.pageParam,
          limit: _pageSize,
        );
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

    return GetBuilder<NotificationsController>(
      init: NotificationsController(),
      builder: (controller) {
        return Obx(() {
          final selecting = controller.isSelecting.value;
          final selectedIds = controller.selectedIds.toSet();
          final allSelected = controller.allSelected(items);
          final deleting = controller.isDeleting.value;

          return PopScope(
            canPop: !selecting,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) controller.exitSelection();
            },
            child: Scaffold(
              backgroundColor: const Color(AppColors.backgroundColor),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerFloat,
              floatingActionButton: selecting &&
                      selectedIds.isNotEmpty &&
                      !deleting
                  ? FloatingActionButton.extended(
                      onPressed: () => _confirmDelete(
                        context,
                        controller,
                        items,
                      ),
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      icon: const Icon(Icons.delete_outline),
                      label: Text(
                        selectedIds.length == 1
                            ? 'Delete'
                            : 'Delete (${selectedIds.length})',
                      ),
                    )
                  : null,
              body: RefreshIndicator(
                edgeOffset: floatingRefreshEdgeOffset(context),
                color: _primary,
                onRefresh: () => query.refetch(),
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
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      FloatingSliverAppBar(
                        title: Text(
                          selecting
                              ? '${selectedIds.length} selected'
                              : 'Notifications',
                        ),
                        leading: selecting
                            ? IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: controller.exitSelection,
                              )
                            : null,
                        actions: [
                          if (selecting && items.isNotEmpty)
                            IconButton(
                              tooltip:
                                  allSelected ? 'Deselect all' : 'Select all',
                              onPressed: () =>
                                  controller.toggleSelectAll(items),
                              icon: Icon(
                                allSelected
                                    ? Icons.check_box
                                    : Icons.check_box_outline_blank,
                              ),
                            )
                          else if (items.any((e) => !e.isRead))
                            TextButton(
                              onPressed: controller.markAllRead,
                              child: const Text(
                                'Mark all read',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                      _NotificationsBody(
                        query: query,
                        items: items,
                        isSelecting: selecting,
                        selectedIds: selectedIds,
                        onTap: controller.onTap,
                        onLongPress: controller.onLongPress,
                        onConfirmDismiss: (n) =>
                            _confirmDeleteOne(context, n),
                        onDismissed: (n) =>
                            controller.deleteIds({n.id}, items),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    NotificationsController controller,
    List<AppNotification> items,
  ) async {
    final count = controller.selectedIds.length;
    if (count == 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete notifications'),
        content: Text(
          count == 1
              ? 'Delete this notification?'
              : 'Delete $count notifications?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.deleteSelected(items);
    }
  }

  Future<bool> _confirmDeleteOne(
    BuildContext context,
    AppNotification n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete notification'),
        content: Text(
          n.title.isEmpty
              ? 'Delete this notification?'
              : 'Delete "${n.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }
}

class _NotificationsBody extends StatelessWidget {
  const _NotificationsBody({
    required this.query,
    required this.items,
    required this.isSelecting,
    required this.selectedIds,
    required this.onTap,
    required this.onLongPress,
    required this.onConfirmDismiss,
    required this.onDismissed,
  });

  final InfiniteQueryResult<PaginatedResponse<AppNotification>, Object, int>
      query;
  final List<AppNotification> items;
  final bool isSelecting;
  final Set<String> selectedIds;
  final Future<void> Function(AppNotification n) onTap;
  final void Function(AppNotification n) onLongPress;
  final Future<bool> Function(AppNotification n) onConfirmDismiss;
  final void Function(AppNotification n) onDismissed;

  static const Color _primary = Color(AppColors.primaryColor);
  static const Color _textSecondary = Color(AppColors.textSecondaryColor);

  @override
  Widget build(BuildContext context) {
    if (query.isLoading || (query.isFetching && items.isEmpty)) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_primary),
          ),
        ),
      );
    }

    if (query.isError && items.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
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
        ),
      );
    }

    if (items.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications_none_rounded,
                size: 64,
                color: _textSecondary,
              ),
              SizedBox(height: 16),
              Text(
                'No notifications yet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(AppColors.textColor),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'When something needs your attention, it will show up here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        0,
        8,
        0,
        isSelecting && selectedIds.isNotEmpty ? 88 : 8,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
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
            final selected = selectedIds.contains(n.id);
            return Dismissible(
              key: ValueKey(n.id),
              direction: isSelecting
                  ? DismissDirection.none
                  : DismissDirection.endToStart,
              background: const _DeleteBackground(),
              confirmDismiss: (_) => onConfirmDismiss(n),
              onDismissed: (_) => onDismissed(n),
              child: Material(
                color: selected
                    ? _primary.withValues(alpha: 0.12)
                    : n.isRead
                        ? const Color(AppColors.backgroundColor)
                        : _primary.withValues(alpha: 0.06),
                child: InkWell(
                  onTap: () => onTap(n),
                  onLongPress: () => onLongPress(n),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isSelecting)
                          Padding(
                            padding: const EdgeInsets.only(top: 2, right: 12),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: selected,
                                onChanged: (_) => onTap(n),
                                activeColor: _primary,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          )
                        else if (!n.isRead)
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
              ),
            );
          },
          childCount: items.length + (query.isFetchingNextPage ? 1 : 0),
        ),
      ),
    );
  }

  String? _formatTime(AppNotification n) {
    final dt = n.createdAtDate ?? n.updatedAtDate;
    if (dt == null) return null;
    return DateFormat('MMM d, y • h:mm a').format(dt.toLocal());
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.red.shade600,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(Icons.delete_outline, color: Colors.white),
          SizedBox(width: 8),
          Text(
            'Delete',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
