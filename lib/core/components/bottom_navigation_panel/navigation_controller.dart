import 'dart:async';

import 'package:get/get.dart';

import '../../../explore/model/explore_category.dart';
import '../../../turf/feed/turf_list_controller.dart';
import '../../config/constants.dart';
import 'nav_tabs.dart';

class PendingExploreNav {
  const PendingExploreNav({this.category});

  final ExploreCategory? category;
}

class NavigationController extends GetxController {
  final RxInt _currentIndex = kDefaultNavTabIndex.obs;
  final RxDouble _slideValue = 0.0.obs;
  final RxnString pendingSportFilter = RxnString();
  final Rxn<PendingExploreNav> pendingExplore = Rxn();

  int get currentIndex => _currentIndex.value;
  double get slideValue => _slideValue.value;
  List<NavTab> get activeTabs => kNavTabs;
  int get tabCount => activeTabs.length;

  /// Latest handler wins so a pushed copy of a tab screen does not replace
  /// the tab's handler permanently.
  final Map<String, List<Future<bool> Function()>> _scrollToTop = {};
  final Map<String, List<Future<bool> Function()>> _tabRefresh = {};
  int _retapGeneration = 0;

  void bindScrollToTop(String label, Future<bool> Function() action) {
    _bind(_scrollToTop, label, action);
  }

  void unbindScrollToTop(String label, Future<bool> Function() action) {
    _unbind(_scrollToTop, label, action);
  }

  void bindTabRefresh(String label, Future<bool> Function() action) {
    _bind(_tabRefresh, label, action);
  }

  void unbindTabRefresh(String label, Future<bool> Function() action) {
    _unbind(_tabRefresh, label, action);
  }

  void _bind(
    Map<String, List<Future<bool> Function()>> handlersByLabel,
    String label,
    Future<bool> Function() action,
  ) {
    final handlers = handlersByLabel.putIfAbsent(label, () => []);
    handlers.remove(action);
    handlers.add(action);
  }

  void _unbind(
    Map<String, List<Future<bool> Function()>> handlersByLabel,
    String label,
    Future<bool> Function() action,
  ) {
    final handlers = handlersByLabel[label];
    if (handlers == null) return;
    handlers.remove(action);
    if (handlers.isEmpty) handlersByLabel.remove(label);
  }

  Future<bool> Function()? _latest(
    Map<String, List<Future<bool> Function()>> handlersByLabel,
    String label,
  ) {
    final handlers = handlersByLabel[label];
    if (handlers == null || handlers.isEmpty) return null;
    return handlers.last;
  }

  void changeTab(int index) {
    if (index < 0 || index >= tabCount) return;

    // Same tab tapped again → scroll to top, or refresh if already there.
    if (_currentIndex.value == index) {
      final generation = ++_retapGeneration;
      unawaited(_onSameTab(index, generation));
      return;
    }

    // Keep previous tab controllers alive so IndexedStack can restore scroll/UI.
    _currentIndex.value = index;
    _loadControllerForCurrentTab();
  }

  void goToRank() {
    Get.toNamed(AppConstants.routes.rank);
  }

  /// Switches to the Turfs tab and optionally applies a sport filter.
  void goToTurfs({String? sportFilter}) {
    final turfsIndex = navTabIndex('Turfs');
    if (turfsIndex < 0) return;

    if (sportFilter != null) {
      // Tab/controller may already be alive — apply immediately when possible.
      if (Get.isRegistered<TurfListController>()) {
        Get.find<TurfListController>().setSportFilter(sportFilter);
        pendingSportFilter.value = null;
      } else {
        pendingSportFilter.value = sportFilter;
      }
    }
    changeTab(turfsIndex);
  }

  /// Switches to the Explore tab and optionally applies a category filter.
  void goToExplore({ExploreCategory? category}) {
    final exploreIndex = navTabIndex('Explore');
    if (exploreIndex < 0) return;

    if (category != null) {
      pendingExplore.value = PendingExploreNav(category: category);
    }
    changeTab(exploreIndex);
  }

  String? takePendingSportFilter() {
    final value = pendingSportFilter.value;
    pendingSportFilter.value = null;
    return value;
  }

  PendingExploreNav? takePendingExplore() {
    final value = pendingExplore.value;
    pendingExplore.value = null;
    return value;
  }

  void slideToNext() {
    if (_currentIndex.value < tabCount - 1) {
      changeTab(_currentIndex.value + 1);
    }
  }

  void slideToPrevious() {
    if (_currentIndex.value > 0) {
      changeTab(_currentIndex.value - 1);
    }
  }

  void updateSlideValue(double value) {
    _slideValue.value = value;
  }

  Future<void> _onSameTab(int index, int generation) async {
    final label = activeTabs[index].label;
    final scrolled = await _latest(_scrollToTop, label)?.call() ?? false;
    if (generation != _retapGeneration || _currentIndex.value != index) {
      return;
    }
    if (scrolled) return;

    final shown = await _latest(_tabRefresh, label)?.call() ?? false;
    if (generation != _retapGeneration || _currentIndex.value != index) {
      return;
    }
    if (!shown) {
      await activeTabs[index].onRetap?.call();
    }
  }

  void _loadControllerForCurrentTab() {
    activeTabs[_currentIndex.value].loadController?.call();
  }

  @override
  void onInit() {
    super.onInit();
    _loadControllerForCurrentTab();
  }
}
