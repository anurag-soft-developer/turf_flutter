import 'package:get/get.dart';
import 'nav_tabs.dart';

class NavigationController extends GetxController {
  final RxInt _currentIndex = 0.obs;
  final RxDouble _slideValue = 0.0.obs;

  int get currentIndex => _currentIndex.value;
  double get slideValue => _slideValue.value;
  int get tabCount => kNavTabs.length;

  void changeTab(int index) {
    if (_currentIndex.value != index && index >= 0 && index < tabCount) {
      _currentIndex.value = index;
      _loadControllerForCurrentTab();
    }
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
    _cleanupPreviousControllers();
    kNavTabs[_currentIndex.value].loadController?.call();
  }

  void _cleanupPreviousControllers() {
    try {
      for (final tab in kNavTabs) {
        tab.disposeController?.call();
      }
    } catch (e) {
      // Controllers might already be disposed
    }
  }

  @override
  void onInit() {
    super.onInit();
    _loadControllerForCurrentTab();
  }
}
