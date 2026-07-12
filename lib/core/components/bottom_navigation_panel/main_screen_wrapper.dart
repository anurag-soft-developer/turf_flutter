import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app_bottom_navigation_panel.dart';
import 'nav_tabs.dart';
import 'navigation_controller.dart';

class MainScreenWrapper extends StatefulWidget {
  const MainScreenWrapper({super.key});

  @override
  State<MainScreenWrapper> createState() => _MainScreenWrapperState();
}

class _MainScreenWrapperState extends State<MainScreenWrapper> {
  late final NavigationController _navController;

  @override
  void initState() {
    super.initState();
    _navController = Get.find<NavigationController>();
  }

  Widget _buildActiveTab(int safeIndex) {
    final tab = kNavTabs[safeIndex];
    return KeyedSubtree(
      key: ValueKey(safeIndex),
      child: tab.screenBuilder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        final safeIndex = _navController.currentIndex.clamp(
          0,
          kNavTabs.length - 1,
        );
        return _buildActiveTab(safeIndex);
      }),
      bottomNavigationBar: Obx(() {
        final safeIndex = _navController.currentIndex.clamp(
          0,
          kNavTabs.length - 1,
        );
        return AppBottomNavigationPanel(
          tabs: kNavTabs,
          currentIndex: safeIndex,
          onTap: _navController.changeTab,
        );
      }),
    );
  }
}
