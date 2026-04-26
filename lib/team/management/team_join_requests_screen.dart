import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/config/constants.dart';
import '../members/model/team_member_model.dart';
import '../utils/team_ui.dart';
import 'team_join_requests_controller.dart';

class TeamJoinRequestsScreen extends StatelessWidget {
  const TeamJoinRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<TeamJoinRequestsController>();

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: Obx(
          () => Text(
            c.teamName.value != null
                ? 'Join requests · ${c.teamName.value}'
                : 'Join requests',
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
                'You do not have access to review join requests for this team.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(AppColors.textSecondaryColor),
                  fontSize: 15,
                ),
              ),
            ),
          );
        }
        if (c.isBusy.value && c.pending.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Color(AppColors.primaryColor),
              ),
            ),
          );
        }
        if (c.pending.isEmpty) {
          return const Center(
            child: Text(
              'No pending join requests.',
              style: TextStyle(
                color: Color(AppColors.textSecondaryColor),
                fontSize: 15,
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: c.loadPending,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: c.pending.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final m = c.pending[i];
              return _PendingApplicantRow(
                member: m,
                onOpenProfile: () => Get.toNamed(
                  AppConstants.routes.teamMemberProfile,
                  arguments: {'user': m.user},
                ),
                isProcessing:
                    c.actionMembershipId.value != null &&
                    c.actionMembershipId.value == m.id,
                onAccept: () => c.accept(m),
                onReject: () => _confirmReject(context, c, m),
              );
            },
          ),
        );
      }),
    );
  }

  void _confirmReject(
    BuildContext context,
    TeamJoinRequestsController c,
    TeamMemberModel m,
  ) {
    final name = m.userHelper.getDisplayName();
    Get.dialog<void>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reject request?'),
        content: Text('Turn down $name’s application?'),
        actions: [
          TextButton(
            onPressed: () => Get.back<void>(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back<void>();
              c.reject(m);
            },
            child: const Text(
              'Reject',
              style: TextStyle(color: Color(AppColors.errorColor)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingApplicantRow extends StatelessWidget {
  const _PendingApplicantRow({
    required this.member,
    required this.onOpenProfile,
    required this.isProcessing,
    required this.onAccept,
    required this.onReject,
  });

  final TeamMemberModel member;
  final VoidCallback onOpenProfile;
  final bool isProcessing;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final h = member.userHelper;
    final avatar = h.getAvatar();
    final name = h.getDisplayName();
    return Card(
      elevation: 0,
      color: const Color(AppColors.surfaceColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onOpenProfile,
              borderRadius: BorderRadius.circular(999),
              child: CircleAvatar(
                radius: 24,
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
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: onOpenProfile,
                    behavior: HitTestBehavior.opaque,
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Color(AppColors.textColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    teamMemberStatusLabel(TeamMemberStatus.pending),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(AppColors.textSecondaryColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            if (isProcessing)
              const Padding(
                padding: EdgeInsets.all(8),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(AppColors.primaryColor),
                    ),
                  ),
                ),
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: onReject,
                    child: const Text('Reject'),
                  ),
                  FilledButton(
                    onPressed: onAccept,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(AppColors.successColor),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Add'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
