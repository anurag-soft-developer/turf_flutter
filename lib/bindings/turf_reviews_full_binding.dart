import 'package:get/get.dart';

import '../turf/reviews/turf_reviews_list_controller.dart';

class TurfReviewsFullBinding extends Bindings {
  @override
  void dependencies() {
    final args = Get.arguments;
    final id = args is Map<String, dynamic> ? args['turfId'] as String? : null;
    if (id == null) return;
    Get.put(
      TurfReviewsListController(turfId: id, previewOnly: false),
      tag: turfReviewsFullTag(id),
    );
  }
}
