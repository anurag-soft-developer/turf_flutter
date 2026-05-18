import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../components/shared/app_drawer.dart';
import '../core/config/constants.dart';
import 'player/player_dashboard.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: Text(
          AppConstants.appName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(AppColors.primaryColor),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Get.toNamed(AppConstants.routes.notifications),
            icon: const Icon(Icons.notifications),
            tooltip: 'Notifications',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: const PlayerDashboard(),
    );
  }
}
