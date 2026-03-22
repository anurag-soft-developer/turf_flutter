import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/constants.dart';
import '../../controllers/turf_list_controller.dart';

class FilterBottomSheet extends StatelessWidget {
  final TurfListController controller;

  const FilterBottomSheet({super.key, required this.controller});

  static void show(BuildContext context, TurfListController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FilterBottomSheet(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSportTypesFilter(),
                    const SizedBox(height: 24),
                    _buildAmenitiesFilter(),
                    const SizedBox(height: 24),
                    _buildPriceRangeFilter(),
                    const SizedBox(height: 24),
                    _buildRatingFilter(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            _buildApplyButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Filters',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                controller.clearFilters();
                Get.back();
              },
              child: const Text('Clear All'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSportTypesFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sport Types',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Obx(
          () => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: controller.availableSportTypes
                .map(
                  (sport) => FilterChip(
                    label: Text(sport),
                    selected: controller.selectedSportTypes.contains(sport),
                    onSelected: (_) => controller.toggleSportType(sport),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAmenitiesFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Amenities',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Obx(
          () => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: controller.availableAmenities
                .map(
                  (amenity) => FilterChip(
                    label: Text(amenity),
                    selected: controller.selectedAmenities.contains(amenity),
                    onSelected: (_) => controller.toggleAmenity(amenity),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRangeFilter() {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Price Range: ₹${controller.minPrice.toInt()} - ₹${controller.maxPrice.toInt()}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          RangeSlider(
            values: RangeValues(
              controller.minPrice.value,
              controller.maxPrice.value,
            ),
            min: 0,
            max: 5000,
            divisions: 50,
            labels: RangeLabels(
              '₹${controller.minPrice.value.toInt()}',
              '₹${controller.maxPrice.value.toInt()}',
            ),
            onChanged: (values) =>
                controller.updatePriceRange(values.start, values.end),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingFilter() {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Minimum Rating: ${controller.selectedRating == 0 ? 'Any' : '${controller.selectedRating.toStringAsFixed(1)}+'}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          Slider(
            value: controller.selectedRating.value,
            min: 0,
            max: 5,
            divisions: 10,
            label: controller.selectedRating.value == 0
                ? 'Any'
                : '${controller.selectedRating.value.toStringAsFixed(1)}+',
            onChanged: controller.updateRating,
          ),
        ],
      ),
    );
  }

  Widget _buildApplyButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Get.back();
          controller.searchTurfs();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(AppColors.primaryColor),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Apply Filters',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
