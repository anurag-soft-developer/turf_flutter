import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../core/config/constants.dart';

/// Page-level pull-to-refresh over hero + pinned tabs.
///
/// Tab bars stay tappable; horizontal swipe is omitted so a vertical pull
/// is never claimed by a [TabBarView].
class ProfileScrollScaffold extends HookWidget {
  const ProfileScrollScaffold({
    super.key,
    required this.onRefresh,
    required this.hero,
    required this.badges,
    required this.outerTabController,
    required this.photosSliver,
    required this.statsSliver,
  });

  final Future<void> Function() onRefresh;
  final Widget hero;
  final Widget badges;
  final TabController outerTabController;

  /// Must be a sliver (e.g. [SliverGrid], [SliverToBoxAdapter]).
  final Widget photosSliver;

  /// Must be a sliver.
  final Widget statsSliver;

  @override
  Widget build(BuildContext context) {
    useListenable(outerTabController);
    final isPhotos = outerTabController.index == 0;

    // Dashboard body starts below the AppBar (edgeOffset 0). Profile uses
    // extendBodyBehindAppBar, so shift the indicator origin to the AppBar's
    // bottom edge — same "pop from under the bar" animation.
    final edgeOffset =
        Scaffold.maybeOf(context)?.appBarMaxHeight ??
        MediaQuery.paddingOf(context).top + kToolbarHeight;

    return RefreshIndicator(
      edgeOffset: edgeOffset,
      displacement: 40,
      color: const Color(AppColors.primaryColor),
      backgroundColor: Colors.white,
      elevation: 2,
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: hero),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                badges,
                const SizedBox(height: 24),
              ],
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _PinnedTabBarDelegate(
              tabBar: TabBar(
                controller: outerTabController,
                labelColor: const Color(AppColors.primaryColor),
                unselectedLabelColor: const Color(
                  AppColors.textSecondaryColor,
                ),
                indicatorColor: const Color(AppColors.primaryColor),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.grid_on_outlined, size: 20),
                    text: 'Photos',
                  ),
                  Tab(
                    icon: Icon(Icons.bar_chart_outlined, size: 20),
                    text: 'Stats',
                  ),
                ],
              ),
            ),
          ),
          if (isPhotos) photosSliver else statsSliver,
        ],
      ),
    );
  }
}

class _PinnedTabBarDelegate extends SliverPersistentHeaderDelegate {
  _PinnedTabBarDelegate({required this.tabBar});

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: Colors.white,
      elevation: overlapsContent ? 1 : 0,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}
