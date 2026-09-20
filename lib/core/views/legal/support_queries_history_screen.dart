import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../../components/support/support_query_list_tile.dart';
import '../../../core/models/paginated_response.dart';
import '../../../support/model/support_query_model.dart';
import '../../../support/support_service.dart';
import '../../components/app_bar/app_bar_background.dart';
import '../../config/constants.dart';
import '../../query/query_keys.dart';
import '../../query/query_retry.dart';

class SupportQueriesHistoryScreen extends HookWidget {
  const SupportQueriesHistoryScreen({super.key});

  static const int _pageSize = 20;

  @override
  Widget build(BuildContext context) {
    final service = useMemoized(SupportService.new);

    final query =
        useInfiniteQuery<PaginatedResponse<SupportQueryModel>, Object, int>(
      QueryKeys.supportQueriesHistoryPrefix,
      (ctx) async {
        final result = await service.listMine(
          page: ctx.pageParam,
          limit: _pageSize,
        );
        return result ?? EmptyPaginatedResponse<SupportQueryModel>();
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
            const <SupportQueryModel>[];

    void openDetail(String id) {
      Get.toNamed(AppConstants.routes.supportQueryDetail(id));
    }

    Widget body;
    if (query.isLoading && items.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (query.isError && items.isEmpty) {
      body = Center(
        child: TextButton(
          onPressed: () => query.refetch(),
          child: const Text('Could not load queries. Retry'),
        ),
      );
    } else if (items.isEmpty) {
      body = const Center(
        child: Text(
          'No support queries yet',
          style: TextStyle(color: Color(AppColors.textSecondaryColor)),
        ),
      );
    } else {
      body = NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.pixels >=
                  notification.metrics.maxScrollExtent - 200 &&
              query.hasNextPage &&
              !query.isFetchingNextPage) {
            query.fetchNextPage();
          }
          return false;
        },
        child: RefreshIndicator(
          onRefresh: () async => query.refetch(),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length + (query.isFetchingNextPage ? 1 : 0),
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: Color(AppColors.dividerColor),
            ),
            itemBuilder: (context, index) {
              if (index >= items.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final item = items[index];
              return SupportQueryListTile(
                query: item,
                onTap: () => openDetail(item.id),
              );
            },
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: const AppAppBar(title: Text('My queries')),
      body: body,
    );
  }
}
