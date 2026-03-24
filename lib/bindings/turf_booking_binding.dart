import 'package:get/get.dart';
import '../controllers/turf_booking_controller.dart';

class TurfBookingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TurfBookingController>(
      () => TurfBookingController(),
      fenix: true,
    );
  }
}
