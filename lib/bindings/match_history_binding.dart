import 'package:get/get.dart';
import '../match_up/match_history/match_history_controller.dart';

class MatchHistoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MatchHistoryController>(() => MatchHistoryController());
  }
}
