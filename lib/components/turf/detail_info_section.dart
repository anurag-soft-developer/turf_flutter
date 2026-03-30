import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/config/constants.dart';
import '../../turf/details/turf_detail_controller.dart';

class TurfImageCarousel extends StatelessWidget {
  final TurfDetailController controller;

  const TurfImageCarousel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final turf = controller.turf.value;
      if (turf == null) return const SizedBox();

      final hasImages = turf.images?.isNotEmpty == true;

      return SliverAppBar(
        expandedHeight: 250,
        pinned: true,
        backgroundColor: const Color(AppColors.primaryColor),
        foregroundColor: Colors.white,
        flexibleSpace: FlexibleSpaceBar(
          title: Text(
            turf.displayName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  offset: Offset(0, 1),
                  blurRadius: 3,
                  color: Colors.black54,
                ),
              ],
            ),
          ),
          background: hasImages
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image carousel
                    PageView.builder(
                      itemCount: turf.images!.length,
                      onPageChanged: controller.changeImageIndex,
                      itemBuilder: (context, index) {
                        return Image.network(
                          turf.images![index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.sports_soccer,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                              ),
                        );
                      },
                    ),

                    // Gradient overlay
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Colors.black54],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),

                    // Image indicators
                    if (turf.images!.length > 1)
                      Positioned(
                        bottom: 20,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: turf.images!.asMap().entries.map((entry) {
                            return Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    controller.currentImageIndex.value ==
                                        entry.key
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.5),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                )
              : Container(
                  color: const Color(AppColors.primaryColor),
                  child: const Icon(
                    Icons.sports_soccer,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
        ),
      );
    });
  }
}

class TurfInfoSection extends StatelessWidget {
  final TurfDetailController controller;

  const TurfInfoSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final turf = controller.turf.value!;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating and availability
          Row(
            children: [
              if (turf.averageRating != null) ...[
                _buildRatingBadge(turf.averageRating!),
                const SizedBox(width: 12),
              ],
              Obx(() => _buildAvailabilityBadge(controller)),
            ],
          ),

          const SizedBox(height: 16),

          // Description
          if (turf.description?.isNotEmpty == true) ...[
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(AppColors.textColor),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              turf.description!,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Color(AppColors.textColor),
              ),
            ),
            // Location
            if (turf.location?.address != null) ...[
              const Text(
                'Location',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(AppColors.textColor),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      turf.location!.address,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(AppColors.textColor),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Sports and amenities info grid
            Row(
              children: [
                Expanded(
                  child: TurfInfoCard(
                    title: 'Sports',
                    value: turf.sportTypesDisplay,
                    icon: Icons.sports_soccer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TurfInfoCard(
                    title: 'Price',
                    value: '₹${turf.pricing?.basePricePerHour ?? 0}/hr',
                    icon: Icons.attach_money,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (turf.amenities?.isNotEmpty == true)
              Row(
                children: [
                  Expanded(
                    child: TurfInfoCard(
                      title: 'Amenities',
                      value: turf.amenitiesDisplay,
                      icon: Icons.local_activity,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TurfInfoCard(
                      title: 'Operating Hours',
                      value: turf.operatingHours != null
                          ? '${turf.operatingHours!.open} - ${turf.operatingHours!.close}'
                          : 'Not specified',
                      icon: Icons.access_time,
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingBadge(double rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityBadge(TurfDetailController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: controller.isCurrentlyOpen ? Colors.green : Colors.orange,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        controller.turf.value!.availabilityStatus,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class TurfInfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const TurfInfoCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(AppColors.primaryColor)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(AppColors.textSecondaryColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(AppColors.textColor),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
