import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../components/shared/app_segmented_tabs/app_segmented_tabs.dart';
import '../../core/components/search/app_search_screen.dart';
import '../../core/services/search/search_history_store.dart';
import '../../settings/settings_controller.dart';
import '../explore_controller.dart';
import '../model/explore_category.dart';
import '../widgets/explore_category_page.dart';
import '../widgets/explore_feed_body.dart';
import 'explore_search_all_body.dart';
import 'explore_search_category_tabs.dart';

class ExploreSearchScreen extends StatelessWidget {
  const ExploreSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ExploreController.search;
    final settings = Get.find<SettingsController>();

    return AppSearchScreen(
      historyScope: SearchHistoryScope.explore,
      hintText: 'Search matches, teams, players, or posts',
      headerBuilder: (context, query) {
        return const ExploreSearchCategoryTabs(tag: ExploreController.searchTag);
      },
      resultsBuilder: (context, query) {
        return AppSegmentedTabView(
          controller: controller.tabController,
          children: [
            for (final tab in controller.tabs)
              ExploreCategoryPage(
                category: tab,
                controller: controller,
                settings: settings,
                bodyBuilder: (context, {required filters, required location}) {
                  if (tab == ExploreCategory.all) {
                    return ExploreSearchAllBody(
                      key: ValueKey(
                        'search-all|$query|${filters.toQueryKeyParts().join(',')}|${location?.latitude}|${location?.longitude}',
                      ),
                      q: query,
                      filters: filters,
                      location: location,
                      onViewMore: controller.selectCategory,
                    );
                  }
                  return ExploreFeedBody(
                    key: ValueKey(
                      'search|$query|${tab.apiValue}|${filters.toQueryKeyParts().join(',')}|${location?.latitude}|${location?.longitude}',
                    ),
                    mode: 'search',
                    category: tab,
                    filters: filters,
                    q: query,
                    location: location,
                    emptyTitle: 'No results found',
                    emptySubtitle:
                        'Try another keyword or switch the category filter.',
                    emptyIcon: Icons.search_off_outlined,
                    errorMessage: 'Failed to load search results',
                  );
                },
              ),
          ],
        );
      },
    );
  }
}
