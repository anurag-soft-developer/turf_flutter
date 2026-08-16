import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';

import '../components/shared/user_avatar_app_bar_action.dart';
import '../core/config/constants.dart';
import '../settings/settings_controller.dart';
import 'model/explore_category.dart';
import 'model/explore_filters.dart';
import 'search/explore_search_category_tabs.dart';
import 'search/explore_search_filters_bar.dart';
import 'widgets/explore_feed_body.dart';

class ExploreScreen extends HookWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final category = useState(ExploreCategory.match);
    final filters = useState(ExploreFilters.all);
    final settings = Get.find<SettingsController>();

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const UserAvatarAppBarAction(),
        title: const Text('Explore'),
        actions: [
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search),
            onPressed: () => Get.toNamed(AppConstants.routes.exploreSearch),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          ExploreSearchCategoryTabs(
            category: category.value,
            onChanged: (next) => category.value = next,
          ),
          ExploreSearchFiltersBar(
            category: category.value,
            filters: filters.value,
            onChanged: (next) => filters.value = next,
          ),
          Expanded(
            child: Obx(() {
              final location = settings.nearbyLocation.value;
              return ExploreFeedBody(
                key: ValueKey(
                  '${category.value.apiValue}|${filters.value.toQueryKeyParts().join(',')}|${location?.latitude}|${location?.longitude}',
                ),
                mode: 'feed',
                category: category.value,
                filters: filters.value,
                location: location,
              );
            }),
          ),
        ],
      ),
    );
  }
}
