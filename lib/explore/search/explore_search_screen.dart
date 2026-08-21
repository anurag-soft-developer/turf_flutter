import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';

import '../../core/components/search/app_search_screen.dart';
import '../../core/services/search/search_history_store.dart';
import '../../settings/settings_controller.dart';
import '../model/explore_category.dart';
import '../model/explore_filters.dart';
import '../widgets/explore_feed_body.dart';
import 'explore_search_all_body.dart';
import 'explore_search_category_tabs.dart';
import 'explore_search_filters_bar.dart';

class ExploreSearchScreen extends HookWidget {
  const ExploreSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final category = useState(ExploreCategory.all);
    final filters = useState(ExploreFilters.all);
    final settings = Get.find<SettingsController>();

    return AppSearchScreen(
      historyScope: SearchHistoryScope.explore,
      hintText: 'Search matches, teams, players, or posts',
      headerBuilder: (context, query) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExploreSearchCategoryTabs(
              category: category.value,
              includeAll: true,
              onChanged: (next) {
                category.value = next;
                filters.value = ExploreFilters.all;
              },
            ),
            ExploreSearchFiltersBar(
              category: category.value,
              filters: filters.value,
              onChanged: (next) => filters.value = next,
            ),
          ],
        );
      },
      resultsBuilder: (context, query) {
        final activeCategory = category.value;
        final activeFilters = filters.value;

        return Obx(() {
          final location = settings.nearbyLocation.value;
          if (activeCategory == ExploreCategory.all) {
            return ExploreSearchAllBody(
              key: ValueKey(
                'search-all|$query|${activeFilters.toQueryKeyParts().join(',')}|${location?.latitude}|${location?.longitude}',
              ),
              q: query,
              filters: activeFilters,
              location: location,
              onViewMore: (next) => category.value = next,
            );
          }
          return ExploreFeedBody(
            key: ValueKey(
              'search|$query|${activeCategory.apiValue}|${activeFilters.toQueryKeyParts().join(',')}|${location?.latitude}|${location?.longitude}',
            ),
            mode: 'search',
            category: activeCategory,
            filters: activeFilters,
            q: query,
            location: location,
            emptyTitle: 'No results found',
            emptySubtitle:
                'Try another keyword or switch the category filter.',
            emptyIcon: Icons.search_off_outlined,
            errorMessage: 'Failed to load search results',
          );
        });
      },
    );
  }
}
