import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../settings/settings_controller.dart';
import 'app_bottom_navigation_panel.dart';
import 'nav_tabs.dart';
import 'navigation_controller.dart';

class MainScreenWrapper extends StatelessWidget {
  const MainScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final NavigationController navController = Get.find<NavigationController>();
    final SettingsController settingsController = Get.find<SettingsController>();

    return Scaffold(
      body: Obx(() {
        final tabs = navTabsForMode(settingsController.currentMode.value);
        final safeIndex = navController.currentIndex.clamp(0, tabs.length - 1);
        return tabs[safeIndex].screenBuilder();
      }),
      bottomNavigationBar: Obx(
        () {
          final tabs = navTabsForMode(settingsController.currentMode.value);
          final safeIndex = navController.currentIndex.clamp(0, tabs.length - 1);
          return AppBottomNavigationPanel(
            tabs: tabs,
            currentIndex: safeIndex,
            onTap: navController.changeTab,
          );
        },
      ),
    );
  }
}
