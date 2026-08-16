import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../components/turf/search_components.dart';
import '../../components/turf/turf_cards.dart';
import '../../core/config/constants.dart';
import '../../core/models/paginated_response.dart';
import '../../core/query/query_keys.dart';
import '../../core/query/query_retry.dart';
import '../../core/components/search/app_search_screen.dart';
import '../../core/services/search/search_history_store.dart';
import '../../settings/settings_controller.dart';
import '../feed/turf_list_controller.dart';
import '../model/turf_model.dart';
import '../turf_service.dart';

class TurfSearchScreen extends StatelessWidget {
  const TurfSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TurfListController>();

    return AppSearchScreen(
      historyScope: SearchHistoryScope.turfs,
      title: 'Search Turfs',
      hintText: 'Search turfs by name',
      headerBuilder: (context, query) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: QuickFiltersRow(controller: controller),
        );
      },
      resultsBuilder: (context, query) => _TurfSearchResults(
        query: query,
        controller: controller,
      ),
    );
  }
}

class _TurfSearchResults extends HookWidget {
  const _TurfSearchResults({
    required this.query,
    required this.controller,
  });

  final String query;
  final TurfListController controller;

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();
    final turfService = TurfService();

    return Obx(() {
      final city = settings.selectedCityLocation.value;
      controller.filterRevision.value;
      final queryKey = QueryKeys.turfSearch(
        search: query,
        sportTypes: controller.selectedSportTypes.toList(),
        amenities: controller.selectedAmenities.toList(),
        city: city == null ? '' : '${city.latitude},${city.longitude}',
        minPrice: controller.minPrice.value,
        maxPrice: controller.maxPrice.value,
        minRating: controller.selectedRating.value,
        sortBy: controller.sortBy.value,
      );

      return _TurfSearchQueryBody(
        key: ValueKey(queryKey.join('|')),
        queryKey: queryKey,
        query: query,
        controller: controller,
        turfService: turfService,
      );
    });
  }
}

class _TurfSearchQueryBody extends HookWidget {
  const _TurfSearchQueryBody({
    super.key,
    required this.queryKey,
    required this.query,
    required this.controller,
    required this.turfService,
  });

  final List<Object?> queryKey;
  final String query;
  final TurfListController controller;
  final TurfService turfService;

  @override
  Widget build(BuildContext context) {
    final turfsQuery =
        useInfiniteQuery<PaginatedResponse<TurfModel>, Object, int>(
      queryKey,
      (ctx) async {
        final response = await turfService.searchTurfs(
          globalSearchText: query,
          sportTypes: controller.selectedSportTypes.isNotEmpty
              ? controller.selectedSportTypes.toList()
              : null,
          amenities: controller.selectedAmenities.isNotEmpty
              ? controller.selectedAmenities.toList()
              : null,
          location: controller.settings.selectedCityLocation.value,
          minPrice:
              controller.minPrice.value > 0 ? controller.minPrice.value : null,
          maxPrice: controller.maxPrice.value < 5000
              ? controller.maxPrice.value
              : null,
          minRating: controller.selectedRating.value > 0
              ? controller.selectedRating.value
              : null,
          page: ctx.pageParam,
          limit: 10,
          sort: controller.sortBy.value,
        );
        return response ?? EmptyPaginatedResponse<TurfModel>();
      },
      initialPageParam: 1,
      retry: noRetry,
      nextPageParamBuilder: (data) {
        final last = data.pages.isNotEmpty ? data.pages.last : null;
        if (last == null || !last.hasNextPage) return null;
        return last.page + 1;
      },
    );

    final turfs =
        turfsQuery.data?.pages.expand((p) => p.data).toList() ??
        const <TurfModel>[];

    return RefreshIndicator(
      onRefresh: () => turfsQuery.refetch(),
      child: _buildList(turfsQuery, turfs),
    );
  }

  Widget _buildList(
    InfiniteQueryResult<PaginatedResponse<TurfModel>, Object, int> queryResult,
    List<TurfModel> turfs,
  ) {
    if (turfs.isEmpty &&
        (queryResult.isLoading ||
            (queryResult.isFetching && queryResult.data == null))) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Color(AppColors.primaryColor),
              ),
            ),
          ),
        ],
      );
    }

    if (queryResult.isError && turfs.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Center(
            child: ElevatedButton(
              onPressed: () => queryResult.refetch(),
              child: const Text('Retry'),
            ),
          ),
        ],
      );
    }

    if (turfs.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 320,
            child: EmptyTurfsView(onClearFilters: controller.clearFilters),
          ),
        ],
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 200) {
          if (queryResult.hasNextPage && !queryResult.isFetchingNextPage) {
            queryResult.fetchNextPage();
          }
        }
        return false;
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: turfs.length + (queryResult.isFetchingNextPage ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == turfs.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color(AppColors.primaryColor),
                  ),
                ),
              ),
            );
          }

          final turf = turfs[index];
          return TurfListCard(
            turf: turf,
            onTap: () => controller.navigateToTurfDetail(turf),
          );
        },
      ),
    );
  }
}
