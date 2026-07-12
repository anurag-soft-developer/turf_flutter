import 'package:get/get.dart';

import '../match_up/matches/matches_controller.dart';
import 'scoring_binding.dart';

class MatchesBinding extends Bindings {
  @override
  void dependencies() {
    ScoringBinding().dependencies();
    Get.lazyPut<MatchesController>(() => MatchesController());
  }
}
