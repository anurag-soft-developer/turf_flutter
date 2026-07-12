import 'package:flutter_application_1/settings/settings_controller.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../auth/auth_state_controller.dart';

class InitialBinding extends Bindings {
  InitialBinding({required this.queryClient});

  final QueryClient queryClient;

  @override
  void dependencies() {
    if (!Get.isRegistered<QueryClient>()) {
      Get.put<QueryClient>(queryClient, permanent: true);
    }
    if (!Get.isRegistered<AuthStateController>()) {
      Get.put<AuthStateController>(AuthStateController(), permanent: true);
    }
    if (!Get.isRegistered<SettingsController>()) {
      Get.put<SettingsController>(SettingsController(), permanent: true);
    }
  }
}
