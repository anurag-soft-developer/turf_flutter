import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../components/shared/app_segmented_tabs/app_segmented_tabs.dart';
import '../components/shared/user_avatar_app_bar_action.dart';
import '../core/components/scroll/floating_sliver_app_bar.dart';
import '../core/config/constants.dart';
import '../openings/opening_manage.dart';
import '../settings/settings_controller.dart';
import 'explore_controller.dart';
import 'search/explore_search_category_tabs.dart';
import 'widgets/explore_category_page.dart';
import 'widgets/explore_feed_body.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ExploreController.instance;
    final settings = Get.find<SettingsController>();

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      body: ExtendedNestedScrollView(
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
                PopupMenuButton<String>(
                  tooltip: 'Create',
                  icon: const Icon(Icons.add),
                  color: Colors.white,
                  onSelected: (value) {
                    if (value == 'media') {
                      Get.toNamed(AppConstants.routes.createPost);
                    } else if (value == 'opening') {
                      openPostOpening(context);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'media',
                      child: _CreateMenuLabel(
                        icon: Icons.add_a_photo_outlined,
                        label: 'New Post',
                      ),
                    ),
                    PopupMenuItem(
                      value: 'opening',
                      child: _CreateMenuLabel(
                        icon: Icons.campaign_outlined,
                        label: 'New Opening',
                      ),
                    ),
                  ],
                ),
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
                          return ExploreFeedBody(
                            key: ValueKey(
                              'feed|${tab.apiValue}|${filters.toQueryKeyParts().join(',')}|${location?.latitude}|${location?.longitude}',
                            ),
                            mode: 'feed',
                            category: tab,
                            filters: filters,
                            location: location,
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

class _CreateMenuLabel extends StatelessWidget {
  const _CreateMenuLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    const color = Color(AppColors.textColor);
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: color)),
      ],
    );
  }
}

