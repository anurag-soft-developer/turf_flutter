import 'package:get/get.dart';
import '../controllers/turf_list_controller.dart';

class TurfListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TurfListController>(() => TurfListController());
  }
}
