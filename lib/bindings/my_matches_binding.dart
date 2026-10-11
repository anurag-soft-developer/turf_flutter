import 'package:get/get.dart';

import '../match_up/my_matches/my_matches_controller.dart';
import 'scoring_binding.dart';

class MyMatchesBinding extends Bindings {
  @override
  void dependencies() {
    ScoringBinding().dependencies();
    Get.lazyPut<MyMatchesController>(() => MyMatchesController());
    if (Get.isRegistered<MyMatchesController>()) {
      final c = Get.find<MyMatchesController>();
      c.applyTabFromArguments();
      c.applySportFromRoute();
    }
  }
}
