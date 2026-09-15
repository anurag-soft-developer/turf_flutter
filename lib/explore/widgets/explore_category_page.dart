import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/config/constants.dart';
import '../../core/models/location_model.dart';
import '../../settings/settings_controller.dart';
import '../explore_controller.dart';
import '../model/explore_category.dart';
import '../model/explore_filters.dart';
import '../search/explore_search_filters_bar.dart';

typedef ExploreCategoryBodyBuilder = Widget Function(
  BuildContext context, {
  required ExploreFilters filters,
  required LocationModel? location,
});

/// Per-tab chrome: filters slide with the page so tab switches don't resize a
/// shared header.
class ExploreCategoryPage extends StatelessWidget {
  const ExploreCategoryPage({
    super.key,
    required this.category,
    required this.controller,
    required this.settings,
    required this.bodyBuilder,
    this.wrapFiltersInMaterial = false,
  });

  final ExploreCategory category;
  final ExploreController controller;
  final SettingsController settings;
  final ExploreCategoryBodyBuilder bodyBuilder;
  final bool wrapFiltersInMaterial;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Obx(() {
          final bar = ExploreSearchFiltersBar(
            category: category,
            filters: controller.filters.value,
            onChanged: controller.setFilters,
          );
          if (!wrapFiltersInMaterial) return bar;
          return Material(
            color: const Color(AppColors.surfaceColor),
            child: bar,
          );
        }),
        Expanded(
          child: Obx(() {
            return bodyBuilder(
              context,
              filters: controller.filters.value,
              location: settings.nearbyLocation.value,
            );
          }),
        ),
      ],
    );
  }
}
