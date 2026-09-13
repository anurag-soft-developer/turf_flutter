import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';

import '../components/shared/user_avatar_app_bar_action.dart';
import '../core/components/bottom_navigation_panel/navigation_controller.dart';
import '../core/components/scroll/floating_sliver_app_bar.dart';
import '../core/components/scroll/pinned_sliver_header.dart';
import '../core/config/constants.dart';
import '../settings/settings_controller.dart';
import 'model/explore_category.dart';
import 'model/explore_filters.dart';
import 'search/explore_search_category_tabs.dart';
import 'search/explore_search_filters_bar.dart';
import 'widgets/explore_feed_body.dart';

void _applyPendingExplore(
  NavigationController nav,
  ValueNotifier<ExploreCategory> category,
  ValueNotifier<ExploreFilters> filters,
) {
  final pending = nav.takePendingExplore();
  if (pending == null) return;
  if (pending.category != null) {
    category.value = pending.category!;
  }
  if (pending.teamOpenForMatch != null) {
    filters.value = filters.value.copyWith(
      teamOpenForMatch: pending.teamOpenForMatch,
    );
  }
}

class ExploreScreen extends HookWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final category = useState(ExploreCategory.post);
    final filters = useState(ExploreFilters.all);
    final settings = Get.find<SettingsController>();

    useEffect(() {
      if (!Get.isRegistered<NavigationController>()) return null;
      final nav = Get.find<NavigationController>();
      _applyPendingExplore(nav, category, filters);
      final worker = ever(nav.pendingExplore, (_) {
        _applyPendingExplore(nav, category, filters);
      });
      return worker.dispose;
    }, const []);

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      body: Obx(() {
        final location = settings.nearbyLocation.value;
        return ExploreFeedBody(
          key: ValueKey(
            '${category.value.apiValue}|${filters.value.toQueryKeyParts().join(',')}|${location?.latitude}|${location?.longitude}',
          ),
          mode: 'feed',
          category: category.value,
          filters: filters.value,
          location: location,
          leadingSlivers: [
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
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
