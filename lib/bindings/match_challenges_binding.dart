import 'package:get/get.dart';

import '../match_up/match_challenges/match_challenges_controller.dart';
import 'scoring_binding.dart';

class MatchChallengesBinding extends Bindings {
  @override
  void dependencies() {
    ScoringBinding().dependencies();
    Get.lazyPut<MatchChallengesController>(() => MatchChallengesController());
  }
}
