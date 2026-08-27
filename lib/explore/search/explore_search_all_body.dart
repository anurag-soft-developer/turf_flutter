import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../components/match_history/match_history_placeholders.dart';
import '../../core/config/constants.dart';
import '../../core/models/location_model.dart';
import '../../core/query/query_keys.dart';
import '../../core/query/query_retry.dart';
import '../../engagement/engagement_service.dart';
import '../explore_service.dart';
import '../model/explore_category.dart';
import '../model/explore_filters.dart';
import '../model/explore_item.dart';
import '../widgets/explore_item_tile.dart';
import 'explore_search_category_tabs.dart';

class ExploreSearchAllBody extends HookWidget {
  const ExploreSearchAllBody({
    super.key,
    required this.q,
    required this.filters,
    required this.onViewMore,
    this.location,
  });

  final String q;
  final ExploreFilters filters;
  final LocationModel? location;
  final ValueChanged<ExploreCategory> onViewMore;

  static const _sectionOrder = <ExploreCategory>[
    ExploreCategory.post,
    ExploreCategory.match,
    ExploreCategory.team,
    ExploreCategory.player,
  ];

  @override
  Widget build(BuildContext context) {
    final query = useInfiniteQuery<ExplorePaginatedResponse, Object, int>(
      QueryKeys.explore(
        mode: 'search',
        category: ExploreCategory.all.apiValue,
        q: q,
        filterParts: filters.toQueryKeyParts(),
        lat: location?.latitude,
        lng: location?.longitude,
      ),
      (ctx) async {
        final result = await ExploreService().fetch(
          q: q,
          category: ExploreCategory.all,
          page: ctx.pageParam,
          limit: 20,
          filters: filters,
          location: location,
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

    final items = _dedupeItems(
      query.data?.pages.expand((p) => p.data).toList() ?? const <ExploreItem>[],
    );

    if (query.isLoading || (query.isFetching && items.isEmpty)) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Color(AppColors.primaryColor),
          ),
        ),
      );
    }

    if (query.isError && items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 42,
              color: Color(AppColors.textSecondaryColor),
            ),
            const SizedBox(height: 10),
            const Text(
              'Failed to load search results',
              style: TextStyle(
                color: Color(AppColors.textSecondaryColor),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => query.refetch(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (items.isEmpty) {
      return RefreshIndicator(
        color: const Color(AppColors.primaryColor),
        onRefresh: () async {
          await query.refetch();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.5,
              child: const MatchHistoryEmptyPlaceholder(
                icon: Icons.search_off_outlined,
                title: 'No results found',
                subtitle: 'Try another keyword or switch the category filter.',
              ),
            ),
          ],
        ),
      );
    }

    final grouped = _groupByCategory(items);

    return RefreshIndicator(
      color: const Color(AppColors.primaryColor),
      onRefresh: () async {
        await query.refetch();
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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            for (final category in _sectionOrder) ...[
              if (grouped[category]?.isNotEmpty == true)
                _SearchSection(
                  category: category,
                  items: grouped[category]!,
                  onViewMore: () => onViewMore(category),
                ),
            ],
            if (query.isFetchingNextPage)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(AppColors.primaryColor),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static List<ExploreItem> _dedupeItems(List<ExploreItem> items) {
    final seen = <String>{};
    final out = <ExploreItem>[];
    for (final item in items) {
      final key =
          '${item.engagementType.apiValue}:${item.entityId ?? identityHashCode(item)}';
      if (seen.add(key)) out.add(item);
    }
    return out;
  }

  static Map<ExploreCategory, List<ExploreItem>> _groupByCategory(
    List<ExploreItem> items,
  ) {
    final map = <ExploreCategory, List<ExploreItem>>{
      for (final c in _sectionOrder) c: <ExploreItem>[],
    };
    for (final item in items) {
      final category = switch (item) {
        ExploreMatchItem() => ExploreCategory.match,
        ExploreTeamItem() => ExploreCategory.team,
        ExplorePlayerItem() => ExploreCategory.player,
        ExplorePostItem() => ExploreCategory.post,
      };
      map[category]!.add(item);
    }
    return map;
  }
}

class _SearchSection extends StatelessWidget {
  const _SearchSection({
    required this.category,
    required this.items,
    required this.onViewMore,
  });

  final ExploreCategory category;
  final List<ExploreItem> items;
  final VoidCallback onViewMore;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  ExploreSearchCategoryTabs.label(category),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(AppColors.textColor),
                  ),
                ),
              ),
              TextButton(
                onPressed: onViewMore,
                child: const Text('View more'),
              ),
            ],
          ),
        ),
        for (var i = 0; i < items.length; i++)
          VisibilityDetector(
            key: Key(
              'search-all-${items[i].engagementType.apiValue}-${items[i].entityId ?? i}',
            ),
            onVisibilityChanged: (info) {
              if (info.visibleFraction < 0.5) return;
              final item = items[i];
              final id = item.entityId;
              if (id == null || id.isEmpty) return;
              EngagementService().trackImpression(
                entityType: item.engagementType,
                entityId: id,
              );
            },
            child: ExploreItemTile(item: items[i]),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}
