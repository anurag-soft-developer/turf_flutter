import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        ],
      ),
      SettingSection(
        title: 'Account Actions',
        items: [
          SettingItem(
            title: 'Clear Cache',
            subtitle: 'Clear cached images and search history',
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
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AccountInformationSection(authController: authController),
                const SizedBox(height: 32),
                _ManageNotificationsEntry(),
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
          'This will remove cached images and search history. You will stay signed in.',
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

class _AccountInformationSection extends StatelessWidget {
  final AuthStateController authController;

  const _AccountInformationSection({required this.authController});

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _copy(String label, String value) {
    if (value.isEmpty) return;
    Clipboard.setData(ClipboardData(text: value));
    AppSnackbar.success(title: 'Copied', message: '$label copied');
  }

  @override
  Widget build(BuildContext context) {
    final user = authController.user;
    final userId = user?.id;
    final createdAt = _formatDate(user?.createdAtDate);
    final lastSignIn = _formatDate(user?.lastLoginDate);

    final items = [
      _ReadOnlyInfoItem(
        title: 'User ID',
        displayValue: userId ?? 'Unknown',
        copyValue: userId,
        icon: Icons.badge_outlined,
      ),
      _ReadOnlyInfoItem(
        title: 'Account Created',
        displayValue: createdAt,
        copyValue: createdAt == 'Unknown' ? null : createdAt,
        icon: Icons.calendar_today_outlined,
      ),
      _ReadOnlyInfoItem(
        title: 'Last Sign In',
        displayValue: lastSignIn,
        copyValue: lastSignIn == 'Unknown' ? null : lastSignIn,
        icon: Icons.access_time,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          color: const Color(AppColors.surfaceColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                if (i > 0)
                  const Divider(height: 1, color: Color(AppColors.dividerColor)),
                _ReadOnlyInfoTile(
                  item: items[i],
                  onCopy: items[i].copyValue == null
                      ? null
                      : () => _copy(items[i].title, items[i].copyValue!),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ReadOnlyInfoItem {
  final String title;
  final String displayValue;
  final String? copyValue;
  final IconData icon;

  const _ReadOnlyInfoItem({
    required this.title,
    required this.displayValue,
    required this.copyValue,
    required this.icon,
  });
}

class _ReadOnlyInfoTile extends StatelessWidget {
  final _ReadOnlyInfoItem item;
  final VoidCallback? onCopy;

  const _ReadOnlyInfoTile({required this.item, this.onCopy});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        item.title,
        style: const TextStyle(color: Color(AppColors.textColor)),
      ),
      subtitle: Text(
        item.displayValue,
        style: const TextStyle(color: Color(AppColors.textSecondaryColor)),
      ),
      leading: Icon(item.icon, color: const Color(AppColors.primaryColor)),
      trailing: onCopy == null
          ? null
          : IconButton(
              tooltip: 'Copy ${item.title}',
              icon: const Icon(
                Icons.copy,
                size: 20,
                color: Color(AppColors.primaryColor),
              ),
              onPressed: onCopy,
            ),
    );
  }
}

class _ManageNotificationsEntry extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: const Icon(
              Icons.notifications_outlined,
              color: Color(AppColors.primaryColor),
            ),
            title: const Text(
              'Manage notifications',
              style: TextStyle(color: Color(AppColors.textColor)),
            ),
            subtitle: const Text(
              'Push, SMS, email, and alerts by topic',
              style: TextStyle(color: Color(AppColors.textSecondaryColor)),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(AppColors.textSecondaryColor),
            ),
            onTap: () => Get.toNamed(AppConstants.routes.manageNotifications),
          ),
        ),
      ],
    );
  }
}
