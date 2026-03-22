import 'package:flutter/material.dart';
import '../../config/constants.dart';
import '../../controllers/turf_list_controller.dart';
import '../../models/turf_model.dart';

class FeaturedTurfCard extends StatelessWidget {
  final TurfModel turf;
  final TurfListController controller;

  const FeaturedTurfCard({
    super.key,
    required this.turf,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => controller.navigateToTurfDetail(turf),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                image: turf.mainImage != null
                    ? DecorationImage(
                        image: NetworkImage(turf.mainImage!),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: turf.mainImage == null ? Colors.grey[300] : null,
              ),
              child: turf.mainImage == null
                  ? const Icon(
                      Icons.sports_soccer,
                      size: 40,
                      color: Colors.grey,
                    )
                  : null,
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    turf.displayName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        turf.ratingDisplay,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${turf.pricing?.basePricePerHour ?? 0}/hr',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(AppColors.primaryColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TurfListCard extends StatelessWidget {
  final TurfModel turf;
  final TurfListController controller;

  const TurfListCard({super.key, required this.turf, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => controller.navigateToTurfDetail(turf),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: turf.mainImage != null
                      ? DecorationImage(
                          image: NetworkImage(turf.mainImage!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: turf.mainImage == null ? Colors.grey[300] : null,
                ),
                child: turf.mainImage == null
                    ? const Icon(Icons.sports_soccer, color: Colors.grey)
                    : null,
              ),

              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            turf.displayName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TurfAvailabilityBadge(turf: turf),
                      ],
                    ),

                    const SizedBox(height: 4),

                    if (turf.location?.address != null)
                      Text(
                        turf.location!.address,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        if (turf.averageRating != null) ...[
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            turf.averageRating!.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            ' (${turf.totalReviews ?? 0})',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],

                        Text(
                          '₹${turf.pricing?.basePricePerHour ?? 0}/hr',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(AppColors.primaryColor),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    if (turf.sportType?.isNotEmpty == true)
                      Text(
                        turf.sportTypesDisplay,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TurfAvailabilityBadge extends StatelessWidget {
  final TurfModel turf;

  const TurfAvailabilityBadge({super.key, required this.turf});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: turf.isAvailable == true
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        turf.availabilityStatus,
        style: TextStyle(
          fontSize: 10,
          color: turf.isAvailable == true ? Colors.green[700] : Colors.red[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class EmptyTurfsView extends StatelessWidget {
  final VoidCallback onClearFilters;

  const EmptyTurfsView({super.key, required this.onClearFilters});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sports_soccer, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No turfs found',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onClearFilters,
            child: const Text('Clear Filters'),
          ),
        ],
      ),
    );
  }
}
