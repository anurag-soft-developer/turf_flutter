import 'package:get/get.dart';

import 'casual_match_start_controller.dart';

class CasualMatchStartBinding extends Bindings {
  @override
  void dependencies() {
    if (Get.isRegistered<CasualMatchStartController>()) {
      Get.delete<CasualMatchStartController>(force: true);
    }
    Get.put(CasualMatchStartController());
  }
}
