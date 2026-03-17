import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth/auth_state_controller.dart';
import '../../components/shared/loading_overlay.dart';
import '../../utils/constants.dart';

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
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [
                    Color(AppColors.primaryColor),
                    Color(AppColors.secondaryColor),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    authController.user?.fullName ?? 'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Have a great day ahead!',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Quick Actions
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(AppColors.textColor),
            ),
          ),
          const SizedBox(height: 16),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              _buildActionCard(
                icon: Icons.person,
                title: 'Profile',
                subtitle: 'View & edit profile',
                onTap: () => Get.toNamed(AppConstants.routes.profile),
              ),
              _buildActionCard(
                icon: Icons.settings,
                title: 'Settings',
                subtitle: 'App preferences',
                onTap: () => Get.toNamed(AppConstants.routes.settings),
              ),
              _buildActionCard(
                icon: Icons.security,
                title: 'Security',
                subtitle: 'Account security',
                onTap: () {
                  Get.snackbar(
                    'Coming Soon',
                    'Security settings will be available soon',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),
              _buildActionCard(
                icon: Icons.help,
                title: 'Help',
                subtitle: 'Get support',
                onTap: () {
                  Get.snackbar(
                    'Help',
                    'Contact us at support@example.com',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Account Info
          const Text(
            'Account Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(AppColors.textColor),
            ),
          ),
          const SizedBox(height: 16),

          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildInfoRow('Email', authController.user?.email ?? ''),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    'Email Verified',
                    authController.user?.isEmailVerified == true ? 'Yes' : 'No',
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    'Account Created',
                    authController.user?.createdAtDate != null
                        ? '${authController.user!.createdAtDate!.day}/${authController.user!.createdAtDate!.month}/${authController.user!.createdAtDate!.year}'
                        : 'Unknown',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: const Color(AppColors.primaryColor)),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(AppColors.textColor),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(AppColors.textSecondaryColor),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(AppColors.textSecondaryColor),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(AppColors.textColor),
          ),
        ),
      ],
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
