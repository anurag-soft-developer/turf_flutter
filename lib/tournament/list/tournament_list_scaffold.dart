import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';

import '../../components/shared/app_segmented_tabs/app_segmented_tabs.dart';
import '../../core/components/scroll/floating_sliver_app_bar.dart';
import '../../core/components/scroll/pinned_sliver_header.dart';
import 'tournament_list_controller.dart';

/// App bar + segmented tabs + optional sub-filters for tournament lists.
class TournamentListScaffold extends HookWidget {
  const TournamentListScaffold({
    super.key,
    required this.title,
    required this.controller,
    required this.tabs,
    required this.initialTabIndex,
    required this.onTabChanged,
    required this.buildPanes,
    this.belowTabs,
  });

  final String title;
  final TournamentListController controller;
  final List<AppTabItem> tabs;
  final int initialTabIndex;
  final ValueChanged<int> onTabChanged;
  final List<Widget> Function(String sportFilterKey) buildPanes;
  final Widget? belowTabs;

  @override
  Widget build(BuildContext context) {
    final ticker = useSingleTickerProvider();
    final safeInitial = initialTabIndex.clamp(0, tabs.length - 1);
    final tabController = useMemoized(
      () => TabController(
        length: tabs.length,
        vsync: ticker,
        initialIndex: safeInitial,
      ),
      [ticker],
    );

    useEffect(() {
      void listener() {
        if (tabController.indexIsChanging) return;
        onTabChanged(tabController.index);
      }

      tabController.addListener(listener);
      return () {
        tabController.removeListener(listener);
        tabController.dispose();
      };
    }, [tabController]);

    return Obx(() {
      final sportKey = controller.sportFilter.value?.name ?? 'all';

      return NestedScrollView(
        floatHeaderSlivers: true,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            FloatingSliverAppBar(title: Text(title)),
            PinnedSliverHeader(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: AppSegmentedTabs(
                      controller: tabController,
                      onTap: onTabChanged,
                      padding: EdgeInsets.zero,
                      fillWidth: true,
                      items: tabs,
                    ),
                  ),
                  if (belowTabs != null) belowTabs!,
                ],
              ),
            ),
          ];
        },
        body: AppSegmentedTabView(
          controller: tabController,
          children: buildPanes(sportKey),
        ),
      );
    });
  }
}
