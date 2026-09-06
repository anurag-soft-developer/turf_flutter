import 'package:get/get.dart';

import '../../../turf/feed/turf_list_controller.dart';
import 'nav_tabs.dart';

class NavigationController extends GetxController {
  final RxInt _currentIndex = 0.obs;
  final RxDouble _slideValue = 0.0.obs;
  final RxnString pendingSportFilter = RxnString();

  int get currentIndex => _currentIndex.value;
  double get slideValue => _slideValue.value;
  List<NavTab> get activeTabs => kNavTabs;
  int get tabCount => activeTabs.length;

  void changeTab(int index) {
    if (index < 0 || index >= tabCount) return;

    // Same tab tapped again → refresh that tab's data.
    if (_currentIndex.value == index) {
      activeTabs[index].onRetap?.call();
      return;
    }

    // Keep previous tab controllers alive so IndexedStack can restore scroll/UI.
    _currentIndex.value = index;
    _loadControllerForCurrentTab();
  }

  /// Switches to the Turfs tab and optionally applies a sport filter.
  void goToTurfs({String? sportFilter}) {
    final turfsIndex = kNavTabs.indexWhere((tab) => tab.label == 'Turfs');
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

  String? takePendingSportFilter() {
    final value = pendingSportFilter.value;
    pendingSportFilter.value = null;
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

  void _loadControllerForCurrentTab() {
    activeTabs[_currentIndex.value].loadController?.call();
  }

  @override
  void onInit() {
    super.onInit();
    _loadControllerForCurrentTab();
  }
}
