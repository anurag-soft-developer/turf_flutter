import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/config/constants.dart';
import '../../core/config/sport_types.dart';
import '../../turf/feed/turf_list_controller.dart';
import 'search_components.dart';

class SportTypesFilterBottomSheet extends StatelessWidget {
  final TurfListController controller;

  const SportTypesFilterBottomSheet({super.key, required this.controller});

  static void show(BuildContext context, TurfListController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SportTypesFilterBottomSheet(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SearchableMultiSelectSheet(
      title: 'Sport Types',
      searchHint: 'Search sport types',
      onClear: () {
        controller.selectedSportTypes.clear();
        controller.searchTurfs();
      },
      buildContent: (query) {
        final sports = _filterSportTypes(controller.availableSportTypes, query);
        if (sports.isEmpty) {
          return _NoSearchResults(query: query);
        }

        return Obx(
          () => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sports
                .map(
                  (sport) => QuickFilterChip(
                    label: sport.label,
                    icon: sport.icon,
                    isSelected:
                        controller.selectedSportTypes.contains(sport.id),
                    onTap: () => controller.toggleSportType(sport.id),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}

class AmenitiesFilterBottomSheet extends StatelessWidget {
  final TurfListController controller;

  const AmenitiesFilterBottomSheet({super.key, required this.controller});

  static void show(BuildContext context, TurfListController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AmenitiesFilterBottomSheet(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SearchableMultiSelectSheet(
      title: 'Amenities',
      searchHint: 'Search amenities',
      onClear: () {
        controller.selectedAmenities.clear();
        controller.searchTurfs();
      },
      buildContent: (query) {
        final amenities = _filterAmenities(controller.availableAmenities, query);
        if (amenities.isEmpty) {
          return _NoSearchResults(query: query);
        }

        return Obx(
          () => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: amenities
                .map(
                  (amenity) => QuickFilterChip(
                    label: amenity,
                    isSelected:
                        controller.selectedAmenities.contains(amenity),
                    onTap: () => controller.toggleAmenity(amenity),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}

class _SearchableMultiSelectSheet extends StatefulWidget {
  final String title;
  final String searchHint;
  final VoidCallback onClear;
  final Widget Function(String query) buildContent;

  const _SearchableMultiSelectSheet({
    required this.title,
    required this.searchHint,
    required this.onClear,
    required this.buildContent,
  });

  @override
  State<_SearchableMultiSelectSheet> createState() =>
      _SearchableMultiSelectSheetState();
}

class _SearchableMultiSelectSheetState extends State<_SearchableMultiSelectSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight =
        (screenHeight * 0.85 - keyboardHeight).clamp(280.0, screenHeight);
    final sheetHeight =
        keyboardHeight > 0 ? maxHeight : screenHeight * 0.6;

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: sheetHeight.clamp(280.0, maxHeight),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(title: widget.title, onClear: widget.onClear),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(AppColors.textColor),
                  ),
                  decoration: InputDecoration(
                    hintText: widget.searchHint,
                    hintStyle: const TextStyle(
                      color: Color(AppColors.textSecondaryColor),
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(AppColors.textSecondaryColor),
                    ),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(
                              Icons.clear,
                              color: Color(AppColors.textSecondaryColor),
                            ),
                          ),
                    filled: true,
                    fillColor: const Color(AppColors.surfaceColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(AppColors.primaryColor),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: widget.buildContent(_query),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

List<SportTypeConfig> _filterSportTypes(
  List<SportTypeConfig> sports,
  String query,
) {
  final trimmed = query.trim().toLowerCase();
  if (trimmed.isEmpty) return sports;

  return sports
      .where(
        (sport) =>
            sport.label.toLowerCase().contains(trimmed) ||
            sport.id.toLowerCase().contains(trimmed),
      )
      .toList();
}

List<String> _filterAmenities(List<String> amenities, String query) {
  final trimmed = query.trim().toLowerCase();
  if (trimmed.isEmpty) return amenities;

  return amenities
      .where((amenity) => amenity.toLowerCase().contains(trimmed))
      .toList();
}

class _NoSearchResults extends StatelessWidget {
  final String query;

  const _NoSearchResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          query.trim().isEmpty
              ? 'No options available'
              : 'No results for "${query.trim()}"',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class PriceRangeFilterBottomSheet extends StatelessWidget {
  final TurfListController controller;

  const PriceRangeFilterBottomSheet({super.key, required this.controller});

  static void show(BuildContext context, TurfListController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => PriceRangeFilterBottomSheet(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            title: 'Price Range',
            onClear: () {
              controller.updatePriceRange(0, 5000);
            },
          ),
          const SizedBox(height: 16),
          Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₹${controller.minPrice.value.toInt()} - ₹${controller.maxPrice.value.toInt()}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(AppColors.textColor),
                  ),
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
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class RatingFilterBottomSheet extends StatelessWidget {
  final TurfListController controller;

  const RatingFilterBottomSheet({super.key, required this.controller});

  static void show(BuildContext context, TurfListController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => RatingFilterBottomSheet(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            title: 'Minimum Rating',
            onClear: () {
              controller.updateRating(0);
            },
          ),
          const SizedBox(height: 16),
          Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.selectedRating.value == 0
                      ? 'Any'
                      : '${controller.selectedRating.value.toStringAsFixed(1)}+',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(AppColors.textColor),
                  ),
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
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

Widget _buildHeader({
  required String title,
  required VoidCallback onClear,
}) {
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(AppColors.textColor),
            ),
          ),
          TextButton(
            onPressed: onClear,
            child: const Text(
              'Clear',
              style: TextStyle(color: Color(AppColors.primaryColor)),
            ),
          ),
        ],
      ),
    ],
  );
}
