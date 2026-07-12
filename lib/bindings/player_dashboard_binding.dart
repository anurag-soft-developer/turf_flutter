import 'package:get/get.dart';

import '../dashboard/player/player_dashboard_controller.dart';

class PlayerDashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PlayerDashboardController>(() => PlayerDashboardController());
  }
}
