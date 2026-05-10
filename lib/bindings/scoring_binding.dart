import 'package:get/get.dart';

import '../scoring/scoring_api_service.dart';
import '../scoring/scoring_controller.dart';
// import '../scoring/scoring_socket_service.dart';

class ScoringBinding extends Bindings {
  @override
  void dependencies() {
    // Get.lazyPut<ScoringSocketService>(
    //   () => ScoringSocketService(),
    //   fenix: true,
    // );
    Get.lazyPut<ScoringApiService>(() => ScoringApiService(), fenix: true);
    Get.lazyPut<ScoringController>(
      () => ScoringController(
        // socketService: Get.find<ScoringSocketService>(),
        apiService: Get.find<ScoringApiService>(),
      ),
      fenix: true,
    );
  }
}
