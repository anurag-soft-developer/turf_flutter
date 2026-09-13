import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../components/shared/app_segmented_tabs/app_segmented_tabs.dart';
import '../components/shared/user_avatar_app_bar_action.dart';
import '../core/components/scroll/floating_sliver_app_bar.dart';
import '../core/components/scroll/pinned_sliver_header.dart';
import '../core/config/constants.dart';
import '../settings/settings_controller.dart';
import 'explore_controller.dart';
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
      body: NestedScrollView(
        floatHeaderSlivers: true,
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
            PinnedSliverHeader.surfaceCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const ExploreSearchCategoryTabs(),
                  Obx(
                    () => ExploreSearchFiltersBar(
                      category: controller.category.value,
                      filters: controller.filters.value,
                      onChanged: controller.setFilters,
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
        body: Obx(() {
          final location = settings.nearbyLocation.value;
          final filters = controller.filters.value;
          return AppSegmentedTabView(
            controller: controller.tabController,
            children: [
              for (final tab in controller.tabs)
                ExploreFeedBody(
                  key: ValueKey(
                    'feed|${tab.apiValue}|${filters.toQueryKeyParts().join(',')}|${location?.latitude}|${location?.longitude}',
                  ),
                  mode: 'feed',
                  category: tab,
                  filters: filters,
                  location: location,
                ),
            ],
          );
        }),
      ),
    );
  }
}
