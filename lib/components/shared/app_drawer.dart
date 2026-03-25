import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth/auth_state_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../config/constants.dart';
import '../../utils/app_snackbar.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthStateController authController = Get.find();
    final SettingsController settingsController = Get.find();
    final String? avatar = authController.user?.avatar;
    return Drawer(
      backgroundColor: const Color(AppColors.surfaceColor),
      child: Column(
        children: [
          // User Header
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
              accountEmail: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(authController.user?.email ?? ''),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      settingsController.currentModeDisplay,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                child: avatar == null
                    ? const Icon(
                        Icons.person,
                        color: Color(AppColors.primaryColor),
                        size: 40,
                      )
                    : null,
              ),
            ),
          ),

          // Mode Switch Button
          Obx(
            () => Container(
              margin: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () {
                  settingsController.toggleMode();
                  Get.back(); // Close drawer
                },
                icon: Icon(
                  settingsController.isPlayerMode
                      ? Icons.business
                      : Icons.sports_soccer,
                  size: 20,
                ),
                label: Text(
                  'Switch to ${settingsController.alternateModeDisplay}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(AppColors.primaryColor),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),

          const Divider(color: Color(AppColors.dividerColor)),

          // Navigation Items
          ListTile(
            leading: const Icon(
              Icons.dashboard,
              color: Color(AppColors.primaryColor),
            ),
            title: const Text(
              'Dashboard',
              style: TextStyle(color: Color(AppColors.textColor)),
            ),
            onTap: () => Get.back(),
          ),

          // Player Mode Specific Items
          Obx(() {
            if (settingsController.currentMode.value == UserMode.player) {
              return Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.sports,
                      color: Color(AppColors.primaryColor),
                    ),
                    title: const Text(
                      'Browse Turfs',
                      style: TextStyle(color: Color(AppColors.textColor)),
                    ),
                    onTap: () {
                      Get.back();
                      Get.toNamed(AppConstants.routes.turfList);
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.book_online,
                      color: Color(AppColors.primaryColor),
                    ),
                    title: const Text(
                      'My Bookings',
                      style: TextStyle(color: Color(AppColors.textColor)),
                    ),
                    onTap: () {
                      Get.back();
                      // Navigate to bookings
                      AppSnackbar.comingSoon(feature: 'My Bookings');
                    },
                  ),
                ],
              );
            } else {
              // Proprietor Mode Specific Items
              return Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.add_business,
                      color: Color(AppColors.primaryColor),
                    ),
                    title: const Text(
                      'Add New Turf',
                      style: TextStyle(color: Color(AppColors.textColor)),
                    ),
                    onTap: () {
                      Get.back();
                      // Navigate to add turf
                      AppSnackbar.comingSoon(feature: 'Add Turf');
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.grass,
                      color: Color(AppColors.primaryColor),
                    ),
                    title: const Text(
                      'My Turfs',
                      style: TextStyle(color: Color(AppColors.textColor)),
                    ),
                    onTap: () {
                      Get.back();
                      // Navigate to my turfs
                      AppSnackbar.comingSoon(feature: 'My Turfs management');
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.calendar_today,
                      color: Color(AppColors.primaryColor),
                    ),
                    title: const Text(
                      'Turf Bookings',
                      style: TextStyle(color: Color(AppColors.textColor)),
                    ),
                    onTap: () {
                      Get.back();
                      // Navigate to turf bookings
                      AppSnackbar.comingSoon(
                        feature: 'Turf Bookings management',
                      );
                    },
                  ),
                ],
              );
            }
          }),
          const Spacer(),

          const Divider(color: Color(AppColors.dividerColor)),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              Get.back();
              _showLogoutDialog(context, authController);
            },
          ),
          const SizedBox(height: 16),
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
