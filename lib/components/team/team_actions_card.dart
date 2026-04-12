import 'package:flutter/material.dart';

import '../../core/config/constants.dart';
import '../../team/model/team_model.dart';

/// Activate/deactivate (owner) and leave team (member) actions.
class TeamActionsCard extends StatelessWidget {
  const TeamActionsCard({
    super.key,
    required this.isOwner,
    required this.isMember,
    required this.isActionLoading,
    required this.teamStatus,
    required this.onToggleStatus,
    required this.onLeave,
  });

  final bool isOwner;
  final bool isMember;
  final bool isActionLoading;
  final TeamStatus teamStatus;
  final VoidCallback onToggleStatus;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final isActive = teamStatus == TeamStatus.active;

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
          if (isOwner) ...[
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color:
                      (isActive
                              ? const Color(AppColors.errorColor)
                              : const Color(AppColors.successColor))
                          .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isActive ? Icons.block_outlined : Icons.check_circle_outline,
                  color: isActive
                      ? const Color(AppColors.errorColor)
                      : const Color(AppColors.successColor),
                  size: 20,
                ),
              ),
              title: Text(
                isActive ? 'Deactivate team' : 'Activate team',
                style: TextStyle(
                  color: isActive
                      ? const Color(AppColors.errorColor)
                      : const Color(AppColors.successColor),
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                isActive
                    ? 'Mark this team as inactive'
                    : 'Restore this team to active',
                style: const TextStyle(
                  color: Color(AppColors.textSecondaryColor),
                  fontSize: 12,
                ),
              ),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: isActionLoading ? null : onToggleStatus,
            ),
            if (isMember) const Divider(height: 1, indent: 16, endIndent: 16),
          ],
          if (isMember)
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(
                    AppColors.errorColor,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.exit_to_app,
                  color: Color(AppColors.errorColor),
                  size: 20,
                ),
              ),
              title: const Text(
                'Leave team',
                style: TextStyle(
                  color: Color(AppColors.errorColor),
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text(
                'Remove yourself from this team',
                style: TextStyle(
                  color: Color(AppColors.textSecondaryColor),
                  fontSize: 12,
                ),
              ),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: isActionLoading ? null : onLeave,
            ),
        ],
      ),
    );
  }
}
