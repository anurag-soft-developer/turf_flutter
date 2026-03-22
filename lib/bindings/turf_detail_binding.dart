import 'package:get/get.dart';
import '../controllers/turf_detail_controller.dart';

class TurfDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TurfDetailController>(() => TurfDetailController());
  }
}
