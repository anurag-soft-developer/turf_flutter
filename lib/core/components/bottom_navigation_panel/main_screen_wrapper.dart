import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../settings/settings_controller.dart';
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
  late final SettingsController _settingsController;

  UserMode? _cachedMode;
  List<Widget?> _tabCache = const [];

  @override
  void initState() {
    super.initState();
    _navController = Get.find<NavigationController>();
    _settingsController = Get.find<SettingsController>();
  }

  void _syncCacheForMode(UserMode mode, int tabCount) {
    if (_cachedMode != mode || _tabCache.length != tabCount) {
      _cachedMode = mode;
      _tabCache = List<Widget?>.filled(tabCount, null, growable: false);
    }
  }

  Widget _buildLazyIndexedStack(List<NavTab> tabs, int safeIndex) {
    _syncCacheForMode(_settingsController.currentMode.value, tabs.length);

    if (_tabCache[safeIndex] == null) {
      debugPrint(
        '[MainScreenWrapper] First mount tab index=$safeIndex label=${tabs[safeIndex].label}',
      );
      tabs[safeIndex].loadController?.call();
      _tabCache[safeIndex] = tabs[safeIndex].screenBuilder();
    }

    return IndexedStack(
      index: safeIndex,
      children: List<Widget>.generate(
        tabs.length,
        (index) => _tabCache[index] ?? const SizedBox.shrink(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        final tabs = navTabsForMode(_settingsController.currentMode.value);
        final safeIndex = _navController.currentIndex.clamp(0, tabs.length - 1);
        return _buildLazyIndexedStack(tabs, safeIndex);
      }),
      bottomNavigationBar: Obx(
        () {
          final tabs = navTabsForMode(_settingsController.currentMode.value);
          final safeIndex = _navController.currentIndex.clamp(
            0,
            tabs.length - 1,
          );
          return AppBottomNavigationPanel(
            tabs: tabs,
            currentIndex: safeIndex,
            onTap: _navController.changeTab,
          );
        },
      ),
    );
  }
}
