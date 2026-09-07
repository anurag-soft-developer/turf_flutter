import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/chat/chat_inbox_controller.dart';
import 'package:flutter_application_1/chat/chat_inbox_tile.dart';
import 'package:flutter_application_1/chat/chat_service.dart';
import 'package:flutter_application_1/chat/model/chat_models.dart';
import 'package:flutter_application_1/components/shared/user_avatar_app_bar_action.dart';
import 'package:flutter_application_1/core/components/scroll/floating_sliver_app_bar.dart';
import 'package:flutter_application_1/core/config/constants.dart';
import 'package:flutter_application_1/core/models/paginated_response.dart';
import 'package:flutter_application_1/core/query/query_keys.dart';
import 'package:flutter_application_1/core/query/query_retry.dart';
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

          Widget bodySliver;
          if (query.isLoading && items.isEmpty) {
            bodySliver = const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(_primary),
                ),
              ),
            );
          } else if (query.isError && items.isEmpty) {
            bodySliver = SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: TextButton(
                  onPressed: () => query.refetch(),
                  child: const Text('Could not load messages. Retry'),
                ),
              ),
            );
          } else if (items.isEmpty) {
            bodySliver = const SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 64,
                    color: _textSecondary,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No messages yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(AppColors.textColor),
                    ),
                  ),
                ],
              ),
            );
          } else {
            bodySliver = SliverPadding(
              padding: EdgeInsets.only(
                bottom: selecting && selectedKeys.isNotEmpty ? 88 : 0,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= items.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final item = items[index];
                    final selected = selectedKeys.contains(item.roomKey);
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Dismissible(
                          key: ValueKey(item.roomKey),
                          direction: selecting
                              ? DismissDirection.none
                              : DismissDirection.endToStart,
                          background: const _HideBackground(),
                          confirmDismiss: (_) => _confirmHide(context, item),
                          onDismissed: (_) {
                            unawaited(controller.hideThreads([item]));
                          },
                          child: ChatInboxTile(
                            item: item,
                            selected: selected,
                            isSelecting: selecting,
                            onTap: () => controller.onTap(item),
                            onLongPress: () => controller.onLongPress(item),
                          ),
                        ),
                        if (index < items.length - 1)
                          const Divider(height: 1),
                      ],
                    );
                  },
                  childCount:
                      items.length + (query.isFetchingNextPage ? 1 : 0),
                ),
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
                edgeOffset: floatingRefreshEdgeOffset(context),
                onRefresh: () async {
                  if (Get.isRegistered<QueryClient>()) {
                    await Get.find<QueryClient>().invalidateQueries(
                      queryKey: QueryKeys.chatInbox,
                    );
                  } else {
                    await query.refetch();
                  }
                },
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification.metrics.pixels >=
                        notification.metrics.maxScrollExtent - 200) {
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
                              ? '${selectedKeys.length} selected'
                              : 'Messages',
                        ),
                        automaticallyImplyLeading: false,
                        leading: selecting
                            ? IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: controller.exitSelection,
                              )
                            : const UserAvatarAppBarAction(),
                        actions: [
                          if (!selecting)
                            IconButton(
                              tooltip: 'Search',
                              icon: const Icon(Icons.search),
                              onPressed: () => Get.toNamed(
                                AppConstants.routes.chatInboxSearch,
                              ),
                            ),
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
                            ),
                        ],
                      ),
                      bodySliver,
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
