import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../../core/models/location_model.dart';
import '../../settings/settings_controller.dart';

/// Resolves GPS/permission for the player dashboard. Data fetching is owned by
/// flutter_query on [PlayerDashboard].
class PlayerDashboardController extends GetxController {
  /// Location passed to `GET /dashboard/player`, or null when permission denied.
  final Rxn<LocationModel> dashboardLocation = Rxn<LocationModel>();

  /// True after the first [resolveLocation] attempt completes.
  final RxBool isLocationReady = false.obs;

  final RxBool isResolvingLocation = false.obs;

  /// Unread inbox count from the latest player dashboard payload.
  final RxInt unreadNotificationCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    resolveLocation();
  }

  void decrementUnreadNotificationCount([int by = 1]) {
    if (by <= 0) return;
    final next = unreadNotificationCount.value - by;
    unreadNotificationCount.value = next < 0 ? 0 : next;
  }

  void incrementUnreadNotificationCount([int by = 1]) {
    if (by <= 0) return;
    unreadNotificationCount.value += by;
  }

  void clearUnreadNotificationCount() {
    unreadNotificationCount.value = 0;
  }

  Future<void> resolveLocation() async {
    if (isResolvingLocation.value) return;
    isResolvingLocation.value = true;
    try {
      final settings = Get.find<SettingsController>();
      await settings.detectCurrentCityLocation(requestPermission: true);

      final permission = await Geolocator.checkPermission();
      final granted =
          permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;

      dashboardLocation.value =
          granted ? settings.selectedCityLocation.value : null;
    } finally {
      isResolvingLocation.value = false;
      isLocationReady.value = true;
    }
  }
}
