import 'package:get/get.dart';

import '../match_up/match_challenges/match_challenges_controller.dart';

class MatchChallengesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MatchChallengesController>(() => MatchChallengesController());
  }
}
