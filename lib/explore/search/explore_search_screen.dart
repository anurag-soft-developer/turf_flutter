import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';

import '../../components/shared/app_search_field.dart';
import '../../core/config/constants.dart';
import '../../core/query/query_keys.dart';
import '../../core/query/query_retry.dart';
import '../explore_service.dart';
import '../model/explore_category.dart';
import '../model/explore_filters.dart';
import '../model/explore_item.dart';
import '../widgets/explore_list.dart';
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

    final exploreQuery =
        useInfiniteQuery<ExplorePaginatedResponse, Object, int>(
      QueryKeys.explore(
        mode: 'search',
        category: activeCategory.apiValue,
        q: queryText,
        filterParts: activeFilters.toQueryKeyParts(),
      ),
      (ctx) async {
        final result = await ExploreService().fetch(
          q: queryText,
          category: activeCategory,
          page: ctx.pageParam,
          limit: 20,
          filters: activeFilters,
        );
        return result ??
            ExplorePaginatedResponse(
              data: const [],
              totalDocuments: 0,
              page: ctx.pageParam,
              limit: 20,
              totalPages: 0,
            );
      },
      initialPageParam: 1,
      retry: noRetry,
      enabled: canFetch,
      nextPageParamBuilder: (data) {
        final last = data.pages.isNotEmpty ? data.pages.last : null;
        if (last == null || !last.hasNextPage) return null;
        return last.page + 1;
      },
    );

    final items = canFetch
        ? exploreQuery.data?.pages.expand((p) => p.data).toList() ??
            const <ExploreItem>[]
        : const <ExploreItem>[];

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
              hintText: 'Search matches, teams, or players',
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
              onChanged: (next) => category.value = next,
            ),
            ExploreSearchFiltersBar(
              category: activeCategory,
              filters: activeFilters,
              onChanged: (next) => filters.value = next,
            ),
            Expanded(
              child: ExploreList(
                query: exploreQuery,
                items: items,
                emptyTitle: 'No results found',
                emptySubtitle:
                    'Try another keyword or switch the category filter.',
                emptyIcon: Icons.search_off_outlined,
                errorMessage: 'Failed to load search results',
              ),
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
