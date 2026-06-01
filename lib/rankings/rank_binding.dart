import 'package:get/get.dart';

import '../team/feed/teams_ranking_controller.dart';
import 'player_ranking_controller.dart';
import 'rank_controller.dart';

class RankBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TeamsRankingController>(() => TeamsRankingController());
    Get.lazyPut<PlayerRankingController>(() => PlayerRankingController());
    Get.lazyPut<RankController>(() => RankController());
  }
}
