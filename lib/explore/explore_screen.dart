import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../components/shared/app_segmented_tabs/app_segmented_tabs.dart';
import '../components/shared/create_menu_button.dart';
import '../components/shared/user_avatar_app_bar_action.dart';
import '../core/components/scroll/floating_sliver_app_bar.dart';
import '../core/components/scroll/tab_scroll_to_top.dart';
import '../core/config/constants.dart';
import '../settings/settings_controller.dart';
import 'explore_controller.dart';
import 'search/explore_search_category_tabs.dart';
import 'widgets/explore_category_page.dart';
import 'widgets/explore_feed_body.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _nestedKey = GlobalKey<ExtendedNestedScrollViewState>();
  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    bindTabScrollToTop('Explore', _scrollToTop);
    bindTabRefresh('Explore', _showRefresh);
  }

  @override
  void dispose() {
    unbindTabScrollToTop('Explore', _scrollToTop);
    unbindTabRefresh('Explore', _showRefresh);
    super.dispose();
  }

  Future<bool> _showRefresh() => showTabRefreshIndicator(_refreshIndicatorKey);

  Future<bool> _scrollToTop() {
    final nested = _nestedKey.currentState;
    if (nested == null) return Future.value(false);
    return animateNestedScrollToTop(
      outer: nested.outerController,
      inners: nested.innerPositions,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = ExploreController.instance;
    final settings = Get.find<SettingsController>();

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      body: ExtendedNestedScrollView(
        key: _nestedKey,
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
                const CreateMenuButton(),
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
                      child: ExploreCategoryPage(
                        category: tab,
                        controller: controller,
                        settings: settings,
                        wrapFiltersInMaterial: true,
                        bodyBuilder: (context, {required filters, required location}) {
                          final selected = controller.category.value == tab;
                          return ExploreFeedBody(
                            key: ValueKey(
                              'feed|${tab.apiValue}|${filters.toQueryKeyParts().join(',')}|${location?.latitude}|${location?.longitude}',
                            ),
                            mode: 'feed',
                            category: tab,
                            filters: filters,
                            location: location,
                            refreshIndicatorKey: selected
                                ? _refreshIndicatorKey
                                : null,
                          );
                        },
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

