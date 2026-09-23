import 'package:get/get.dart';

import 'unranked_match_start_controller.dart';

class UnrankedMatchStartBinding extends Bindings {
  @override
  void dependencies() {
    if (Get.isRegistered<UnrankedMatchStartController>()) {
      Get.delete<UnrankedMatchStartController>(force: true);
    }
    Get.put(UnrankedMatchStartController());
  }
}
