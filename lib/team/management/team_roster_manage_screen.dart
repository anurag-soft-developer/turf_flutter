import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/config/constants.dart';
import '../members/model/team_member_model.dart';
import '../utils/team_ui.dart';
import 'team_roster_manage_controller.dart';

class TeamRosterManageScreen extends StatelessWidget {
  const TeamRosterManageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<TeamRosterManageController>();

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: Obx(
          () => Text(
            c.teamName.value != null
                ? 'Manage squad · ${c.teamName.value}'
                : 'Manage squad',
          ),
        ),
      ),
      body: Obx(() {
        if (c.isInitialLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Color(AppColors.primaryColor),
              ),
            ),
          );
        }
        if (c.accessDenied.value) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'You do not have permission to manage this team’s roster.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(AppColors.textSecondaryColor),
                  fontSize: 15,
                ),
              ),
            ),
          );
        }
        if (c.isBusy.value && c.members.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Color(AppColors.primaryColor),
              ),
            ),
          );
        }
        if (c.members.isEmpty) {
          return const Center(
            child: Text(
              'No members in the roster yet.',
              style: TextStyle(
                color: Color(AppColors.textSecondaryColor),
                fontSize: 15,
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: c.loadMembers,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: c.members.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final m = c.members[i];
              final busy = c.actionTargetId.value != null &&
                  c.actionTargetId.value == m.id;
              return _RosterRow(
                member: m,
                isBusy: busy,
                isSelf: c.isSelf(m),
                onOpenProfile: () => c.openProfile(m),
                onRemove: () => _confirmRemove(context, c, m),
                onSuspend: () => _confirmSuspend(context, c, m),
                onUnsuspend: () => c.unsuspendMember(m),
              );
            },
          ),
        );
      }),
    );
  }

  void _confirmRemove(
    BuildContext context,
    TeamRosterManageController c,
    TeamMemberModel m,
  ) {
    final name = m.userHelper.getDisplayName();
    Get.dialog<void>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove player?'),
        content: Text('Remove $name from the team? This cannot be undone here.'),
        actions: [
          TextButton(
            onPressed: () => Get.back<void>(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back<void>();
              c.removeMember(m);
            },
            child: const Text(
              'Remove',
              style: TextStyle(color: Color(AppColors.errorColor)),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmSuspend(
    BuildContext context,
    TeamRosterManageController c,
    TeamMemberModel m,
  ) {
    final name = m.userHelper.getDisplayName();
    Get.dialog<void>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Suspend player?'),
        content: Text(
          'Suspend $name? They will not be able to play until unsuspended.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back<void>(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back<void>();
              c.suspendMember(m);
            },
            child: const Text('Suspend'),
          ),
        ],
      ),
    );
  }
}

class _RosterRow extends StatelessWidget {
  const _RosterRow({
    required this.member,
    required this.isBusy,
    required this.isSelf,
    required this.onOpenProfile,
    required this.onRemove,
    required this.onSuspend,
    required this.onUnsuspend,
  });

  final TeamMemberModel member;
  final bool isBusy;
  final bool isSelf;
  final VoidCallback onOpenProfile;
  final VoidCallback onRemove;
  final VoidCallback onSuspend;
  final VoidCallback onUnsuspend;

  @override
  Widget build(BuildContext context) {
    final h = member.userHelper;
    final avatar = h.getAvatar();
    final name = h.getDisplayName();
    return Card(
      elevation: 0,
      color: const Color(AppColors.surfaceColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: InkWell(
          onTap: onOpenProfile,
          borderRadius: BorderRadius.circular(999),
          child: CircleAvatar(
            backgroundColor: const Color(
              AppColors.primaryColor,
            ).withValues(alpha: 0.12),
            backgroundImage: avatar != null && avatar.isNotEmpty
                ? NetworkImage(avatar)
                : null,
            child: avatar == null || avatar.isEmpty
                ? const Icon(
                    Icons.person,
                    color: Color(AppColors.primaryColor),
                  )
                : null,
          ),
        ),
        title: GestureDetector(
          onTap: onOpenProfile,
          behavior: HitTestBehavior.opaque,
          child: Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(AppColors.textColor),
            ),
          ),
        ),
        subtitle: Text(
          isSelf
              ? 'You (owner) · ${teamMemberStatusLabel(member.status)}'
              : teamMemberStatusLabel(member.status),
          style: const TextStyle(
            fontSize: 12,
            color: Color(AppColors.textSecondaryColor),
          ),
        ),
        trailing: isBusy
            ? const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color(AppColors.primaryColor),
                  ),
                ),
              )
            : PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  color: Color(AppColors.textSecondaryColor),
                ),
                onSelected: (v) {
                  switch (v) {
                    case 'remove':
                      onRemove();
                    case 'suspend':
                      onSuspend();
                    case 'unsuspend':
                      onUnsuspend();
                  }
                },
                itemBuilder: (context) {
                  return [
                    if (!isSelf) ...[
                      if (member.status == TeamMemberStatus.active)
                        const PopupMenuItem(
                          value: 'suspend',
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.pause_circle_outline),
                            title: Text('Suspend'),
                            dense: true,
                          ),
                        ),
                      if (member.status == TeamMemberStatus.suspended)
                        const PopupMenuItem(
                          value: 'unsuspend',
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.restart_alt),
                            title: Text('Unsuspend'),
                            dense: true,
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'remove',
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.person_remove_outlined,
                            color: Color(AppColors.errorColor),
                          ),
                          title: Text('Remove from team'),
                          dense: true,
                        ),
                      ),
                    ],
                  ];
                },
              ),
      ),
    );
  }
}
