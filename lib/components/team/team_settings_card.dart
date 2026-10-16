import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/config/constants.dart';
import '../../team/details/team_detail_controller.dart';
import '../../team/model/team_model.dart';

/// Owner-only team discovery / join preferences (backed by [TeamDetailController]).
class TeamSettingsCard extends StatelessWidget {
  const TeamSettingsCard({
    super.key,
    required this.controller,
    required this.team,
  });

  final TeamDetailController controller;
  final TeamModel team;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final busy = controller.isUpdatingTeamSettings.value;
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            const _CardSectionHeader(title: 'Team Settings'),
            _settingsSwitchTile(
              icon: Icons.public_outlined,
              title: 'Public team',
              subtitle: 'When off, the team is private and harder to discover.',
              value: team.visibility == TeamVisibility.public,
              busy: busy,
              onChanged: (v) => controller.updateTeamSettings(
                visibility: v ? TeamVisibility.public : TeamVisibility.private,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _CardSectionHeader extends StatelessWidget {
  const _CardSectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          color: Color(AppColors.textSecondaryColor),
        ),
      ),
    );
  }
}

Widget _settingsSwitchTile({
  required IconData icon,
  required String title,
  required String subtitle,
  required bool value,
  required bool busy,
  required ValueChanged<bool> onChanged,
}) {
  return SwitchListTile(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    contentPadding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
    secondary: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(AppColors.primaryColor).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: const Color(AppColors.primaryColor), size: 20),
    ),
    title: Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 15,
        color: Color(AppColors.textColor),
      ),
    ),
    subtitle: Text(
      subtitle,
      style: const TextStyle(
        color: Color(AppColors.textSecondaryColor),
        fontSize: 12,
      ),
    ),
    value: value,
    onChanged: busy ? null : onChanged,
    activeThumbColor: Colors.white,
    activeTrackColor: const Color(AppColors.primaryColor),
  );
}
