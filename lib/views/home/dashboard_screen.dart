import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth/auth_state_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../components/shared/loading_overlay.dart';
import '../../components/shared/app_drawer.dart';
import '../../config/constants.dart';
import 'player_dashboard.dart';
import 'proprietor_dashboard.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthStateController authController = Get.find();
    final SettingsController settingsController = Get.find();

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: _buildAppBar(settingsController),
      drawer: const AppDrawer(),
      body: Obx(
        () => LoadingOverlay(
          isLoading: authController.isLoading,
          child: settingsController.currentMode == UserMode.player
              ? const PlayerDashboard()
              : const ProprietorDashboard(),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(SettingsController settingsController) {
    return AppBar(
      title: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppConstants.appName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              settingsController.currentModeDisplay,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
      backgroundColor: const Color(AppColors.primaryColor),
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          onPressed: () => Get.toNamed(AppConstants.routes.settings),
          icon: const Icon(Icons.settings),
        ),
      ],
    );
  }
}
