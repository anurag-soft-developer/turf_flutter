import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';

import '../../components/shared/app_search_field.dart';
import '../../core/config/constants.dart';
import '../../settings/settings_controller.dart';
import '../model/explore_category.dart';
import '../model/explore_filters.dart';
import '../widgets/explore_feed_body.dart';
import 'explore_search_all_body.dart';
import 'explore_search_category_tabs.dart';
import 'explore_search_filters_bar.dart';
import 'explore_search_history.dart';
import 'explore_search_history_store.dart';

class ExploreSearchScreen extends HookWidget {
  const ExploreSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final searchController = useTextEditingController();
    final searchText = useState('');
    final debouncedQuery = useState('');
    final category = useState(ExploreCategory.all);
    final filters = useState(ExploreFilters.all);
    final historyItems = useState<List<String>>(const []);
    final settings = Get.find<SettingsController>();

    final historyStore = useMemoized(() => ExploreSearchHistoryStore.instance);

    Future<void> refreshHistory() async {
      historyItems.value = await historyStore.load();
    }

    useEffect(() {
      refreshHistory();
      return null;
    }, const []);

    useEffect(() {
      void listener() {
        searchText.value = searchController.text;
      }

      searchController.addListener(listener);
      return () => searchController.removeListener(listener);
    }, [searchController]);

    useEffect(() {
      final timer = Timer(const Duration(milliseconds: 350), () {
        debouncedQuery.value = searchText.value.trim();
      });
      return timer.cancel;
    }, [searchText.value]);

    useEffect(() {
      final query = debouncedQuery.value;
      if (query.isEmpty) return null;

      historyStore.add(query).then((_) => refreshHistory());
      return null;
    }, [debouncedQuery.value]);

    void applySearch(String term) {
      searchController.text = term;
      searchText.value = term;
      debouncedQuery.value = term.trim();
    }

    final activeCategory = category.value;
    final activeFilters = filters.value;
    final queryText = debouncedQuery.value;
    final canFetch = queryText.isNotEmpty;
    final isDebouncing = searchText.value.trim().isNotEmpty && !canFetch;

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: AppSearchField(
              controller: searchController,
              hintText: 'Search matches, teams, players, or posts',
              autofocus: true,
              onCleared: () {
                searchText.value = '';
                debouncedQuery.value = '';
              },
            ),
          ),
          if (canFetch) ...[
            ExploreSearchCategoryTabs(
              category: activeCategory,
              includeAll: true,
              onChanged: (next) {
                category.value = next;
                filters.value = ExploreFilters.all;
              },
            ),
            ExploreSearchFiltersBar(
              category: activeCategory,
              filters: activeFilters,
              onChanged: (next) => filters.value = next,
            ),
            Expanded(
              child: Obx(() {
                final location = settings.nearbyLocation.value;
                if (activeCategory == ExploreCategory.all) {
                  return ExploreSearchAllBody(
                    key: ValueKey(
                      'search-all|$queryText|${activeFilters.toQueryKeyParts().join(',')}|${location?.latitude}|${location?.longitude}',
                    ),
                    q: queryText,
                    filters: activeFilters,
                    location: location,
                    onViewMore: (next) => category.value = next,
                  );
                }
                return ExploreFeedBody(
                  key: ValueKey(
                    'search|$queryText|${activeCategory.apiValue}|${activeFilters.toQueryKeyParts().join(',')}|${location?.latitude}|${location?.longitude}',
                  ),
                  mode: 'search',
                  category: activeCategory,
                  filters: activeFilters,
                  q: queryText,
                  location: location,
                  emptyTitle: 'No results found',
                  emptySubtitle:
                      'Try another keyword or switch the category filter.',
                  emptyIcon: Icons.search_off_outlined,
                  errorMessage: 'Failed to load search results',
                );
              }),
            ),
          ] else
            Expanded(
              child: isDebouncing
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(AppColors.primaryColor),
                        ),
                      ),
                    )
                  : ExploreSearchHistory(
                      items: historyItems.value,
                      onSelect: applySearch,
                      onRemove: (term) async {
                        await historyStore.remove(term);
                        await refreshHistory();
                      },
                      onClearAll: () async {
                        await historyStore.clear();
                        await refreshHistory();
                      },
                    ),
            ),
        ],
      ),
    );
  }
}
