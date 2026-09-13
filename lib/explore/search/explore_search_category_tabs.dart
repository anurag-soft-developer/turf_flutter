import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../components/shared/app_segmented_tabs/app_segmented_tabs.dart';
import '../explore_controller.dart';
import '../model/explore_category.dart';

class ExploreSearchCategoryTabs extends StatelessWidget {
  const ExploreSearchCategoryTabs({super.key, this.tag});

  final String? tag;

  static String label(ExploreCategory value) => switch (value) {
        ExploreCategory.all => 'All',
        ExploreCategory.match => 'Matches',
        ExploreCategory.team => 'Teams',
        ExploreCategory.player => 'Players',
        ExploreCategory.post => 'Posts',
      };

  static IconData icon(ExploreCategory value) => switch (value) {
        ExploreCategory.all => Icons.grid_view_rounded,
        ExploreCategory.match => Icons.sports_outlined,
        ExploreCategory.team => Icons.groups_outlined,
        ExploreCategory.player => Icons.person_outline,
        ExploreCategory.post => Icons.dynamic_feed_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ExploreController>(tag: tag);

    return AppSegmentedTabs(
      controller: controller.tabController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      onTap: controller.selectTabIndex,
      items: [
        for (final tab in controller.tabs)
          AppTabItem(label: label(tab), icon: icon(tab)),
      ],
    );
  }
}
