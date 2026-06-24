import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/auth/auth_state_controller.dart';
import '../../core/config/constants.dart';
import 'custom_button.dart';

class AppMenuItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? backgroundColor;

  const AppMenuItem({
    required this.title,
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.backgroundColor,
  });
}

class AppMenuScreen extends StatelessWidget {
  const AppMenuScreen({super.key});

  List<AppMenuItem> _getPlayerModeItems() {
    return [
      AppMenuItem(
        title: 'My Bookings',
        icon: Icons.book_online_rounded,
        onTap: () => _navigateTo(AppConstants.routes.myBookings),
      ),
      AppMenuItem(
        title: 'My Teams',
        icon: Icons.groups_rounded,
        onTap: () => _navigateTo(AppConstants.routes.myTeams),
      ),
      AppMenuItem(
        title: 'Openings',
        icon: Icons.group_add_rounded,
        onTap: () => _navigateTo(AppConstants.routes.teamOpenings),
      ),
      AppMenuItem(
        title: 'Challenges',
        icon: Icons.sports_soccer_rounded,
        onTap: () => _navigateTo(AppConstants.routes.matchUpChallenges),
      ),
      AppMenuItem(
        title: 'Notifications',
        icon: Icons.notifications_rounded,
        onTap: () => _navigateTo(AppConstants.routes.notifications),
      ),
    ];
  }

  List<AppMenuItem> _getAppItems() {
    return [
      AppMenuItem(
        title: 'Settings',
        icon: Icons.settings_rounded,
        onTap: () => _navigateTo(AppConstants.routes.settings),
      ),
      AppMenuItem(
        title: 'Help & Support',
        icon: Icons.help_outline_rounded,
        onTap: () => _navigateTo(AppConstants.routes.helpSupport),
      ),
      AppMenuItem(
        title: 'About',
        icon: Icons.info_outline_rounded,
        onTap: () => _navigateTo(AppConstants.routes.about),
      ),
    ];
  }

  void _navigateTo(String route) {
    Get.toNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthStateController>();
    final playerItems = _getPlayerModeItems();
    final appItems = _getAppItems();

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(() => _buildProfileHeader(authController)),
                    const SizedBox(height: 28),
                    _buildSectionTitle('App'),
                    const SizedBox(height: 12),
                    _buildMenuGrid(playerItems),
                    const SizedBox(height: 28),
                    _buildSectionTitle('Other'),
                    const SizedBox(height: 12),
                    _buildMenuList(appItems),
                    const SizedBox(height: 32),
                    CustomButton(
                      text: 'Logout',
                      isOutlined: true,
                      backgroundColor: Colors.red,
                      textColor: Colors.red,
                      icon: const Icon(
                        Icons.logout_rounded,
                        size: 20,
                        color: Colors.red,
                      ),
                      onPressed: () =>
                          _showLogoutDialog(context, authController),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: Get.back,
            icon: const Icon(Icons.arrow_back_rounded),
            color: const Color(AppColors.textColor),
          ),
          const Expanded(
            child: Text(
              'Menu',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(AppColors.textColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(AuthStateController authController) {
    final avatar = authController.user?.avatar;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(AppColors.primaryColor),
            Color(AppColors.secondaryColor),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(AppColors.primaryColor).withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white,
                backgroundImage:
                    avatar != null ? NetworkImage(avatar) : null,
                child: avatar == null
                    ? const Icon(
                        Icons.person_rounded,
                        color: Color(AppColors.primaryColor),
                        size: 28,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authController.user?.fullName ?? 'User',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      authController.user?.email ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Get.toNamed(AppConstants.routes.profile),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white70),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              icon: const Icon(Icons.person_outline_rounded, size: 16),
              label: const Text('View Profile'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Color(AppColors.textColor),
      ),
    );
  }

  Widget _buildMenuGrid(List<AppMenuItem> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (context, index) => _buildGridTile(items[index]),
    );
  }

  Widget _buildGridTile(AppMenuItem item) {
    return Material(
      color: const Color(AppColors.surfaceColor),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(AppColors.dividerColor).withValues(alpha: 0.6),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (item.backgroundColor ??
                          const Color(AppColors.primaryColor))
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item.icon,
                  color:
                      item.iconColor ?? const Color(AppColors.primaryColor),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(AppColors.textColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuList(List<AppMenuItem> items) {
    return Column(
      children: items.map(_buildListTile).toList(),
    );
  }

  Widget _buildListTile(AppMenuItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: const Color(AppColors.surfaceColor),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    const Color(AppColors.dividerColor).withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(AppColors.primaryColor)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    item.icon,
                    color: item.iconColor ?? const Color(AppColors.primaryColor),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(AppColors.textColor),
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(AppColors.textSecondaryColor),
                ),
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
