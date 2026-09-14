import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../components/shared/app_segmented_tabs/app_segmented_tabs.dart';
import '../components/shared/user_avatar_app_bar_action.dart';
import '../core/components/scroll/floating_sliver_app_bar.dart';
import '../core/config/constants.dart';
import '../settings/settings_controller.dart';
import 'explore_controller.dart';
import 'model/explore_category.dart';
import 'search/explore_search_category_tabs.dart';
import 'search/explore_search_filters_bar.dart';
import 'widgets/explore_feed_body.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ExploreController.instance;
    final settings = Get.find<SettingsController>();

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      body: ExtendedNestedScrollView(
        floatHeaderSlivers: true,
        // KeepAlive tabs leave multiple inner positions attached; only scroll
        // the visible one so category offsets stay independent.
        onlyOneScrollInBody: true,
        pinnedHeaderSliverHeightBuilder: () => 0,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            FloatingSliverAppBar(
              leading: const UserAvatarAppBarAction(),
              title: const Text('Explore'),
              actions: [
                IconButton(
                  tooltip: 'Search',
                  icon: const Icon(Icons.search),
                  onPressed: () =>
                      Get.toNamed(AppConstants.routes.exploreSearch),
                ),
              ],
            ),
          ];
        },
        body: Column(
          children: [
            Material(
              color: const Color(AppColors.surfaceColor),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: const Color(
                        AppColors.dividerColor,
                      ).withValues(alpha: 0.7),
                    ),
                  ),
                ),
                child: const ExploreSearchCategoryTabs(),
              ),
            ),
            Expanded(
              child: AppSegmentedTabView(
                controller: controller.tabController,
                children: [
                  for (final tab in controller.tabs)
                    ExtendedVisibilityDetector(
                      uniqueKey: Key('explore-visible-${tab.apiValue}'),
                      child: _ExploreCategoryPage(
                        category: tab,
                        controller: controller,
                        settings: settings,
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

/// Per-tab chrome: filters slide with the page so tab switches don't resize a
/// shared header.
class _ExploreCategoryPage extends StatelessWidget {
  const _ExploreCategoryPage({
    required this.category,
    required this.controller,
    required this.settings,
  });

  final ExploreCategory category;
  final ExploreController controller;
  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Obx(
          () => Material(
            color: const Color(AppColors.surfaceColor),
            child: ExploreSearchFiltersBar(
              category: category,
              filters: controller.filters.value,
              onChanged: controller.setFilters,
            ),
          ),
        ),
        Expanded(
          child: Obx(() {
            final location = settings.nearbyLocation.value;
            final filters = controller.filters.value;
            return ExploreFeedBody(
              key: ValueKey(
                'feed|${category.apiValue}|${filters.toQueryKeyParts().join(',')}|${location?.latitude}|${location?.longitude}',
              ),
              mode: 'feed',
              category: category,
              filters: filters,
              location: location,
            );
          }),
        ),
      ],
    );
  }
}
