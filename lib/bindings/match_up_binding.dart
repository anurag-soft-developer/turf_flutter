import 'package:get/get.dart';
import '../match_up/match_up_controller.dart';

class MatchUpBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MatchUpController>(() => MatchUpController());
  }
}
