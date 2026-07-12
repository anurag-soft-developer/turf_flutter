import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../components/turf_review/turf_review_stats_summary.dart';
import '../../components/turf_review/turf_review_tile.dart';
import '../../core/config/constants.dart';
import '../../core/models/paginated_response.dart';
import '../../core/query/query_keys.dart';
import '../../core/query/query_retry.dart';
import '../model/turf_review_model.dart';
import 'turf_review_service.dart';

class TurfReviewsFullScreen extends HookWidget {
  const TurfReviewsFullScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final raw = Get.arguments;
    final turfId =
        raw is Map<String, dynamic> ? raw['turfId'] as String? : null;

    if (turfId == null || turfId.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(AppColors.backgroundColor),
        appBar: AppBar(title: const Text('Reviews')),
        body: const Center(child: Text('Unable to open reviews for this turf.')),
      );
    }

    final statsQuery = useQuery<TurfReviewStats?, Object>(
      QueryKeys.turfReviewStats(turfId),
      (_) => TurfReviewService().getTurfReviewStats(turfId),
      retry: noRetry,
    );

    final reviewsQuery =
        useInfiniteQuery<PaginatedResponse<TurfReviewModel>, Object, int>(
      QueryKeys.turfReviews(turfId),
      (ctx) async {
        final page = await TurfReviewService().findTurfReviews(
          turfId,
          TurfReviewListQuery(
            turf: turfId,
            page: ctx.pageParam,
            limit: 20,
            sortBy: 'createdAt',
            sortOrder: 'desc',
          ),
        );
        return page ?? EmptyPaginatedResponse<TurfReviewModel>();
      },
      initialPageParam: 1,
      retry: noRetry,
      nextPageParamBuilder: (data) {
        final last = data.pages.isNotEmpty ? data.pages.last : null;
        if (last == null || !last.hasNextPage) return null;
        return last.page + 1;
      },
    );

    final reviews =
        reviewsQuery.data?.pages.expand((p) => p.data).toList() ??
        const <TurfReviewModel>[];
    final statsLoading = statsQuery.isLoading ||
        (statsQuery.isFetching && statsQuery.data == null);
    final listLoading = reviewsQuery.isLoading ||
        (reviewsQuery.isFetching && reviews.isEmpty);

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: const Text('All reviews'),
        backgroundColor: const Color(AppColors.primaryColor),
        foregroundColor: Colors.white,
      ),
      body: listLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color(AppColors.primaryColor),
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  statsQuery.refetch(),
                  reviewsQuery.refetch(),
                ]);
              },
              color: const Color(AppColors.primaryColor),
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification.metrics.pixels >=
                      notification.metrics.maxScrollExtent - 160) {
                    if (reviewsQuery.hasNextPage &&
                        !reviewsQuery.isFetchingNextPage) {
                      reviewsQuery.fetchNextPage();
                    }
                  }
                  return false;
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    TurfReviewStatsSummary(
                      stats: statsQuery.data,
                      isLoading: statsLoading && reviews.isEmpty,
                    ),
                    const SizedBox(height: 16),
                    if (reviewsQuery.isError && reviews.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'Could not load reviews',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ...reviews.map((r) => TurfReviewTile(review: r)),
                    if (reviewsQuery.isFetchingNextPage)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
