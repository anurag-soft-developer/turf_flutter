import 'package:get/get.dart';
import '../match_up/match_up_controller.dart';
import 'scoring_binding.dart';

class MatchUpBinding extends Bindings {
  @override
  void dependencies() {
    ScoringBinding().dependencies();
    Get.lazyPut<MatchUpController>(() => MatchUpController());
  }
}
