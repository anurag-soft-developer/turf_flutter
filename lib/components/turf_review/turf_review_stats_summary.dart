import 'package:flutter/material.dart';

import '../../core/config/constants.dart';
import '../../turf/model/turf_review_model.dart';

/// Rating breakdown and average for a turf.
class TurfReviewStatsSummary extends StatelessWidget {
  const TurfReviewStatsSummary({
    super.key,
    required this.stats,
    this.isLoading = false,
  });

  final TurfReviewStats? stats;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading && stats == null) {
      return const Card(
        margin: EdgeInsets.zero,
        color: Color(AppColors.surfaceColor),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    final avg = stats?.averageRating ?? 0.0;
    final total = stats?.totalReviews ?? 0;
    final dist = stats?.ratingDistribution ?? {};

    return Card(
      color: Color(AppColors.surfaceColor),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  avg > 0 ? avg.toStringAsFixed(1) : '—',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Color(AppColors.textColor),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StarsRow(rating: avg),
                      const SizedBox(height: 4),
                      Text(
                        total == 1 ? '1 review' : '$total reviews',
                        style: const TextStyle(
                          color: Color(AppColors.textSecondaryColor),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (dist.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...List.generate(5, (i) {
                final star = 5 - i;
                final key = star.toString();
                final count = dist[key] ?? 0;
                final max = dist.values.fold<int>(0, (m, v) => v > m ? v : m);
                final fraction = max > 0 ? count / max : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 14,
                        child: Text(
                          '$star',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(AppColors.textSecondaryColor),
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.star,
                        size: 12,
                        color: Color(0xFFFBBF24),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: fraction.clamp(0.0, 1.0),
                            minHeight: 6,
                            backgroundColor: const Color(0xFFE5E7EB),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(AppColors.primaryColor),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 28,
                        child: Text(
                          '$count',
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(AppColors.textSecondaryColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _StarsRow extends StatelessWidget {
  const _StarsRow({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final v = i + 1;
        final filled = rating >= v - 0.25;
        final half = !filled && rating >= v - 0.75;
        return Icon(
          half ? Icons.star_half : Icons.star,
          size: 20,
          color: filled || half
              ? const Color(0xFFFBBF24)
              : const Color(0xFFD1D5DB),
        );
      }),
    );
  }
}
