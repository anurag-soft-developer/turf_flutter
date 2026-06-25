import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/config/constants.dart';
import '../../turf/feed/turf_list_controller.dart';
import '../../core/components/bottom_sheets/city_picker_bottom_sheet.dart';
import '../shared/custom_text_field.dart';

class TurfSearchBar extends StatelessWidget {
  final TurfListController controller;

  const TurfSearchBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller.searchController,
      hintText: 'Search turfs by name',
      prefixIcon: const Icon(Icons.search, color: Colors.grey),
      suffixIcon: Obx(
        () => controller.isSearching.value
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                ),
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
    final foregroundColor = isSelected
        ? Colors.white
        : const Color(AppColors.primaryColor);

    return FilterChip(
      avatar: icon == null
          ? null
          : Icon(icon, size: 16, color: foregroundColor),
      label: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.white,
      selectedColor: const Color(AppColors.secondaryColor),
      checkmarkColor: Colors.white,
      showCheckmark: icon == null,
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
            ActionChip(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              avatar: const Icon(
                Icons.location_city,
                size: 16,
                color: Color(AppColors.primaryColor),
              ),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 140),
                    child: Text(
                      cityLabel,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(AppColors.primaryColor),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_drop_down,
                    color: Color(AppColors.primaryColor),
                  ),
                ],
              ),
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(AppColors.primaryColor)),
              onPressed: () => _showCityPickerBottomSheet(context),
            ),
            const SizedBox(width: 8),
            ...controller.availableSportTypes
                .map(
                  (sport) => Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: QuickFilterChip(
                      label: sport.label,
                      icon: sport.icon,
                      isSelected:
                          controller.selectedSportTypes.contains(sport.id),
                      onTap: () => controller.toggleSportType(sport.id),
                    ),
                  ),
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
