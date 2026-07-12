import 'package:flutter/material.dart';
import 'package:flutter_application_1/components/shared/user_avatar_app_bar_action.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../components/turf/search_components.dart';
import '../../components/turf/turf_cards.dart';
import '../../core/config/constants.dart';
import '../../core/models/paginated_response.dart';
import '../../core/query/query_keys.dart';
import '../../settings/settings_controller.dart';
import '../model/turf_model.dart';
import '../turf_service.dart';
import 'turf_list_controller.dart';

Duration? _noRetry(int count, Object error) => null;

class TurfListScreen extends StatelessWidget {
  const TurfListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TurfListController controller = Get.find();

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const UserAvatarAppBarAction(),
        title: const Text(
          'Find Turfs',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(AppColors.primaryColor),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          TurfSearchSection(controller: controller),
          Expanded(
            child: Obx(() {
              final settings = Get.find<SettingsController>();
              final city = settings.selectedCityLocation.value;
              final queryKey = QueryKeys.turfSearch(
                search: controller.searchController.text.trim(),
                sportTypes: controller.selectedSportTypes.toList(),
                amenities: controller.selectedAmenities.toList(),
                city: city == null
                    ? ''
                    : '${city.latitude},${city.longitude}',
                minPrice: controller.minPrice.value,
                maxPrice: controller.maxPrice.value,
                minRating: controller.selectedRating.value,
                sortBy: controller.sortBy.value,
              );
              // Touch revision so Obx rebuilds when filters bump without list change.
              controller.filterRevision.value;

              return _TurfListQueryBody(
                key: ValueKey(queryKey.join('|')),
                queryKey: queryKey,
                controller: controller,
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _TurfListQueryBody extends HookWidget {
  const _TurfListQueryBody({
    super.key,
    required this.queryKey,
    required this.controller,
  });

  final List<Object?> queryKey;
  final TurfListController controller;

  @override
  Widget build(BuildContext context) {
    final turfService = TurfService();

    final turfsQuery = useInfiniteQuery<PaginatedResponse<TurfModel>, Object, int>(
      queryKey,
      (ctx) async {
        final response = await turfService.searchTurfs(
          globalSearchText: controller.searchController.text.trim().isNotEmpty
              ? controller.searchController.text.trim()
              : null,
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
      retry: _noRetry,
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
    InfiniteQueryResult<PaginatedResponse<TurfModel>, Object, int> query,
    List<TurfModel> turfs,
  ) {
    if (turfs.isEmpty &&
        (query.isLoading || (query.isFetching && query.data == null))) {
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

    if (query.isError && turfs.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Center(
            child: ElevatedButton(
              onPressed: () => query.refetch(),
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
          if (query.hasNextPage && !query.isFetchingNextPage) {
            query.fetchNextPage();
          }
        }
        return false;
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: turfs.length + (query.isFetchingNextPage ? 1 : 0),
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
