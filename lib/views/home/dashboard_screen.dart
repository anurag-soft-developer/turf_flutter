import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth/auth_state_controller.dart';
import '../../components/shared/loading_overlay.dart';
import '../../components/dashboard/welcome_card.dart';
import '../../components/dashboard/sports_section.dart';
import '../../components/dashboard/quick_actions_section.dart';
import '../../config/constants.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthStateController authController = Get.find();

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: Text(
          AppConstants.appName,
          style: const TextStyle(fontWeight: FontWeight.bold),
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
      ),
      drawer: _buildDrawer(context, authController),
      body: Obx(
        () => LoadingOverlay(
          isLoading: authController.isLoading,
          child: _buildBody(context, authController),
        ),
      ),
    );
  }

  Widget _buildDrawer(
    BuildContext context,
    AuthStateController authController,
  ) {
    return Drawer(
      child: Column(
        children: [
          Obx(
            () => UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                color: Color(AppColors.primaryColor),
              ),
              accountName: Text(
                authController.user?.fullName ?? 'User',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              accountEmail: Text(authController.user?.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: authController.user?.avatar != null
                    ? NetworkImage(authController.user!.avatar!)
                    : null,
                child: authController.user?.avatar == null
                    ? const Icon(
                        Icons.person,
                        color: Color(AppColors.primaryColor),
                        size: 40,
                      )
                    : null,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () => Get.back(),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Get.back();
              Get.toNamed(AppConstants.routes.profile);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Get.back();
              Get.toNamed(AppConstants.routes.settings);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              Get.back();
              _showLogoutDialog(context, authController);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, AuthStateController authController) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card
          WelcomeCard(authController: authController),
          const SizedBox(height: 32),

          // Sports Section (Primary - Most Prominent)
          const SportsSection(),
          const SizedBox(height: 32),

          // Quick Actions (Secondary - Below Sports)
          const QuickActionsSection(),
          const SizedBox(height: 32),

          // Account Info
        ],
      ),
    );
  }

  void _showLogoutDialog(
    BuildContext context,
    AuthStateController authController,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              authController.signOut();
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
