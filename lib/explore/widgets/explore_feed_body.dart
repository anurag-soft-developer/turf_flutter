import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../components/match_history/match_history_placeholders.dart';
import '../../core/components/scroll/floating_sliver_app_bar.dart';
import '../../core/config/constants.dart';
import '../../core/models/location_model.dart';
import '../../core/query/query_keys.dart';
import '../../core/query/query_retry.dart';
import '../../engagement/engagement_service.dart';
import '../explore_service.dart';
import '../model/explore_category.dart';
import '../model/explore_filters.dart';
import '../model/explore_item.dart';
import 'explore_item_tile.dart';

class ExploreFeedBody extends HookWidget {
  const ExploreFeedBody({
    super.key,
    required this.mode,
    required this.category,
    required this.filters,
    this.q,
    this.location,
    this.enabled = true,
    this.emptyTitle = 'Nothing to explore yet',
    this.emptySubtitle =
        'Matches, teams, players, and posts will show up here as activity grows.',
    this.emptyIcon = Icons.explore_outlined,
    this.errorMessage = 'Failed to load explore feed',
    /// When set, wraps feed in [CustomScrollView] with these leading slivers
    /// (floating app bar, pinned filters) so pagination/refresh stay on one scroll.
    this.leadingSlivers,
  });

  final String mode;
  final ExploreCategory category;
  final ExploreFilters filters;
  final String? q;
  final LocationModel? location;
  final bool enabled;
  final String emptyTitle;
  final String emptySubtitle;
  final IconData emptyIcon;
  final String errorMessage;
  final List<Widget>? leadingSlivers;

  @override
  Widget build(BuildContext context) {
    final query = useInfiniteQuery<ExplorePaginatedResponse, Object, int>(
      QueryKeys.explore(
        mode: mode,
        category: category.apiValue,
        q: q,
        filterParts: filters.toQueryKeyParts(),
        lat: location?.latitude,
        lng: location?.longitude,
      ),
      (ctx) async {
        final result = await ExploreService().fetch(
          q: q,
          category: category,
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
      enabled: enabled,
      nextPageParamBuilder: (data) {
        final last = data.pages.isNotEmpty ? data.pages.last : null;
        if (last == null || !last.hasNextPage) return null;
        return last.page + 1;
      },
    );

    final items =
        query.data?.pages.expand((p) => p.data).toList() ??
        const <ExploreItem>[];

    final leading = leadingSlivers;
    if (leading != null) {
      return RefreshIndicator(
        edgeOffset: floatingRefreshEdgeOffset(context),
        color: const Color(AppColors.primaryColor),
        onRefresh: () => query.refetch(),
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
              ...leading,
              ..._feedSlivers(
                context: context,
                query: query,
                items: items,
              ),
            ],
          ),
        ),
      );
    }

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
            Text(
              errorMessage,
              style: const TextStyle(
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
              child: MatchHistoryEmptyPlaceholder(
                icon: emptyIcon,
                title: emptyTitle,
                subtitle: emptySubtitle,
              ),
            ),
          ],
        ),
      );
    }

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
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          scrollCacheExtent: const ScrollCacheExtent.pixels(800),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: items.length + (query.isFetchingNextPage ? 1 : 0),
          itemBuilder: (context, i) {
            if (i == items.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(AppColors.primaryColor),
                    ),
                  ),
                ),
              );
            }

            return _ExploreFeedItem(item: items[i], index: i);
          },
        ),
      ),
    );
  }

  List<Widget> _feedSlivers({
    required BuildContext context,
    required InfiniteQueryResult<ExplorePaginatedResponse, Object, int> query,
    required List<ExploreItem> items,
  }) {
    if (query.isLoading || (query.isFetching && items.isEmpty)) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Color(AppColors.primaryColor),
              ),
            ),
          ),
        ),
      ];
    }

    if (query.isError && items.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 42,
                  color: Color(AppColors.textSecondaryColor),
                ),
                const SizedBox(height: 10),
                Text(
                  errorMessage,
                  style: const TextStyle(
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
          ),
        ),
      ];
    }

    if (items.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: MatchHistoryEmptyPlaceholder(
            icon: emptyIcon,
            title: emptyTitle,
            subtitle: emptySubtitle,
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              if (i == items.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(AppColors.primaryColor),
                      ),
                    ),
                  ),
                );
              }

              return _ExploreFeedItem(item: items[i], index: i);
            },
            childCount: items.length + (query.isFetchingNextPage ? 1 : 0),
          ),
        ),
      ),
    ];
  }
}

class _ExploreFeedItem extends StatelessWidget {
  const _ExploreFeedItem({required this.item, required this.index});

  final ExploreItem item;
  final int index;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(
        'explore-${item.engagementType.apiValue}-${item.entityId ?? index}',
      ),
      onVisibilityChanged: (info) {
        if (info.visibleFraction < 0.5) return;
        final id = item.entityId;
        if (id == null || id.isEmpty) return;
        EngagementService().trackImpression(
          entityType: item.engagementType,
          entityId: id,
        );
      },
      child: ExploreItemTile(item: item),
    );
  }
}
