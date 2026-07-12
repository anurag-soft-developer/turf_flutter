import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../core/config/constants.dart';
import '../../core/models/paginated_response.dart';
import '../../core/query/query_keys.dart';
import '../../core/query/query_retry.dart';
import '../../turf/model/turf_review_model.dart';
import '../../turf/reviews/turf_review_service.dart';
import 'turf_review_stats_summary.dart';
import 'turf_review_tile.dart';
import 'turf_review_write_form.dart';


void openTurfReviewWriteSheet(BuildContext context, String turfId) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => TurfReviewWriteForm(turfId: turfId),
  );
}

Future<void> invalidateTurfReviewQueries(String turfId) async {
  if (!Get.isRegistered<QueryClient>()) return;
  final client = Get.find<QueryClient>();
  await Future.wait([
    client.invalidateQueries(queryKey: ['turfReviews', turfId]),
    client.invalidateQueries(queryKey: QueryKeys.turfReviewStats(turfId)),
  ]);
}

class TurfDetailReviewsSection extends HookWidget {
  const TurfDetailReviewsSection({
    super.key,
    required this.turfId,
    this.showReviewList = true,
  });

  final String turfId;

  /// When false, only rating stats / summary is shown (e.g. owner manage screen).
  final bool showReviewList;

  @override
  Widget build(BuildContext context) {
    final statsQuery = useQuery<TurfReviewStats?, Object>(
      QueryKeys.turfReviewStats(turfId),
      (_) => TurfReviewService().getTurfReviewStats(turfId),
      retry: noRetry,
    );

    final previewQuery =
        useQuery<PaginatedResponse<TurfReviewModel>, Object>(
      QueryKeys.turfReviews(turfId, preview: true),
      (_) async {
        final page = await TurfReviewService().findTurfReviews(
          turfId,
          TurfReviewListQuery(
            turf: turfId,
            page: 1,
            limit: 3,
            sortBy: 'helpfulVotes',
            sortOrder: 'desc',
          ),
        );
        return page ?? EmptyPaginatedResponse<TurfReviewModel>();
      },
      retry: noRetry,
    );

    final statsLoading =
        statsQuery.isLoading || (statsQuery.isFetching && statsQuery.data == null);
    final list = previewQuery.data?.data ?? const <TurfReviewModel>[];
    final listLoading = previewQuery.isLoading ||
        (previewQuery.isFetching && previewQuery.data == null);
    final listError = previewQuery.isError && list.isEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Reviews',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(AppColors.textColor),
                ),
              ),
              if (showReviewList)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(AppColors.primaryColor),
                  ),
                  onPressed: () => openTurfReviewWriteSheet(context, turfId),
                  icon: const Icon(Icons.edit_outlined, size: 15),
                  label: const Text('Write'),
                )
              else
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(AppColors.primaryColor),
                  ),
                  onPressed: () => Get.toNamed(
                    AppConstants.routes.turfReviews,
                    arguments: {'turfId': turfId},
                  ),
                  child: const Text('View all'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TurfReviewStatsSummary(
            stats: statsQuery.data,
            isLoading: statsLoading,
          ),
          if (listError)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Could not load reviews',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            )
          else if (showReviewList) ...[
            if (list.isEmpty && !listLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No reviews yet. Be the first to share your experience.',
                  style: TextStyle(color: Color(AppColors.textSecondaryColor)),
                ),
              )
            else if (list.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Popular reviews',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(AppColors.textColor),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Get.toNamed(
                      AppConstants.routes.turfReviews,
                      arguments: {'turfId': turfId},
                    ),
                    child: const Text(
                      'View all',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(AppColors.primaryColor),
                      ),
                    ),
                  ),
                ],
              ),
              ...list.map((r) => TurfReviewTile(review: r)),
            ],
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
