import 'package:get/get.dart';

import '../explore/explore_controller.dart';
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
    if (!Get.isRegistered<ExploreController>()) {
      Get.put(ExploreController());
    }
  }
}

class ExploreSearchBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(
      ExploreController(includeAll: true),
      tag: ExploreController.searchTag,
    );
  }
}
