import 'package:get/get.dart';
import '../controllers/turf_management_controller.dart';

class TurfManagementBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TurfManagementController>(
      () => TurfManagementController(),
      fenix: true,
    );
  }
}
