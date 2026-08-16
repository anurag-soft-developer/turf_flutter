import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/config/constants.dart';
import '../../turf/feed/turf_list_controller.dart';
import '../../core/components/bottom_sheets/city_picker_bottom_sheet.dart';
import 'turf_filter_bottom_sheets.dart';

class QuickFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  const QuickFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final primary = const Color(AppColors.primaryColor);
    // Theme-matched indigo tint (between washed-out and solid primary).
    const selectedBg = Color(0xFFE0E7FF);

    return FilterChip(
      avatar: icon == null
          ? null
          : Icon(icon, size: 16, color: primary),
      label: Text(
        label,
        style: TextStyle(
          color: primary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.white,
      color: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return selectedBg;
        }
        return Colors.white;
      }),
      showCheckmark: false,
      side: BorderSide(
        color: isSelected ? primary : primary.withValues(alpha: 0.55),
      ),
    );
  }
}

class FilterFieldChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isActive;
  final VoidCallback onPressed;

  const FilterFieldChip({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final primary = const Color(AppColors.primaryColor);
    const selectedBg = Color(0xFFE0E7FF);

    return ActionChip(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      avatar: icon == null
          ? null
          : Icon(icon, size: 16, color: primary),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.arrow_drop_down, color: primary),
        ],
      ),
      backgroundColor: isActive ? selectedBg : Colors.white,
      side: BorderSide(
        color: isActive ? primary : primary.withValues(alpha: 0.55),
      ),
      onPressed: onPressed,
    );
  }
}

String _multiSelectLabel({
  required String placeholder,
  required List<String> selected,
  required List<String> Function(List<String> selected) resolveLabels,
}) {
  if (selected.isEmpty) return placeholder;

  final labels = resolveLabels(selected);
  if (labels.isEmpty) return placeholder;
  if (labels.length == 1) return labels.first;
  return '${labels.first} +${labels.length - 1}';
}

String _sportTypesLabel(TurfListController controller) {
  return _multiSelectLabel(
    placeholder: 'Sports',
    selected: controller.selectedSportTypes,
    resolveLabels: (selected) => controller.availableSportTypes
        .where((sport) => selected.contains(sport.id))
        .map((sport) => sport.label)
        .toList(),
  );
}

String _amenitiesLabel(TurfListController controller) {
  return _multiSelectLabel(
    placeholder: 'Amenities',
    selected: controller.selectedAmenities,
    resolveLabels: (selected) => selected,
  );
}

String _priceLabel(TurfListController controller) {
  final min = controller.minPrice.value;
  final max = controller.maxPrice.value;
  if (min <= 0 && max >= 5000) return 'Price';
  return '₹${min.toInt()}-₹${max.toInt()}';
}

String _ratingLabel(TurfListController controller) {
  final rating = controller.selectedRating.value;
  if (rating <= 0) return 'Rating';
  return '${rating.toStringAsFixed(1)}+';
}

class QuickFiltersRow extends StatelessWidget {
  final TurfListController controller;

  const QuickFiltersRow({super.key, required this.controller});

  void _showCityPickerBottomSheet(BuildContext context) {
    CityPickerBottomSheet.show(
      context: context,
      settings: controller.settings,
      onChanged: controller.searchTurfs,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Obx(() {
        final city = controller.settings.selectedCityLabel.trim();
        final firstPart = city.split(',').first.trim();
        final cityLabel = firstPart.isNotEmpty
            ? firstPart
            : city.isNotEmpty
            ? city
            : 'Select city';

        return Row(
          children: [
            FilterFieldChip(
              label: cityLabel,
              icon: Icons.location_city,
              isActive: city.isNotEmpty,
              onPressed: () => _showCityPickerBottomSheet(context),
            ),
            const SizedBox(width: 8),
            FilterFieldChip(
              label: _sportTypesLabel(controller),
              icon: Icons.sports,
              isActive: controller.selectedSportTypes.isNotEmpty,
              onPressed: () =>
                  SportTypesFilterBottomSheet.show(context, controller),
            ),
            const SizedBox(width: 8),
            FilterFieldChip(
              label: _amenitiesLabel(controller),
              icon: Icons.local_offer_outlined,
              isActive: controller.selectedAmenities.isNotEmpty,
              onPressed: () =>
                  AmenitiesFilterBottomSheet.show(context, controller),
            ),
            const SizedBox(width: 8),
            FilterFieldChip(
              label: _priceLabel(controller),
              icon: Icons.currency_rupee,
              isActive: controller.minPrice.value > 0 ||
                  controller.maxPrice.value < 5000,
              onPressed: () =>
                  PriceRangeFilterBottomSheet.show(context, controller),
            ),
            const SizedBox(width: 8),
            FilterFieldChip(
              label: _ratingLabel(controller),
              icon: Icons.star_outline,
              isActive: controller.selectedRating.value > 0,
              onPressed: () =>
                  RatingFilterBottomSheet.show(context, controller),
            ),
          ],
        );
      }),
    );
  }
}

class TurfSearchSection extends StatelessWidget {
  final TurfListController controller;

  const TurfSearchSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(AppColors.primaryColor),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: QuickFiltersRow(controller: controller),
    );
  }
}
