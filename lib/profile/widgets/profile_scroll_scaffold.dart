import 'package:flutter/material.dart';

import '../../core/config/constants.dart';

/// Collapsing header + swipeable Photos/Stats.
class ProfileScrollScaffold extends StatelessWidget {
  const ProfileScrollScaffold({
    super.key,
    required this.header,
    required this.outerTabController,
    required this.photosSliver,
    required this.statsSliver,
  });

  final Widget header;
  final TabController outerTabController;

  /// Must be a sliver (e.g. [SliverGrid], [SliverToBoxAdapter]).
  final Widget photosSliver;

  /// Must be a sliver.
  final Widget statsSliver;

  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverToBoxAdapter(child: header),
          SliverToBoxAdapter(
            child: Material(
              color: Colors.white,
              child: TabBar(
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
        ];
      },
      body: TabBarView(
        controller: outerTabController,
        children: [
          _TabScroll(
            tabIndex: 0,
            tabController: outerTabController,
            sliver: photosSliver,
          ),
          _TabScroll(
            tabIndex: 1,
            tabController: outerTabController,
            sliver: statsSliver,
          ),
        ],
      ),
    );
  }
}

class _TabScroll extends StatefulWidget {
  const _TabScroll({
    required this.tabIndex,
    required this.tabController,
    required this.sliver,
  });

  final int tabIndex;
  final TabController tabController;
  final Widget sliver;

  @override
  State<_TabScroll> createState() => _TabScrollState();
}

class _TabScrollState extends State<_TabScroll> {
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _isActive = widget.tabController.index == widget.tabIndex;
    widget.tabController.addListener(_syncActive);
  }

  @override
  void didUpdateWidget(covariant _TabScroll oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabController != widget.tabController) {
      oldWidget.tabController.removeListener(_syncActive);
      widget.tabController.addListener(_syncActive);
    }
    _syncActive();
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_syncActive);
    super.dispose();
  }

  void _syncActive() {
    final active = widget.tabController.index == widget.tabIndex;
    if (active == _isActive) return;
    setState(() => _isActive = active);
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      // NestedScrollView's inner controller can attach to only one view.
      primary: _isActive,
      slivers: [widget.sliver],
    );
  }
}
