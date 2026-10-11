import 'package:get/get.dart';

import '../tournament/list/tournament_list_controller.dart';

class TournamentListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(TournamentListController.new);
    if (Get.isRegistered<TournamentListController>()) {
      Get.find<TournamentListController>().applySportFromRoute();
    }
  }
}
