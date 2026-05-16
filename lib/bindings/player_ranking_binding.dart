import 'package:get/get.dart';

import '../rankings/player_ranking_controller.dart';

class PlayerRankingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PlayerRankingController>(() => PlayerRankingController());
  }
}
