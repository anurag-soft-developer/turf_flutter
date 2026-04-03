import 'package:get/get.dart';
import '../turf/details/turf_detail_controller.dart';
import '../turf/my_turves/turf_management_controller.dart';

class ManageTurfBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TurfDetailController>(() => TurfDetailController());
    if (!Get.isRegistered<TurfManagementController>()) {
      Get.lazyPut<TurfManagementController>(
        () => TurfManagementController(),
        fenix: true,
      );
    }
  }
}
