import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/config/constants.dart';
import '../members/model/team_member_model.dart';
import '../utils/team_ui.dart';
import 'my_teams_controller.dart';

class MyTeamsScreen extends StatelessWidget {
  const MyTeamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final MyTeamsController controller = Get.find();

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(title: const Text('My Teams')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppConstants.routes.addTeam),
        backgroundColor: const Color(AppColors.primaryColor),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Create team',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.memberships.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Color(AppColors.primaryColor),
              ),
            ),
          );
        }

        if (controller.memberships.isEmpty) {
          return _EmptyState();
        }

        return RefreshIndicator(
          onRefresh: controller.reload,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: controller.memberships.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _TeamCard(
              membership: controller.memberships[i],
              roleLabel: controller.roleLabel(controller.memberships[i]),
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Team card
// ─────────────────────────────────────────────────────────────────────────────

class _TeamCard extends StatelessWidget {
  const _TeamCard({required this.membership, required this.roleLabel});

  final TeamMemberModel membership;
  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    final teamRef = membership.team;
    final String teamName;
    final String? logo;
    final TeamSportType? sportType;
    final String? teamId;

    if (teamRef is TeamMemberFieldInstance) {
      teamName = teamRef.name;
      logo = teamRef.logo.isNotEmpty ? teamRef.logo : null;
      sportType = teamRef.sportType;
      teamId = teamRef.id;
    } else {
      teamName = 'Unknown team';
      logo = null;
      sportType = null;
      teamId = membership.teamId;
    }

    return Card(
      elevation: 0,
      color: const Color(AppColors.surfaceColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: teamId == null || teamId.isEmpty
            ? null
            : () => Get.toNamed(
                AppConstants.routes.myTeam,
                arguments: {'teamId': teamId},
              ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Team logo / avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(
                    AppColors.primaryColor,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                clipBehavior: Clip.antiAlias,
                child: logo != null
                    ? Image.network(
                        logo,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _teamInitials(teamName),
                      )
                    : _teamInitials(teamName),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      teamName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(AppColors.textColor),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (sportType != null) ...[
                          Text(
                            teamSportLabel(sportType),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(AppColors.textSecondaryColor),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(
                                AppColors.textSecondaryColor,
                              ).withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              AppColors.primaryColor,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            roleLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(AppColors.primaryColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(AppColors.textSecondaryColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _teamInitials(String name) {
    final initials = name.isNotEmpty
        ? name
              .split(' ')
              .where((w) => w.isNotEmpty)
              .take(2)
              .map((w) => w[0].toUpperCase())
              .join()
        : '?';
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(AppColors.primaryColor),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 80),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(AppColors.primaryColor).withValues(alpha: 0.08),
          ),
          child: Icon(
            Icons.groups_2_outlined,
            size: 52,
            color: const Color(AppColors.primaryColor).withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'No teams yet',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(AppColors.textColor),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Create your own squad or browse\npublic teams and ask to join.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: Color(AppColors.textSecondaryColor),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 36),
        ElevatedButton.icon(
          onPressed: () => Get.toNamed(AppConstants.routes.addTeam),
          icon: const Icon(Icons.add, size: 20),
          label: const Text(
            'Create a team',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            backgroundColor: const Color(AppColors.primaryColor),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => Get.toNamed(AppConstants.routes.teamsRanking),
          icon: const Icon(Icons.search, size: 20),
          label: const Text(
            'Browse teams',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            foregroundColor: const Color(AppColors.primaryColor),
            side: const BorderSide(color: Color(AppColors.primaryColor)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }
}
