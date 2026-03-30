import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../settings/settings_controller.dart';
import '../components/shared/app_drawer.dart';
import '../core/config/constants.dart';
import 'player/player_dashboard.dart';
import 'proprietor/proprietor_dashboard.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingsController settingsController = Get.find();

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: _buildAppBar(settingsController),
      drawer: const AppDrawer(),
      body: Obx(() {
        return settingsController.isPlayerMode
            ? const PlayerDashboard()
            : const ProprietorDashboard();
      }),
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
