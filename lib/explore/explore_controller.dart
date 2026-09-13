import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/components/bottom_navigation_panel/navigation_controller.dart';
import 'model/explore_category.dart';
import 'model/explore_filters.dart';

class ExploreController extends GetxController
    with GetSingleTickerProviderStateMixin {
  ExploreController({this.includeAll = false})
      : category = Rx(
          includeAll ? ExploreCategory.all : ExploreCategory.post,
        );

  static const searchTag = 'search';

  static ExploreController get instance => Get.find();

  static ExploreController get search =>
      Get.find<ExploreController>(tag: searchTag);

  static const concreteTabs = <ExploreCategory>[
    ExploreCategory.post,
    ExploreCategory.match,
    ExploreCategory.team,
    ExploreCategory.player,
  ];

  final bool includeAll;
  final Rx<ExploreCategory> category;
  final Rx<ExploreFilters> filters = ExploreFilters.all.obs;

  late final TabController tabController;
  Worker? _pendingWorker;

  List<ExploreCategory> get tabs => [
        if (includeAll) ExploreCategory.all,
        ...concreteTabs,
      ];

  @override
  void onInit() {
    super.onInit();
    final initialIndex = tabs.indexOf(category.value).clamp(0, tabs.length - 1);
    tabController = TabController(
      length: tabs.length,
      vsync: this,
      initialIndex: initialIndex,
    );
    tabController.addListener(_onTabChanged);

    if (!includeAll && Get.isRegistered<NavigationController>()) {
      final nav = Get.find<NavigationController>();
      applyPending(nav.takePendingExplore());
      _pendingWorker = ever(nav.pendingExplore, (_) {
        applyPending(nav.takePendingExplore());
      });
    }
  }

  @override
  void onClose() {
    _pendingWorker?.dispose();
    tabController.removeListener(_onTabChanged);
    tabController.dispose();
    super.onClose();
  }

  void _onTabChanged() {
    if (tabController.indexIsChanging) return;
    final index = tabController.index;
    if (index >= 0 && index < tabs.length) {
      selectCategory(tabs[index], resetFilters: includeAll);
    }
  }

  void selectTabIndex(int index) {
    if (index < 0 || index >= tabs.length) return;
    selectCategory(tabs[index], resetFilters: includeAll);
  }

  void selectCategory(ExploreCategory next, {bool resetFilters = false}) {
    if (!tabs.contains(next)) return;
    if (category.value != next) {
      category.value = next;
      if (resetFilters) {
        filters.value = ExploreFilters.all;
      }
    }
    final index = tabs.indexOf(next);
    if (index >= 0 &&
        tabController.index != index &&
        !tabController.indexIsChanging) {
      tabController.animateTo(index);
    }
  }

  void setFilters(ExploreFilters next) {
    filters.value = next;
  }

  void applyPending(PendingExploreNav? pending) {
    if (pending == null) return;
    if (pending.category != null) {
      selectCategory(pending.category!);
    }
    if (pending.teamOpenForMatch != null) {
      filters.value = filters.value.copyWith(
        teamOpenForMatch: pending.teamOpenForMatch,
      );
    }
  }
}
