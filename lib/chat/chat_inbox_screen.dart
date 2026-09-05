import 'package:flutter/material.dart';
import 'package:flutter_application_1/chat/utils/chat_navigation.dart';
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

    Widget body;
    if (query.isLoading && items.isEmpty) {
      body = const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Color(AppColors.primaryColor),
          ),
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
      body = const Center(
        child: Text('No conversations yet. Start a team, match, or player chat.'),
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
            return _InboxTile(
              item: item,
              onTap: () => ChatNavigation.openThread(
                scope: item.scope,
                scopeId: item.scopeId,
                title: item.title,
                imageUrl: item.imageUrl,
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: const Text('Messages'),
      ),
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
    );
  }
}

class _InboxTile extends StatelessWidget {
  const _InboxTile({required this.item, required this.onTap});

  final ChatInboxItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.imageUrl;
    final timeLabel =
        item.lastMessageAt.isEmpty ? '' : timeAgo(item.lastMessageAt);
    final unread = item.unreadCount > 0;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: const Color(AppColors.primaryColor).withValues(
          alpha: 0.12,
        ),
        backgroundImage: imageUrl != null && imageUrl.isNotEmpty
            ? AppNetworkImage.provider(imageUrl)
            : null,
        child: imageUrl == null || imageUrl.isEmpty
            ? Icon(
                _iconForScope(item.scope),
                color: const Color(AppColors.primaryColor),
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
                color: const Color(AppColors.primaryColor),
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
