import 'package:flutter/material.dart';
import 'package:flutter_query/flutter_query.dart';

import '../../components/match_history/match_history_placeholders.dart';
import '../../core/config/constants.dart';
import '../model/explore_item.dart';
import 'explore_item_tile.dart';

class ExploreList extends StatelessWidget {
  const ExploreList({
    super.key,
    required this.query,
    required this.items,
    required this.emptyTitle,
    required this.emptySubtitle,
    this.emptyIcon = Icons.explore_outlined,
    this.errorMessage = 'Failed to load explore feed',
  });

  final InfiniteQueryResult<ExplorePaginatedResponse, Object, int> query;
  final List<ExploreItem> items;
  final String emptyTitle;
  final String emptySubtitle;
  final IconData emptyIcon;
  final String errorMessage;

  @override
  Widget build(BuildContext context) {
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

            return ExploreItemTile(item: items[i]);
          },
        ),
      ),
    );
  }
}
