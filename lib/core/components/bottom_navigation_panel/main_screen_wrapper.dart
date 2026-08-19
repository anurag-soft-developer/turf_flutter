import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/config/constants.dart';
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
  static const _exitWindow = Duration(seconds: 2);

  late final NavigationController _navController;
  DateTime? _lastBackAt;

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

  void _onPopInvoked(bool didPop, Object? result) {
    if (didPop) return;

    if (_navController.currentIndex != 0) {
      _navController.changeTab(0);
      _lastBackAt = null;
      return;
    }

    final now = DateTime.now();
    final firstTap =
        _lastBackAt == null || now.difference(_lastBackAt!) > _exitWindow;
    if (firstTap) {
      _lastBackAt = now;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Press back again to exit', style: TextStyle(color: Colors.white),),
            duration: _exitWindow,
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(AppColors.secondaryColor),
          ),
        );
      return;
    }

    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onPopInvoked,
      child: Scaffold(
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
      ),
    );
  }
}
