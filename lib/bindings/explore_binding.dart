import 'package:get/get.dart';

import 'scoring_binding.dart';

class ExploreBinding extends Bindings {
  @override
  void dependencies() {
    ScoringBinding().dependencies();
  }
}
