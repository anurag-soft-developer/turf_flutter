import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/chat/chat_inbox_controller.dart';
import 'package:flutter_application_1/chat/chat_service.dart';
import 'package:flutter_application_1/chat/model/chat_models.dart';
import 'package:flutter_application_1/chat/model/chat_scope.dart';
import 'package:flutter_application_1/core/config/constants.dart';
import 'package:flutter_application_1/core/models/paginated_response.dart';
import 'package:flutter_application_1/core/query/query_keys.dart';
import 'package:flutter_application_1/core/query/query_retry.dart';
import 'package:flutter_application_1/core/utils/date_util.dart';
import 'package:flutter_application_1/components/shared/app_network_image.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

class ChatInboxScreen extends HookWidget {
  const ChatInboxScreen({super.key});

  static const Color _primary = Color(AppColors.primaryColor);
  static const Color _textSecondary = Color(AppColors.textSecondaryColor);
  static const int _pageSize = 20;

  @override
  Widget build(BuildContext context) {
    final service = useMemoized(ChatService.new);

    final query =
        useInfiniteQuery<PaginatedResponse<ChatInboxItem>, Object, int>(
      QueryKeys.chatInbox,
      (ctx) async {
        final result = await service.listInbox(
          page: ctx.pageParam,
          limit: _pageSize,
        );
        return result ?? EmptyPaginatedResponse<ChatInboxItem>();
      },
      initialPageParam: 1,
      retry: noRetry,
      nextPageParamBuilder: (data) {
        final last = data.pages.isNotEmpty ? data.pages.last : null;
        if (last == null || !last.hasNextPage) return null;
        return last.page + 1;
      },
    );

    final items =
        query.data?.pages.expand((page) => page.data).toList() ??
            const <ChatInboxItem>[];

    return GetBuilder<ChatInboxController>(
      init: ChatInboxController(),
      builder: (controller) {
        return Obx(() {
          final selecting = controller.isSelecting.value;
          final selectedKeys = controller.selectedKeys.toSet();
          final allSelected = controller.allSelected(items);
          final hiding = controller.isHiding.value;

          Widget body;
          if (query.isLoading && items.isEmpty) {
            body = const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_primary),
              ),
            );
          } else if (query.isError && items.isEmpty) {
            body = Center(
              child: TextButton(
                onPressed: () => query.refetch(),
                child: const Text('Could not load messages. Retry'),
              ),
            );
          } else if (items.isEmpty) {
            body = ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Center(
                  child: Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 64,
                    color: _textSecondary,
                  ),
                ),
                SizedBox(height: 16),
                Center(
                  child: Text(
                    'No messages yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(AppColors.textColor),
                    ),
                  ),
                ),
              ],
            );
          } else {
            body = NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification.metrics.pixels >=
                    notification.metrics.maxScrollExtent - 200) {
                  if (query.hasNextPage && !query.isFetchingNextPage) {
                    query.fetchNextPage();
                  }
                }
                return false;
              },
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(
                  bottom: selecting && selectedKeys.isNotEmpty ? 88 : 0,
                ),
                itemCount: items.length + (query.isFetchingNextPage ? 1 : 0),
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  if (index >= items.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final item = items[index];
                  final selected = selectedKeys.contains(item.roomKey);
                  return Dismissible(
                    key: ValueKey(item.roomKey),
                    direction: selecting
                        ? DismissDirection.none
                        : DismissDirection.endToStart,
                    background: const _HideBackground(),
                    confirmDismiss: (_) => _confirmHide(context, item),
                    onDismissed: (_) {
                      unawaited(controller.hideThreads([item]));
                    },
                    child: _InboxTile(
                      item: item,
                      selected: selected,
                      isSelecting: selecting,
                      onTap: () => controller.onTap(item),
                      onLongPress: () => controller.onLongPress(item),
                    ),
                  );
                },
              ),
            );
          }

          return PopScope(
            canPop: !selecting,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) controller.exitSelection();
            },
            child: Scaffold(
              backgroundColor: const Color(AppColors.backgroundColor),
              appBar: AppBar(
                title: Text(
                  selecting ? '${selectedKeys.length} selected' : 'Messages',
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
                      tooltip: allSelected ? 'Deselect all' : 'Select all',
                      onPressed: () => controller.toggleSelectAll(items),
                      icon: Icon(
                        allSelected
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                      ),
                    ),
                ],
              ),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerFloat,
              floatingActionButton: selecting &&
                      selectedKeys.isNotEmpty &&
                      !hiding
                  ? FloatingActionButton.extended(
                      onPressed: () => _confirmHideSelected(
                        context,
                        controller,
                        items,
                      ),
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      icon: const Icon(Icons.delete_outline),
                      label: Text(
                        selectedKeys.length == 1
                            ? 'Delete'
                            : 'Delete (${selectedKeys.length})',
                      ),
                    )
                  : null,
              body: RefreshIndicator(
                onRefresh: () async {
                  if (Get.isRegistered<QueryClient>()) {
                    await Get.find<QueryClient>().invalidateQueries(
                      queryKey: QueryKeys.chatInbox,
                    );
                  } else {
                    await query.refetch();
                  }
                },
                child: body,
              ),
            ),
          );
        });
      },
    );
  }

  Future<void> _confirmHideSelected(
    BuildContext context,
    ChatInboxController controller,
    List<ChatInboxItem> items,
  ) async {
    final count = controller.selectedKeys.length;
    if (count == 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete conversations'),
        content: Text(
          count == 1
              ? 'Remove this conversation from your inbox? New messages will show it again.'
              : 'Remove $count conversations from your inbox? New messages will show them again.',
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
      await controller.hideSelected(items);
    }
  }

  Future<bool> _confirmHide(BuildContext context, ChatInboxItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete conversation'),
        content: Text(
          'Remove "${item.title}" from your inbox? New messages will show it again.',
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

class _HideBackground extends StatelessWidget {
  const _HideBackground();

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

class _InboxTile extends StatelessWidget {
  const _InboxTile({
    required this.item,
    required this.selected,
    required this.isSelecting,
    required this.onTap,
    required this.onLongPress,
  });

  final ChatInboxItem item;
  final bool selected;
  final bool isSelecting;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.imageUrl;
    final timeLabel =
        item.lastMessageAt.isEmpty ? '' : timeAgo(item.lastMessageAt);
    final unread = item.unreadCount > 0;

    return Material(
      color: selected
          ? ChatInboxScreen._primary.withValues(alpha: 0.12)
          : const Color(AppColors.backgroundColor),
      child: ListTile(
        onTap: onTap,
        onLongPress: onLongPress,
        leading: isSelecting
            ? Checkbox(
                value: selected,
                onChanged: (_) => onTap(),
                activeColor: ChatInboxScreen._primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              )
            : CircleAvatar(
                backgroundColor: ChatInboxScreen._primary.withValues(
                  alpha: 0.12,
                ),
                backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                    ? AppNetworkImage.provider(imageUrl)
                    : null,
                child: imageUrl == null || imageUrl.isEmpty
                    ? Icon(
                        _iconForScope(item.scope),
                        color: ChatInboxScreen._primary,
                      )
                    : null,
              ),
        title: Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
            color: const Color(AppColors.textColor),
          ),
        ),
        subtitle: Text(
          item.lastMessageBody,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
            color: const Color(AppColors.textSecondaryColor),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (timeLabel.isNotEmpty)
              Text(
                timeLabel,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(AppColors.textSecondaryColor),
                ),
              ),
            if (unread) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: ChatInboxScreen._primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  item.unreadCount > 99 ? '99+' : '${item.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _iconForScope(ChatScope scope) {
    return switch (scope) {
      ChatScope.team => Icons.groups_outlined,
      ChatScope.match => Icons.sports_soccer_outlined,
      ChatScope.player => Icons.person_outline,
    };
  }
}
