import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/config/constants.dart';
import '../../core/models/location_model.dart';
import '../../core/utils/map_launch_util.dart';
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

                    // Pass gestures through to PageView (DecoratedBox would absorb hits).
                    const IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, Colors.black54],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),

                    if (turf.images!.length > 1)
                      Positioned(
                        bottom: 20,
                        left: 0,
                        right: 0,
                        child: Obx(
                          () => Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: turf.images!.asMap().entries.map((entry) {
                              return Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
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
            const SizedBox(height: 20),
          ],

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
            _LocationRow(location: turf.location!),
            const SizedBox(height: 20),
          ],

          // Sports and amenities info grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _AmenitiesInfoCard(amenities: turf.amenities!),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TurfInfoCard(
                    title: 'Timing',
                    value: turf.operatingHours != null
                        ? '${turf.operatingHours!.open} - ${turf.operatingHours!.close}'
                        : 'Not specified',
                    icon: Icons.access_time,
                  ),
                ),
              ],
            ),
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

class _LocationRow extends StatelessWidget {
  const _LocationRow({required this.location});

  final LocationModel location;

  @override
  Widget build(BuildContext context) {
    final canOpenMaps = canOpenLocationInMaps(location);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canOpenMaps ? () => openLocationInMaps(location) : null,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.location_on, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  location.address,
                  style: TextStyle(
                    fontSize: 16,
                    color: canOpenMaps
                        ? const Color(AppColors.primaryColor)
                        : const Color(AppColors.textColor),
                    decoration: canOpenMaps
                        ? TextDecoration.underline
                        : TextDecoration.none,
                    decorationColor: const Color(AppColors.primaryColor),
                  ),
                ),
              ),
              if (canOpenMaps)
                const Icon(
                  Icons.open_in_new,
                  size: 18,
                  color: Color(AppColors.primaryColor),
                ),
            ],
          ),
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

class _AmenitiesInfoCard extends StatelessWidget {
  const _AmenitiesInfoCard({required this.amenities});

  final List<String> amenities;

  static const int _visibleCount = 2;

  String get _visibleText {
    if (amenities.length <= _visibleCount) {
      return amenities.join(', ');
    }

    return amenities.take(_visibleCount).join(', ');
  }

  int? get _remainingCount {
    if (amenities.length <= _visibleCount) return null;
    return amenities.length - _visibleCount;
  }

  void _showAll(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final maxHeight = MediaQuery.of(context).size.height * 0.6;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Amenities',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(AppColors.textColor),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      color: const Color(AppColors.textSecondaryColor),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxHeight),
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: amenities
                          .map((amenity) => _AmenityChip(label: amenity))
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showAll(context),
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.local_activity,
                    size: 20,
                    color: Color(AppColors.primaryColor),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Amenities',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(AppColors.textSecondaryColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(AppColors.textColor),
                  ),
                  children: [
                    TextSpan(text: _visibleText),
                    if (_remainingCount != null)
                      TextSpan(
                        text: ' +$_remainingCount',
                        style: const TextStyle(
                          color: Color(AppColors.primaryColor),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmenityChip extends StatelessWidget {
  const _AmenityChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(AppColors.dividerColor)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(AppColors.textColor),
        ),
      ),
    );
  }
}
