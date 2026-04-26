import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/auth/auth_state_controller.dart';
import '../../settings/settings_controller.dart';
import '../../core/config/constants.dart';

class DrawerMenuItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;

  DrawerMenuItem({
    required this.title,
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.textColor,
  });
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  List<DrawerMenuItem> _getPlayerModeItems() {
    return [
      DrawerMenuItem(
        title: 'Browse Turfs',
        icon: Icons.sports,
        iconColor: const Color(AppColors.primaryColor),
        onTap: () {
          Get.back();
          Get.toNamed(AppConstants.routes.turfList);
        },
      ),
      DrawerMenuItem(
        title: 'My Bookings',
        icon: Icons.book_online,
        iconColor: const Color(AppColors.primaryColor),
        onTap: () {
          Get.back();
          Get.toNamed(AppConstants.routes.myBookings);
        },
      ),
      DrawerMenuItem(
        title: 'My Teams',
        icon: Icons.groups,
        iconColor: const Color(AppColors.primaryColor),
        onTap: () {
          Get.back();
          Get.toNamed(AppConstants.routes.myTeams);
        },
      ),
      DrawerMenuItem(
        title: 'Openings',
        icon: Icons.group_add,
        iconColor: const Color(AppColors.primaryColor),
        onTap: () {
          Get.back();
          Get.toNamed(AppConstants.routes.teamOpenings);
        },
      ),

      DrawerMenuItem(
        title: 'Challenges',
        icon: Icons.sports_soccer,
        iconColor: const Color(AppColors.primaryColor),
        onTap: () {
          Get.back();
          Get.toNamed(AppConstants.routes.matchUpChallenges);
        },
      ),
    ];
  }

  List<DrawerMenuItem> _getProprietorModeItems() {
    return [
      DrawerMenuItem(
        title: 'Add New Turf',
        icon: Icons.add_business,
        iconColor: const Color(AppColors.primaryColor),
        onTap: () {
          Get.back();
          Get.toNamed(AppConstants.routes.createTurf);
        },
      ),
      DrawerMenuItem(
        title: 'My Turfs',
        icon: Icons.grass,
        iconColor: const Color(AppColors.primaryColor),
        onTap: () {
          Get.back();
          Get.toNamed(AppConstants.routes.myTurfs);
        },
      ),
      DrawerMenuItem(
        title: 'Turf Bookings',
        icon: Icons.calendar_today,
        iconColor: const Color(AppColors.primaryColor),
        onTap: () {
          Get.back();
          Get.toNamed(AppConstants.routes.myBookings);
        },
      ),
    ];
  }

  List<DrawerMenuItem> _getCommonItems() {
    return [
      DrawerMenuItem(
        title: 'Profile',
        icon: Icons.person,
        iconColor: const Color(AppColors.primaryColor),
        onTap: () {
          Get.back();
          Get.toNamed(AppConstants.routes.profile);
        },
      ),
      DrawerMenuItem(
        title: 'Settings',
        icon: Icons.settings,
        iconColor: const Color(AppColors.primaryColor),
        onTap: () {
          Get.back();
          Get.toNamed(AppConstants.routes.settings);
        },
      ),
    ];
  }

  Widget _buildModeSwitchCard(SettingsController settingsController) {
    return Obx(() {
      final Color primary = const Color(AppColors.primaryColor);
      final bool isPlayer = settingsController.isPlayerMode;
      final String title = isPlayer ? 'Become a host' : 'Become a player';
      final String subtitle = isPlayer
          ? 'List turfs and take bookings'
          : 'Book venues and play';

      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            settingsController.toggleMode();
            Get.back();
          },
          borderRadius: BorderRadius.circular(14),
          splashColor: primary.withValues(alpha: 0.12),
          highlightColor: primary.withValues(alpha: 0.06),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: primary.withValues(alpha: 0.06),
              border: Border.all(color: primary.withValues(alpha: 0.18)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    isPlayer
                        ? Icons.storefront_outlined
                        : Icons.sports_soccer_outlined,
                    color: primary,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                            height: 1.2,
                            color: Color(AppColors.textColor),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            height: 1.25,
                            color: Color(AppColors.textSecondaryColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: primary.withValues(alpha: 0.55),
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildMenuItem(DrawerMenuItem item) {
    return ListTile(
      leading: Icon(
        item.icon,
        color: item.iconColor ?? const Color(AppColors.primaryColor),
      ),
      title: Text(
        item.title,
        style: TextStyle(
          color: item.textColor ?? const Color(AppColors.textColor),
        ),
      ),
      onTap: item.onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AuthStateController authController = Get.find();
    final SettingsController settingsController = Get.find();
    final String? avatar = authController.user?.avatar;
    return Drawer(
      backgroundColor: const Color(AppColors.surfaceColor),
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: IntrinsicHeight(
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
                    accountEmail: Text(authController.user?.email ?? ''),
                    currentAccountPicture: CircleAvatar(
                      backgroundColor: Colors.white,
                      backgroundImage: avatar != null
                          ? NetworkImage(avatar)
                          : null,
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                  child: _buildModeSwitchCard(settingsController),
                ),
                const Divider(color: Color(AppColors.dividerColor)),
                // Navigation Items
                // ListTile(
                //   leading: const Icon(
                //     Icons.dashboard,
                //     color: Color(AppColors.primaryColor),
                //   ),
                //   title: const Text(
                //     'Dashboard',
                //     style: TextStyle(color: Color(AppColors.textColor)),
                //   ),
                //   onTap: () => Get.back(),
                // ),

                // Mode Specific Items
                Obx(() {
                  final List<DrawerMenuItem> modeItems =
                      settingsController.currentMode.value == UserMode.player
                      ? _getPlayerModeItems()
                      : _getProprietorModeItems();

                  return Column(
                    children: modeItems.map(_buildMenuItem).toList(),
                  );
                }),

                const Divider(color: Color(AppColors.dividerColor)),

                // Common Items (Profile, Settings)
                ..._getCommonItems().map((item) => _buildMenuItem(item)),

                const Spacer(),

                ListTile(
                  leading: const Icon(
                    Icons.help_outline_rounded,
                    color: Color(AppColors.primaryColor),
                  ),
                  title: const Text(
                    'Help & support',
                    style: TextStyle(color: Color(AppColors.textColor)),
                  ),
                  onTap: () {
                    Get.back();
                    Get.toNamed(AppConstants.routes.helpSupport);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.info_outline_rounded,
                    color: Color(AppColors.primaryColor),
                  ),
                  title: const Text(
                    'About',
                    style: TextStyle(color: Color(AppColors.textColor)),
                  ),
                  onTap: () {
                    Get.back();
                    Get.toNamed(AppConstants.routes.about);
                  },
                ),

                // Logout Section
                const Divider(color: Color(AppColors.dividerColor)),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Get.back();
                    _showLogoutDialog(context, authController);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
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
