import 'package:flutter/material.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';
import '../components/shared/user_avatar_app_bar_action.dart';
import '../core/config/constants.dart';
import '../core/query/query_keys.dart';
import 'player/player_dashboard.dart';
import 'player/player_dashboard_controller.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const UserAvatarAppBarAction(),
        title: Text(
          AppConstants.appName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(AppColors.primaryColor),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Obx(() {
            final count = Get.find<PlayerDashboardController>()
                .unreadNotificationCount
                .value;
            final hasUnread = count > 0;
            final label = count > 99 ? '99+' : '$count';

            return IconButton(
              onPressed: () async {
                await Get.toNamed(AppConstants.routes.notifications);
                if (Get.isRegistered<QueryClient>()) {
                  await Get.find<QueryClient>().invalidateQueries(
                    queryKey: QueryKeys.playerDashboardPrefix,
                  );
                }
              },
              tooltip: 'Notifications',
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    hasUnread
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_rounded,
                    color: hasUnread
                        ? const Color(AppColors.accentColor)
                        : Colors.white,
                  ),
                  if (hasUnread)
                    Positioned(
                      top: -4,
                      left: -6,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 14),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(AppColors.errorColor),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(AppColors.primaryColor),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
      body: const PlayerDashboard(),
    );
  }
}
