import 'package:flutter/material.dart';
import 'package:flutter_application_1/components/shared/loading_overlay.dart';
import 'package:get/get.dart';
import '../../controllers/auth/auth_state_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../utils/constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingsController settingsController = Get.put(SettingsController());
    final AuthStateController authController = Get.find();

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
                      const Text(
                        'Preferences',
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
                        child: Column(
                          children: [
                            Obx(
                              () => SwitchListTile(
                                title: const Text('Dark Mode'),
                                subtitle: const Text(
                                  'Switch between light and dark theme',
                                ),
                                value: settingsController.isDarkMode,
                                onChanged: (value) =>
                                    settingsController.toggleDarkMode(),
                                activeThumbColor: const Color(
                                  AppColors.primaryColor,
                                ),
                                secondary: Icon(
                                  settingsController.isDarkMode
                                      ? Icons.dark_mode
                                      : Icons.light_mode,
                                  color: const Color(AppColors.primaryColor),
                                ),
                              ),
                            ),
                            const Divider(height: 1),
                            Obx(
                              () => SwitchListTile(
                                title: const Text('Notifications'),
                                subtitle: const Text(
                                  'Enable push notifications',
                                ),
                                value: settingsController.notificationsEnabled,
                                onChanged: (value) =>
                                    settingsController.toggleNotifications(),
                                activeThumbColor: const Color(
                                  AppColors.primaryColor,
                                ),
                                secondary: const Icon(
                                  Icons.notifications_outlined,
                                  color: Color(AppColors.primaryColor),
                                ),
                              ),
                            ),
                            const Divider(height: 1),
                            Obx(
                              () => SwitchListTile(
                                title: const Text('Biometric Authentication'),
                                subtitle: const Text(
                                  'Use fingerprint or face recognition',
                                ),
                                value: settingsController.biometricEnabled,
                                onChanged: (value) =>
                                    settingsController.toggleBiometric(),
                                activeThumbColor: const Color(
                                  AppColors.primaryColor,
                                ),
                                secondary: const Icon(
                                  Icons.fingerprint,
                                  color: Color(AppColors.primaryColor),
                                ),
                              ),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              title: const Text('Language'),
                              subtitle: Obx(
                                () => Text(
                                  'Selected: ${settingsController.selectedLanguage}',
                                ),
                              ),
                              leading: const Icon(
                                Icons.language,
                                color: Color(AppColors.primaryColor),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () => _showLanguageDialog(
                                context,
                                settingsController,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Privacy & Security Section
                      const Text(
                        'Privacy & Security',
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
                        child: Column(
                          children: [
                            ListTile(
                              title: const Text('Change Password'),
                              subtitle: const Text(
                                'Update your account password',
                              ),
                              leading: const Icon(
                                Icons.lock_outline,
                                color: Color(AppColors.primaryColor),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () {
                                Get.snackbar(
                                  'Coming Soon',
                                  'Password change will be available soon',
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                              },
                            ),
                            const Divider(height: 1),
                            ListTile(
                              title: const Text('Two-Factor Authentication'),
                              subtitle: const Text(
                                'Add an extra layer of security',
                              ),
                              leading: const Icon(
                                Icons.security,
                                color: Color(AppColors.primaryColor),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () {
                                Get.snackbar(
                                  'Coming Soon',
                                  'Two-factor authentication will be available soon',
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                              },
                            ),
                            const Divider(height: 1),
                            ListTile(
                              title: const Text('Privacy Settings'),
                              subtitle: const Text(
                                'Manage your privacy preferences',
                              ),
                              leading: const Icon(
                                Icons.privacy_tip_outlined,
                                color: Color(AppColors.primaryColor),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () {
                                Get.snackbar(
                                  'Coming Soon',
                                  'Privacy settings will be available soon',
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Support & Info Section
                      const Text(
                        'Support & Information',
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
                        child: Column(
                          children: [
                            ListTile(
                              title: const Text('Help Center'),
                              subtitle: const Text('Get help and support'),
                              leading: const Icon(
                                Icons.help_outline,
                                color: Color(AppColors.primaryColor),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () {
                                Get.snackbar(
                                  'Help Center',
                                  'Contact us at support@example.com',
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                              },
                            ),
                            const Divider(height: 1),
                            ListTile(
                              title: const Text('Terms of Service'),
                              subtitle: const Text(
                                'Read our terms and conditions',
                              ),
                              leading: const Icon(
                                Icons.description_outlined,
                                color: Color(AppColors.primaryColor),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () {
                                Get.snackbar(
                                  'Terms of Service',
                                  'Terms of service will be available soon',
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                              },
                            ),
                            const Divider(height: 1),
                            ListTile(
                              title: const Text('Privacy Policy'),
                              subtitle: const Text(
                                'Learn about our privacy practices',
                              ),
                              leading: const Icon(
                                Icons.policy_outlined,
                                color: Color(AppColors.primaryColor),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () {
                                Get.snackbar(
                                  'Privacy Policy',
                                  'Privacy policy will be available soon',
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                              },
                            ),
                            const Divider(height: 1),
                            ListTile(
                              title: const Text('About'),
                              subtitle: const Text(
                                'App version and information',
                              ),
                              leading: const Icon(
                                Icons.info_outline,
                                color: Color(AppColors.primaryColor),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: settingsController.showAbout,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Advanced Section
                      const Text(
                        'Advanced',
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
                        child: Column(
                          children: [
                            ListTile(
                              title: const Text('Clear Cache'),
                              subtitle: const Text(
                                'Clear app cache and temporary files',
                              ),
                              leading: const Icon(
                                Icons.cleaning_services_outlined,
                                color: Color(AppColors.primaryColor),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () => _showClearCacheDialog(
                                context,
                                settingsController,
                              ),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              title: const Text(
                                'Sign Out',
                                style: TextStyle(color: Colors.red),
                              ),
                              subtitle: const Text(
                                'Sign out from your account',
                              ),
                              leading: const Icon(
                                Icons.logout,
                                color: Colors.red,
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () =>
                                  _showSignOutDialog(context, authController),
                            ),
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

  void _showLanguageDialog(
    BuildContext context,
    SettingsController settingsController,
  ) {
    final languages = [
      'English',
      'Spanish',
      'French',
      'German',
      'Chinese',
      'Japanese',
    ];

    Get.dialog(
      AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages
              .map(
                (language) => Obx(
                  () => RadioGroup<String>(
                    groupValue: settingsController.selectedLanguage,
                    onChanged: (value) {
                      if (value != null) {
                        settingsController.changeLanguage(value);
                        Get.back();
                      }
                    },
                    child: RadioListTile<String>(
                      title: Text(language),
                      value: language,
                      activeColor: const Color(AppColors.primaryColor),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ],
      ),
    );
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
