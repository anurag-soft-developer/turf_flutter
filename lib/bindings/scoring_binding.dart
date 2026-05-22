import 'package:get/get.dart';

import '../scoring/cricket/cricket_scoring_api_service.dart';
import '../scoring/cricket/cricket_scoring_controller.dart';
import '../scoring/football/football_scoring_api_service.dart';
import '../scoring/football/football_scoring_controller.dart';

class ScoringBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CricketScoringApiService>(
      () => CricketScoringApiService(),
      fenix: true,
    );
    Get.lazyPut<CricketScoringController>(
      () => CricketScoringController(
        apiService: Get.find<CricketScoringApiService>(),
      ),
      fenix: true,
    );
    Get.lazyPut<FootballScoringApiService>(
      () => FootballScoringApiService(),
      fenix: true,
    );
    Get.lazyPut<FootballScoringController>(
      () => FootballScoringController(
        apiService: Get.find<FootballScoringApiService>(),
      ),
      fenix: true,
    );
  }
}
