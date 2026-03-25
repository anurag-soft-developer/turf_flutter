import 'package:flutter_application_1/controllers/settings_controller.dart';
import 'package:get/get.dart';
import '../controllers/auth/auth_state_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<AuthStateController>(AuthStateController(), permanent: true);
    Get.put<SettingsController>(SettingsController(), permanent: true);
  }
}
