import 'package:get/get.dart';

import '../match_up/challenge/challenge_controller.dart';
import 'scoring_binding.dart';

class ExploreBinding extends Bindings {
  @override
  void dependencies() {
    ScoringBinding().dependencies();
    if (!Get.isRegistered<ChallengeController>()) {
      Get.put(ChallengeController());
    } else {
      Get.find<ChallengeController>().load();
    }
  }
}
