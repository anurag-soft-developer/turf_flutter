import 'package:flutter/material.dart';
import 'package:flutter_application_1/chat/chat_inbox_tile.dart';
import 'package:flutter_application_1/chat/chat_service.dart';
import 'package:flutter_application_1/chat/model/chat_models.dart';
import 'package:flutter_application_1/chat/utils/chat_navigation.dart';
import 'package:flutter_application_1/core/components/search/app_search_screen.dart';
import 'package:flutter_application_1/core/config/constants.dart';
import 'package:flutter_application_1/core/models/paginated_response.dart';
import 'package:flutter_application_1/core/query/query_keys.dart';
import 'package:flutter_application_1/core/query/query_retry.dart';
import 'package:flutter_application_1/core/services/search/search_history_store.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';

class ChatInboxSearchScreen extends StatelessWidget {
  const ChatInboxSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSearchScreen(
      historyScope: SearchHistoryScope.chat,
      hintText: 'Search conversations',
      resultsBuilder: (context, query) => _ChatInboxSearchResults(
        key: ValueKey('chat-inbox-search|$query'),
        query: query,
      ),
    );
  }
}

class _ChatInboxSearchResults extends HookWidget {
  const _ChatInboxSearchResults({
    super.key,
    required this.query,
  });

  static const Color _primary = Color(AppColors.primaryColor);
  static const Color _textSecondary = Color(AppColors.textSecondaryColor);
  static const int _pageSize = 20;

  final String query;

  @override
  Widget build(BuildContext context) {
    final service = useMemoized(ChatService.new);

    final searchQuery =
        useInfiniteQuery<PaginatedResponse<ChatInboxItem>, Object, int>(
      QueryKeys.chatInboxSearch(query),
      (ctx) async {
        final result = await service.listInbox(
          page: ctx.pageParam,
          limit: _pageSize,
          search: query,
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
        searchQuery.data?.pages.expand((page) => page.data).toList() ??
            const <ChatInboxItem>[];

    return RefreshIndicator(
      color: _primary,
      onRefresh: () => searchQuery.refetch(),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.pixels >=
              notification.metrics.maxScrollExtent - 200) {
            if (searchQuery.hasNextPage && !searchQuery.isFetchingNextPage) {
              searchQuery.fetchNextPage();
            }
          }
          return false;
        },
        child: _buildList(searchQuery, items),
      ),
    );
  }

  Widget _buildList(
    InfiniteQueryResult<PaginatedResponse<ChatInboxItem>, Object, int> result,
    List<ChatInboxItem> items,
  ) {
    if (items.isEmpty &&
        (result.isLoading || (result.isFetching && result.data == null))) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_primary),
            ),
          ),
        ],
      );
    }

    if (result.isError && items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Center(
            child: TextButton(
              onPressed: () => result.refetch(),
              child: const Text('Could not load conversations. Retry'),
            ),
          ),
        ],
      );
    }

    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 80),
          Icon(
            Icons.search_off_rounded,
            size: 52,
            color: _textSecondary,
          ),
          SizedBox(height: 20),
          Text(
            'No conversations found',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(AppColors.textColor),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try a different name.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: _textSecondary,
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: items.length + (result.isFetchingNextPage ? 1 : 0),
      separatorBuilder: (_, index) {
        if (index >= items.length - 1) return const SizedBox.shrink();
        return const Divider(height: 1);
      },
      itemBuilder: (context, index) {
        if (index >= items.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_primary),
              ),
            ),
          );
        }
        final item = items[index];
        return ChatInboxTile(
          item: item,
          onTap: () => ChatNavigation.openThread(
            scope: item.scope,
            scopeId: item.scopeId,
            title: item.title,
            imageUrl: item.imageUrl,
          ),
        );
      },
    );
  }
}
