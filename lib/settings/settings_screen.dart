import 'package:flutter/material.dart';
import 'package:flutter_application_1/components/shared/loading_overlay.dart';
import 'package:get/get.dart';
import '../core/auth/auth_state_controller.dart';
import 'settings_controller.dart';
import '../core/config/constants.dart';
import '../core/utils/app_snackbar.dart';

class SettingItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool isRed;

  SettingItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.isRed = false,
  });
}

class SettingSection {
  final String title;
  final List<SettingItem> items;

  SettingSection({required this.title, required this.items});
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingsController settingsController = Get.put(SettingsController());
    final AuthStateController authController = Get.find();

    // Define setting sections data
    final List<SettingSection> settingSections = [
      SettingSection(
        title: 'Privacy & Security',
        items: [
          SettingItem(
            title: 'Change Password',
            subtitle: 'Update your account password',
            icon: Icons.lock_outline,
            onTap: () {
              Get.snackbar(
                'Coming Soon',
                'Password change will be available soon',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),
          SettingItem(
            title: 'Two-Factor Authentication',
            subtitle: 'Add an extra layer of security',
            icon: Icons.security,
            onTap: () {
              Get.snackbar(
                'Coming Soon',
                'Two-factor authentication will be available soon',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),
          SettingItem(
            title: 'Privacy Settings',
            subtitle: 'Manage your privacy preferences',
            icon: Icons.privacy_tip_outlined,
            onTap: () {
              AppSnackbar.comingSoon(feature: 'Privacy settings');
            },
          ),
        ],
      ),
      SettingSection(
        title: 'Support & Information',
        items: [
          SettingItem(
            title: 'Help Center',
            subtitle: 'Get help and support',
            icon: Icons.help_outline,
            onTap: () {
              AppSnackbar.info(
                title: 'Help Center',
                message: 'Contact us at support@example.com',
              );
            },
          ),
          SettingItem(
            title: 'Terms of Service',
            subtitle: 'Read our terms and conditions',
            icon: Icons.description_outlined,
            onTap: () {
              AppSnackbar.comingSoon(feature: 'Terms of service');
            },
          ),
          SettingItem(
            title: 'Privacy Policy',
            subtitle: 'Learn about our privacy practices',
            icon: Icons.policy_outlined,
            onTap: () {
              AppSnackbar.comingSoon(feature: 'Privacy policy');
            },
          ),
          SettingItem(
            title: 'About',
            subtitle: 'App version and information',
            icon: Icons.info_outline,
            onTap: settingsController.showAbout,
          ),
        ],
      ),
      SettingSection(
        title: 'Advanced',
        items: [
          SettingItem(
            title: 'Clear Cache',
            subtitle: 'Clear app cache and temporary files',
            icon: Icons.cleaning_services_outlined,
            onTap: () => _showClearCacheDialog(context, settingsController),
          ),
          SettingItem(
            title: 'Sign Out',
            subtitle: 'Sign out from your account',
            icon: Icons.logout,
            onTap: () => _showSignOutDialog(context, authController),
            isRed: true,
          ),
        ],
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(AppColors.primaryColor),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Obx(
        () => LoadingOverlay(
          isLoading: authController.isLoading,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // User Info Header
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(AppColors.primaryColor),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 24,
                      right: 24,
                      bottom: 30,
                    ),
                    child: Row(
                      children: [
                        Obx(
                          () => CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white,
                            backgroundImage: authController.user?.avatar != null
                                ? NetworkImage(authController.user!.avatar!)
                                : null,
                            child: authController.user?.avatar == null
                                ? const Icon(
                                    Icons.person,
                                    color: Color(AppColors.primaryColor),
                                    size: 30,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Obx(
                            () => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  authController.user?.fullName ?? 'User',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  authController.user?.email ?? '',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Settings Sections
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Preferences Section
                      // const Text(
                      //   'Preferences',
                      //   style: TextStyle(
                      //     fontSize: 20,
                      //     fontWeight: FontWeight.bold,
                      //     color: Color(AppColors.textColor),
                      //   ),
                      // ),
                      // const SizedBox(height: 16),
                      // Card(
                      //   elevation: 1,
                      //   color: const Color(AppColors.surfaceColor),
                      //   shape: RoundedRectangleBorder(
                      //     borderRadius: BorderRadius.circular(12),
                      //   ),
                      //   child: Column(
                      //     children: [
                      //       Obx(
                      //         () => SwitchListTile(
                      //           title: const Text(
                      //             'Notifications',
                      //             style: TextStyle(
                      //               color: Color(AppColors.textColor),
                      //             ),
                      //           ),
                      //           subtitle: const Text(
                      //             'Enable push notifications',
                      //             style: TextStyle(
                      //               color: Color(AppColors.textSecondaryColor),
                      //             ),
                      //           ),
                      //           value: settingsController.notificationsEnabled,
                      //           onChanged: (value) =>
                      //               settingsController.toggleNotifications(),
                      //           activeThumbColor: const Color(
                      //             AppColors.primaryColor,
                      //           ),
                      //           secondary: const Icon(
                      //             Icons.notifications_outlined,
                      //             color: Color(AppColors.primaryColor),
                      //           ),
                      //         ),
                      //       ),
                      //       const Divider(
                      //         height: 1,
                      //         color: Color(AppColors.dividerColor),
                      //       ),
                      //       Obx(
                      //         () => ListTile(
                      //           title: const Text(
                      //             'Current Mode',
                      //             style: TextStyle(
                      //               color: Color(AppColors.textColor),
                      //             ),
                      //           ),
                      //           subtitle: Text(
                      //             settingsController.currentModeDisplay,
                      //             style: const TextStyle(
                      //               color: Color(AppColors.textSecondaryColor),
                      //             ),
                      //           ),
                      //           leading: Icon(
                      //             settingsController.currentMode ==
                      //                     UserMode.player
                      //                 ? Icons.sports_soccer
                      //                 : Icons.business,
                      //             color: const Color(AppColors.primaryColor),
                      //           ),
                      //           trailing: IconButton(
                      //             onPressed: () {
                      //               settingsController.toggleMode();
                      //             },
                      //             icon: const Icon(Icons.swap_horiz),
                      //           ),
                      //         ),
                      //       ),
                      //     ],
                      //   ),
                      // ),
                      // const SizedBox(height: 32),

                      // Loop through setting sections
                      ...settingSections.map(
                        (section) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              section.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(AppColors.textColor),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Card(
                              elevation: 1,
                              color: const Color(AppColors.surfaceColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: _buildSectionItems(section.items),
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSectionItems(List<SettingItem> items) {
    List<Widget> widgets = [];
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      widgets.add(
        ListTile(
          title: Text(
            item.title,
            style: TextStyle(
              color: item.isRed ? Colors.red : const Color(AppColors.textColor),
            ),
          ),
          subtitle: Text(
            item.subtitle,
            style: const TextStyle(color: Color(AppColors.textSecondaryColor)),
          ),
          leading: Icon(
            item.icon,
            color: item.isRed
                ? Colors.red
                : const Color(AppColors.primaryColor),
          ),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: item.onTap,
        ),
      );

      // Add divider between items except for the last item
      if (i < items.length - 1) {
        widgets.add(
          const Divider(height: 1, color: Color(AppColors.dividerColor)),
        );
      }
    }
    return widgets;
  }

  void _showClearCacheDialog(
    BuildContext context,
    SettingsController settingsController,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'Are you sure you want to clear the app cache? This will remove temporary files and may improve app performance.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              settingsController.clearCache();
            },
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(
    BuildContext context,
    AuthStateController authController,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              authController.signOut();
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
