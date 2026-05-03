import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/auth/auth_state_controller.dart';
import '../core/config/constants.dart';
import '../core/models/user/user_model.dart';

/// Notification preferences: master switch (primary), delivery channels (SMS/email),
/// then per-module topic alerts (enabled only when master is on and a channel is on).
class ManageNotificationsScreen extends StatelessWidget {
  const ManageNotificationsScreen({super.key});

  static const Color _primary = Color(AppColors.primaryColor);
  static const Color _text = Color(AppColors.textColor);
  static const Color _textSecondary = Color(AppColors.textSecondaryColor);
  static const Color _surface = Color(AppColors.surfaceColor);
  static const Color _divider = Color(AppColors.dividerColor);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authController = Get.find<AuthStateController>();

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Obx(() {
        final user = authController.user;
        final busy = authController.notificationSettingsUpdating.value;
        final masterOn = user?.notificationsEnabled ?? true;
        final smsOn = user?.smsNotificationsEnabled ?? false;
        final emailOn = user?.emailNotificationsEnabled ?? true;
        final turfModuleOn =
            user?.notificationModules?[NotificationModule.turfBooking] ?? true;
        final matchmakingModuleOn =
            user?.notificationModules?[NotificationModule.matchmaking] ?? true;

        final hasDeliveryChannel = smsOn || emailOn;
        final canEditChannels = masterOn && !busy;
        final canEditModules = masterOn && hasDeliveryChannel && !busy;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabel(
                title: 'All notifications',
                subtitle:
                    'Turn this off to pause push and all alerts below.',
              ),
              const SizedBox(height: 12),
              Material(
                color: _primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: Icon(
                      Icons.notifications_active_rounded,
                      color: busy ? theme.disabledColor : _primary,
                      size: 28,
                    ),
                    title: Text(
                      'Push & in-app',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: busy ? theme.disabledColor : _text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Primary switch — controls whether notifications run at all.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: busy ? theme.disabledColor : _textSecondary,
                      ),
                    ),
                    value: masterOn,
                    onChanged: busy
                        ? null
                        : (enabled) {
                            authController.updateNotificationSettings(
                              notificationsEnabled: enabled,
                            );
                          },
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _SectionLabel(
                title: 'Delivery channels',
                subtitle: masterOn
                    ? 'How we reach you — texts and email.'
                    : 'Enable “Push & in-app” above to change these.',
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 1,
                color: _surface,
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
                      secondary: Icon(
                        Icons.sms_outlined,
                        color: canEditChannels
                            ? _primary
                            : theme.disabledColor,
                      ),
                      title: Text(
                        'SMS',
                        style: TextStyle(
                          color: canEditChannels ? _text : theme.disabledColor,
                        ),
                      ),
                      subtitle: Text(
                        'Text messages for important alerts',
                        style: TextStyle(
                          color: canEditChannels
                              ? _textSecondary
                              : theme.disabledColor,
                        ),
                      ),
                      value: smsOn,
                      onChanged: canEditChannels
                          ? (enabled) {
                              authController.updateNotificationSettings(
                                smsNotificationsEnabled: enabled,
                              );
                            }
                          : null,
                    ),
                    const Divider(height: 1, color: _divider),
                    SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      secondary: Icon(
                        Icons.email_outlined,
                        color: canEditChannels
                            ? _primary
                            : theme.disabledColor,
                      ),
                      title: Text(
                        'Email',
                        style: TextStyle(
                          color: canEditChannels ? _text : theme.disabledColor,
                        ),
                      ),
                      subtitle: Text(
                        'Booking updates, reminders, and account alerts',
                        style: TextStyle(
                          color: canEditChannels
                              ? _textSecondary
                              : theme.disabledColor,
                        ),
                      ),
                      value: emailOn,
                      onChanged: canEditChannels
                          ? (enabled) {
                              authController.updateNotificationSettings(
                                emailNotificationsEnabled: enabled,
                              );
                            }
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              _SectionLabel(
                title: 'Alerts by topic',
                subtitle: !masterOn
                    ? 'Enable “Push & in-app” above first.'
                    : !hasDeliveryChannel
                        ? 'Turn on SMS or Email above to choose topic alerts.'
                        : 'Fine-tune turf and matchmaking notices.',
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 1,
                color: _surface,
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
                      secondary: Icon(
                        Icons.sports_soccer,
                        color:
                            canEditModules ? _primary : theme.disabledColor,
                      ),
                      title: Text(
                        'Turf booking',
                        style: TextStyle(
                          color:
                              canEditModules ? _text : theme.disabledColor,
                        ),
                      ),
                      subtitle: Text(
                        'Bookings, reminders, and turf-related notices',
                        style: TextStyle(
                          color: canEditModules
                              ? _textSecondary
                              : theme.disabledColor,
                        ),
                      ),
                      value: turfModuleOn,
                      onChanged: canEditModules
                          ? (enabled) {
                              authController.updateNotificationSettings(
                                notificationModules: {
                                  NotificationModule.turfBooking: enabled,
                                },
                              );
                            }
                          : null,
                    ),
                    const Divider(height: 1, color: _divider),
                    SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      secondary: Icon(
                        Icons.groups_outlined,
                        color:
                            canEditModules ? _primary : theme.disabledColor,
                      ),
                      title: Text(
                        'Matchmaking',
                        style: TextStyle(
                          color:
                              canEditModules ? _text : theme.disabledColor,
                        ),
                      ),
                      subtitle: Text(
                        'Match requests and matchmaking updates',
                        style: TextStyle(
                          color: canEditModules
                              ? _textSecondary
                              : theme.disabledColor,
                        ),
                      ),
                      value: matchmakingModuleOn,
                      onChanged: canEditModules
                          ? (enabled) {
                              authController.updateNotificationSettings(
                                notificationModules: {
                                  NotificationModule.matchmaking: enabled,
                                },
                              );
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(AppColors.textColor),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            height: 1.35,
            color: Color(AppColors.textSecondaryColor),
          ),
        ),
      ],
    );
  }
}
