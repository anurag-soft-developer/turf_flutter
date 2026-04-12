import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app_bottom_navigation_panel.dart';
import 'nav_tabs.dart';
import 'navigation_controller.dart';

class MainScreenWrapper extends StatelessWidget {
  const MainScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final NavigationController navController = Get.find<NavigationController>();

    return Scaffold(
      body: Obx(() => kNavTabs[navController.currentIndex].screenBuilder()),
      bottomNavigationBar: Obx(
        () => AppBottomNavigationPanel(
          currentIndex: navController.currentIndex,
          onTap: navController.changeTab,
        ),
      ),
    );
  }
}
