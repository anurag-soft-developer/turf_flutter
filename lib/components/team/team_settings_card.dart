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
            const Divider(height: 1, indent: 16, endIndent: 16),
            _settingsSwitchTile(
              icon: Icons.sports_kabaddi_outlined,
              title: 'Open for match',
              subtitle:
                  'Appear as available in match finder and similar lists.',
              value: team.teamOpenForMatch,
              busy: busy,
              onChanged: (v) =>
                  controller.updateTeamSettings(teamOpenForMatch: v),
            ),
          ],
        ),
      );
    });
  }
}

class TeamRecruitmentSettingsCard extends StatelessWidget {
  const TeamRecruitmentSettingsCard({
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
      final options = <int>{50, 100, 500};
      if (!options.contains(team.maxPendingJoinRequests)) {
        options.add(team.maxPendingJoinRequests);
      }
      final sortedOptions = options.toList()..sort();

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
            const _CardSectionHeader(title: 'Recruitment Settings'),
            _settingsSwitchTile(
              icon: Icons.person_add_alt_outlined,
              title: 'Looking for members',
              subtitle: 'Show that you are recruiting new players.',
              value: team.lookingForMembers,
              busy: busy,
              onChanged: (v) =>
                  controller.updateTeamSettings(lookingForMembers: v),
            ),
            if (team.lookingForMembers) ...[
              const Divider(height: 1, indent: 16, endIndent: 16),
              _settingsSwitchTile(
                icon: Icons.how_to_reg_outlined,
                title: 'Open join',
                subtitle:
                    'When on, new players join without owner approval (public teams only).',
                value: team.joinMode == TeamJoinMode.open,
                busy: busy,
                onChanged: (v) => controller.updateTeamSettings(
                  joinMode: v ? TeamJoinMode.open : TeamJoinMode.approval,
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(
                          AppColors.primaryColor,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.group_outlined,
                        color: Color(AppColors.primaryColor),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Max pending requests',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Color(AppColors.textColor),
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Limit how many join requests can wait for approval.',
                            style: TextStyle(
                              color: Color(AppColors.textSecondaryColor),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 104,
                      child: DropdownButtonFormField<int>(
                        initialValue: team.maxPendingJoinRequests,
                        isExpanded: true,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          filled: true,
                          fillColor: const Color(AppColors.backgroundColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                            ),
                          ),
                        ),
                        items: sortedOptions
                            .map(
                              (value) => DropdownMenuItem<int>(
                                value: value,
                                child: Text('$value'),
                              ),
                            )
                            .toList(),
                        onChanged: busy
                            ? null
                            : (value) {
                                if (value == null ||
                                    value == team.maxPendingJoinRequests) {
                                  return;
                                }
                                controller.updateTeamSettings(
                                  maxPendingJoinRequests: value,
                                );
                              },
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
