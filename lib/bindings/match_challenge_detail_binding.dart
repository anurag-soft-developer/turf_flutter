import 'package:get/get.dart';

import '../core/routes/route_query.dart';
import '../match_up/match_challenges/match_challenge_detail_controller.dart';
import 'scoring_binding.dart';

class MatchChallengeDetailBinding extends Bindings {
  @override
  void dependencies() {
    ScoringBinding().dependencies();
    final id = routeParam('id') ?? '';
    final tag = id.isEmpty ? null : id;
    if (Get.isRegistered<MatchChallengeDetailController>(tag: tag)) {
      Get.delete<MatchChallengeDetailController>(tag: tag, force: true);
    }
    Get.put(MatchChallengeDetailController(), tag: tag);
  }
}
