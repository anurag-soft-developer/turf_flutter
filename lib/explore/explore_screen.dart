import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../core/config/constants.dart';
import '../../core/query/query_keys.dart';
import '../../core/query/query_retry.dart';
import 'explore_service.dart';
import 'model/explore_category.dart';
import 'model/explore_filters.dart';
import 'model/explore_item.dart';
import 'widgets/explore_list.dart';

class ExploreScreen extends HookWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const filters = ExploreFilters.all;
    const category = ExploreCategory.all;

    final query = useInfiniteQuery<ExplorePaginatedResponse, Object, int>(
      QueryKeys.explore(
        mode: 'feed',
        category: category.apiValue,
        filterParts: filters.toQueryKeyParts(),
      ),
      (ctx) async {
        final result = await ExploreService().fetch(
          category: category,
          page: ctx.pageParam,
          limit: 20,
          filters: filters,
        );
        return result ??
            ExplorePaginatedResponse(
              data: const [],
              totalDocuments: 0,
              page: ctx.pageParam,
              limit: 20,
              totalPages: 0,
            );
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
        query.data?.pages.expand((p) => p.data).toList() ?? const <ExploreItem>[];

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: const Text('Explore'),
        actions: [
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search),
            onPressed: () => Get.toNamed(AppConstants.routes.exploreSearch),
          ),
        ],
      ),
      body: ExploreList(
        query: query,
        items: items,
        emptyTitle: 'Nothing to explore yet',
        emptySubtitle:
            'Matches, teams, and players will show up here as activity grows.',
      ),
    );
  }
}
