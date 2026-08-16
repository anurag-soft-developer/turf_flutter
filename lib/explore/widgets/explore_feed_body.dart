import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';

import '../../core/models/location_model.dart';
import '../../core/query/query_keys.dart';
import '../../core/query/query_retry.dart';
import '../explore_service.dart';
import '../model/explore_category.dart';
import '../model/explore_filters.dart';
import '../model/explore_item.dart';
import 'explore_list.dart';

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
        query.data?.pages.expand((p) => p.data).toList() ?? const <ExploreItem>[];

    return ExploreList(
      query: query,
      items: items,
      emptyTitle: emptyTitle,
      emptySubtitle: emptySubtitle,
      emptyIcon: emptyIcon,
      errorMessage: errorMessage,
    );
  }
}
