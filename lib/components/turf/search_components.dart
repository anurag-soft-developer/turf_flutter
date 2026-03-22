import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/constants.dart';
import '../../controllers/turf_list_controller.dart';
import '../shared/custom_text_field.dart';

class TurfSearchBar extends StatelessWidget {
  final TurfListController controller;

  const TurfSearchBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller.searchController,
      hintText: 'Search turfs by name, location...',
      prefixIcon: const Icon(Icons.search, color: Colors.grey),
      suffixIcon: Obx(
        () => controller.isSearching.value
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : IconButton(
                onPressed: controller.searchTurfs,
                icon: const Icon(Icons.send),
              ),
      ),
    );
  }
}

class QuickFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const QuickFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected
              ? Colors.white
              : const Color(AppColors.primaryColor),
          fontWeight: FontWeight.w500,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.white,
      selectedColor: const Color(AppColors.secondaryColor),
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected
            ? const Color(AppColors.secondaryColor)
            : const Color(AppColors.primaryColor),
      ),
    );
  }
}

class QuickFiltersRow extends StatelessWidget {
  final TurfListController controller;

  const QuickFiltersRow({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Obx(
        () => Row(
          children: [
            QuickFilterChip(
              label: 'Available Now',
              isSelected: controller.isAvailableOnly.value,
              onTap: controller.toggleAvailabilityFilter,
            ),
            const SizedBox(width: 8),
            QuickFilterChip(
              label: '4+ Rating',
              isSelected: controller.selectedRating >= 4.0,
              onTap: () => controller.updateRating(
                controller.selectedRating >= 4.0 ? 0.0 : 4.0,
              ),
            ),
            const SizedBox(width: 8),
            ...controller.availableSportTypes
                .take(3)
                .map(
                  (sport) => Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: QuickFilterChip(
                      label: sport,
                      isSelected: controller.selectedSportTypes.contains(sport),
                      onTap: () => controller.toggleSportType(sport),
                    ),
                  ),
                ),
          ],
        ),
      ),
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
      child: Column(
        children: [
          TurfSearchBar(controller: controller),
          const SizedBox(height: 12),
          QuickFiltersRow(controller: controller),
        ],
      ),
    );
  }
}
