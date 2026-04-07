import 'package:get/get.dart';
import '../../../settings/settings_controller.dart';
import '../../../turf/feed/turf_list_controller.dart';
import '../../../team/feed/teams_ranking_controller.dart';
import '../../../profile/profile_controller.dart';

class NavigationController extends GetxController {
  final RxInt _currentIndex = 0.obs;
  final RxDouble _slideValue = 0.0.obs;

  int get currentIndex => _currentIndex.value;
  double get slideValue => _slideValue.value;

  void changeTab(int index) {
    if (_currentIndex.value != index && index >= 0 && index < 6) {
      _currentIndex.value = index;
      _loadControllerForCurrentTab();
    }
  }

  void slideToNext() {
    if (_currentIndex.value < 5) {
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
    // Clean up previous tab controllers (except persistent ones)
    _cleanupPreviousControllers();

    // Load controller for current tab
    switch (_currentIndex.value) {
      case 0: // Dashboard
        _ensureController<SettingsController>(() => SettingsController());
        break;
      case 1: // Turfs
        _ensureController<TurfListController>(() => TurfListController());
        break;
      case 2: // Match Up
        // No controller needed for placeholder
        break;
      case 3: // Teams
        _ensureController<TeamsRankingController>(
          () => TeamsRankingController(),
        );
        break;
      case 4: // Players
        // No controller needed for placeholder
        break;
      case 5: // Profile
        _ensureController<ProfileController>(() => ProfileController());
        break;
    }
  }

  void _ensureController<T extends GetxController>(T Function() controller) {
    if (!Get.isRegistered<T>()) {
      Get.put<T>(controller(), permanent: false);
    }
  }

  void _cleanupPreviousControllers() {
    // Remove non-persistent controllers when switching tabs
    // Keep AuthStateController as it's persistent
    try {
      if (Get.isRegistered<SettingsController>()) {
        Get.delete<SettingsController>();
      }
      if (Get.isRegistered<TurfListController>()) {
        Get.delete<TurfListController>();
      }
      if (Get.isRegistered<TeamsRankingController>()) {
        Get.delete<TeamsRankingController>();
      }
      if (Get.isRegistered<ProfileController>()) {
        Get.delete<ProfileController>();
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
