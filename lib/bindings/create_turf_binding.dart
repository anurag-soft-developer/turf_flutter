import 'package:get/get.dart';
import '../controllers/create_turf_controller.dart';

class CreateTurfBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CreateTurfController>(() => CreateTurfController());
  }
}
