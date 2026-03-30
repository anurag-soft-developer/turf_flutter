import 'package:get/get.dart';
import '../turf/create/create_turf_controller.dart';

class CreateTurfBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CreateTurfController>(() => CreateTurfController());
  }
}
