import 'package:get/get.dart';

import 'match_start_controller.dart';

class MatchStartBinding extends Bindings {
  @override
  void dependencies() {
    if (Get.isRegistered<MatchStartController>()) {
      Get.delete<MatchStartController>(force: true);
    }
    Get.put(MatchStartController());
  }
}
