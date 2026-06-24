import 'package:get/get.dart';
import '../dashboard/player/dashboard_leaderboard_controller.dart';
import '../turf/feed/turf_list_controller.dart';

class TurfListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TurfListController>(() => TurfListController(), fenix: true);
    Get.lazyPut<DashboardLeaderboardController>(
      () => DashboardLeaderboardController(),
      fenix: true,
    );
  }
}
