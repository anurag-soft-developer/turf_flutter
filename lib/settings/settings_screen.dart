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
              Get.toNamed(AppConstants.routes.changePassword);
            },
          ),
          SettingItem(
            title: 'Two-Factor Authentication',
            subtitle: 'Add an extra layer of security',
            icon: Icons.security,
            onTap: () {
              Get.toNamed(AppConstants.routes.twoFactorAuth);
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
        title: 'Account Information',
        items: [
          SettingItem(
            title: 'User ID',
            subtitle: authController.user?.id?.substring(0, 8) ?? 'N/A',
            icon: Icons.badge_outlined,
            onTap: () {},
          ),
          SettingItem(
            title: 'Account Created',
            subtitle: authController.user?.createdAtDate != null
                ? '${authController.user!.createdAtDate!.day}/${authController.user!.createdAtDate!.month}/${authController.user!.createdAtDate!.year}'
                : 'Unknown',
            icon: Icons.calendar_today_outlined,
            onTap: () {},
          ),
          SettingItem(
            title: 'Last Sign In',
            subtitle: authController.user?.lastLoginDate != null
                ? '${authController.user!.lastLoginDate!.day}/${authController.user!.lastLoginDate!.month}/${authController.user!.lastLoginDate!.year}'
                : 'Unknown',
            icon: Icons.access_time,
            onTap: () {},
          ),
        ],
      ),
      SettingSection(
        title: 'Account Actions',
        items: [
          SettingItem(
            title: 'Download Data',
            subtitle: 'Export your account data',
            icon: Icons.download,
            onTap: () {
              AppSnackbar.comingSoon(feature: 'Data download');
            },
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
            title: 'Delete Account',
            subtitle: 'Permanently delete your account',
            icon: Icons.delete_outline,
            onTap: () => _showDeleteAccountDialog(context),
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
                      _NotificationsSettingsSection(
                        authController: authController,
                      ),
                      const SizedBox(height: 32),
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

  void _showDeleteAccountDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text(
          'Delete Account',
          style: TextStyle(color: Colors.red),
        ),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              AppSnackbar.comingSoon(feature: 'Account deletion');
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
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

class _NotificationsSettingsSection extends StatelessWidget {
  const _NotificationsSettingsSection({required this.authController});

  final AuthStateController authController;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = authController.user;
      final busy = authController.notificationSettingsUpdating.value;
      final emailOn = user?.emailNotificationsEnabled ?? true;
      final smsOn = user?.smsNotificationsEnabled ?? false;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notifications',
            style: TextStyle(
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
              children: [
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  secondary: const Icon(
                    Icons.email_outlined,
                    color: Color(AppColors.primaryColor),
                  ),
                  title: const Text(
                    'Email notifications',
                    style: TextStyle(color: Color(AppColors.textColor)),
                  ),
                  subtitle: const Text(
                    'Booking updates, reminders, and account alerts',
                    style: TextStyle(
                      color: Color(AppColors.textSecondaryColor),
                    ),
                  ),
                  value: emailOn,
                  onChanged: busy
                      ? null
                      : (enabled) {
                          authController.updateNotificationSettings(
                            emailNotificationsEnabled: enabled,
                          );
                        },
                ),
                const Divider(height: 1, color: Color(AppColors.dividerColor)),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  secondary: const Icon(
                    Icons.sms_outlined,
                    color: Color(AppColors.primaryColor),
                  ),
                  title: const Text(
                    'SMS notifications',
                    style: TextStyle(color: Color(AppColors.textColor)),
                  ),
                  subtitle: const Text(
                    'Text messages for important alerts',
                    style: TextStyle(
                      color: Color(AppColors.textSecondaryColor),
                    ),
                  ),
                  value: smsOn,
                  onChanged: busy
                      ? null
                      : (enabled) {
                          authController.updateNotificationSettings(
                            smsNotificationsEnabled: enabled,
                          );
                        },
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}
