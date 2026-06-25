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
        final eventBookingModuleOn =
            user?.notificationModules?[NotificationModule.eventBooking] ?? true;
        final teamsModuleOn =
            user?.notificationModules?[NotificationModule.teams] ?? true;
        final connectionsModuleOn =
            user?.notificationModules?[NotificationModule.connections] ?? true;
        final withdrawalsModuleOn =
            user?.notificationModules?[NotificationModule.withdrawals] ?? true;
        final turfApprovalModuleOn =
            user?.notificationModules?[NotificationModule.turfApproval] ?? true;

        final hasDeliveryChannel = smsOn || emailOn;
        final canEditChannels = masterOn && !busy;
        final canEditModules = masterOn && hasDeliveryChannel && !busy;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 1,
                color: _surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Notification',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: busy ? theme.disabledColor : _text,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Turn this off to pause push and all alerts below.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: busy
                                    ? theme.disabledColor
                                    : _textSecondary,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Switch(
                        value: masterOn,
                        activeThumbColor: Colors.white,
                        activeTrackColor: _primary,
                        onChanged: busy
                            ? null
                            : (enabled) {
                                authController.updateNotificationSettings(
                                  notificationsEnabled: enabled,
                                );
                              },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _SectionLabel(
                title: 'Delivery channels',
                subtitle: masterOn
                    ? 'How we reach you — texts and email.'
                    : 'Enable notifications above to change these.',
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
                    _CompactSwitchTile(
                      icon: Icons.sms_outlined,
                      title: 'SMS',
                      subtitle: 'Text messages for important alerts',
                      value: smsOn,
                      enabled: canEditChannels,
                      onChanged: (enabled) {
                        authController.updateNotificationSettings(
                          smsNotificationsEnabled: enabled,
                        );
                      },
                    ),
                    const Divider(height: 1, color: _divider),
                    _CompactSwitchTile(
                      icon: Icons.email_outlined,
                      title: 'Email',
                      subtitle: 'Booking updates, reminders, and account alerts',
                      value: emailOn,
                      enabled: canEditChannels,
                      onChanged: (enabled) {
                        authController.updateNotificationSettings(
                          emailNotificationsEnabled: enabled,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              _SectionLabel(
                title: 'Alerts by topic',
                subtitle: !masterOn
                    ? 'Enable notifications above first.'
                    : !hasDeliveryChannel
                        ? 'Turn on SMS or Email above to choose topic alerts.'
                        : 'Fine-tune alerts by topic.',
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
                    _CompactSwitchTile(
                      icon: Icons.sports_soccer,
                      title: 'Turf booking',
                      subtitle: 'Bookings, reminders, and turf-related notices',
                      value: turfModuleOn,
                      enabled: canEditModules,
                      onChanged: (enabled) {
                        authController.updateNotificationSettings(
                          notificationModules: {
                            NotificationModule.turfBooking: enabled,
                          },
                        );
                      },
                    ),
                    const Divider(height: 1, color: _divider),
                    _CompactSwitchTile(
                      icon: Icons.groups_outlined,
                      title: 'Matchmaking',
                      subtitle: 'Match requests and matchmaking updates',
                      value: matchmakingModuleOn,
                      enabled: canEditModules,
                      onChanged: (enabled) {
                        authController.updateNotificationSettings(
                          notificationModules: {
                            NotificationModule.matchmaking: enabled,
                          },
                        );
                      },
                    ),
                    const Divider(height: 1, color: _divider),
                    _CompactSwitchTile(
                      icon: Icons.event_available_outlined,
                      title: 'Event booking',
                      subtitle: 'Event registrations and cancellations',
                      value: eventBookingModuleOn,
                      enabled: canEditModules,
                      onChanged: (enabled) {
                        authController.updateNotificationSettings(
                          notificationModules: {
                            NotificationModule.eventBooking: enabled,
                          },
                        );
                      },
                    ),
                    const Divider(height: 1, color: _divider),
                    _CompactSwitchTile(
                      icon: Icons.shield_outlined,
                      title: 'Teams',
                      subtitle: 'Join requests and roster updates',
                      value: teamsModuleOn,
                      enabled: canEditModules,
                      onChanged: (enabled) {
                        authController.updateNotificationSettings(
                          notificationModules: {
                            NotificationModule.teams: enabled,
                          },
                        );
                      },
                    ),
                    const Divider(height: 1, color: _divider),
                    _CompactSwitchTile(
                      icon: Icons.person_add_alt_1_outlined,
                      title: 'Connections',
                      subtitle: 'Connection requests and responses',
                      value: connectionsModuleOn,
                      enabled: canEditModules,
                      onChanged: (enabled) {
                        authController.updateNotificationSettings(
                          notificationModules: {
                            NotificationModule.connections: enabled,
                          },
                        );
                      },
                    ),
                    const Divider(height: 1, color: _divider),
                    _CompactSwitchTile(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Withdrawals',
                      subtitle: 'Payout and withdrawal status updates',
                      value: withdrawalsModuleOn,
                      enabled: canEditModules,
                      onChanged: (enabled) {
                        authController.updateNotificationSettings(
                          notificationModules: {
                            NotificationModule.withdrawals: enabled,
                          },
                        );
                      },
                    ),
                    const Divider(height: 1, color: _divider),
                    _CompactSwitchTile(
                      icon: Icons.verified_outlined,
                      title: 'Turf approval',
                      subtitle: 'Turf listing review and publish updates',
                      value: turfApprovalModuleOn,
                      enabled: canEditModules,
                      onChanged: (enabled) {
                        authController.updateNotificationSettings(
                          notificationModules: {
                            NotificationModule.turfApproval: enabled,
                          },
                        );
                      },
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

class _CompactSwitchTile extends StatelessWidget {
  const _CompactSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  static const Color _primary = Color(AppColors.primaryColor);
  static const Color _text = Color(AppColors.textColor);
  static const Color _textSecondary = Color(AppColors.textSecondaryColor);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = enabled ? _text : theme.disabledColor;
    final subtitleColor = enabled ? _textSecondary : theme.disabledColor;
    final iconColor = enabled ? _primary : theme.disabledColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                    height: 1.2,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: subtitleColor,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.72,
            child: Switch(
              value: value,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              activeThumbColor: Colors.white,
              activeTrackColor: _primary,
              onChanged: enabled ? onChanged : null,
            ),
          ),
        ],
      ),
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
            fontSize: 14,
            fontWeight: FontWeight.w600,
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
