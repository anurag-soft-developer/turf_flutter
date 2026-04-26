import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../components/team/profile/team_hero_header.dart';
import '../../components/team/profile/team_info_section.dart';
import '../../components/team/profile/team_member_card.dart';
import '../../components/team/profile/team_quick_stats_bar.dart';
import '../../components/team/profile/team_section_header.dart';
import '../../components/team/profile/team_social_links_row.dart';
import '../../components/team/profile/team_sport_stats_section.dart';
import '../../components/team/team_actions_card.dart';
import '../../components/team/team_settings_card.dart';
import '../../core/config/constants.dart';
import '../members/model/team_member_model.dart';
import '../model/team_model.dart';
import 'team_detail_controller.dart';

class TeamDetailScreen extends StatelessWidget {
  const TeamDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TeamDetailController controller = Get.find();

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (controller.isMyTeamMode)
            Obx(() {
              final t = controller.team.value;
              if (t == null || !controller.isOwner) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit team',
                onPressed: controller.isActionLoading.value
                    ? null
                    : () => Get.toNamed(
                        AppConstants.routes.editTeam,
                        arguments: {'team': t},
                      ),
              );
            }),
        ],
      ),
      bottomNavigationBar: controller.isMyTeamMode
          ? null
          : _BottomJoinBar(controller: controller),
      body: Stack(
        children: [
          Obx(() {
            if (controller.isLoading.value) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color(AppColors.primaryColor),
                  ),
                ),
              );
            }

            final t = controller.team.value;

            if (t == null && controller.isMyTeamMode) {
              return _NoTeamBody(
                onAddTeam: () => Get.toNamed(AppConstants.routes.addTeam),
                onJoinTeam: () => Get.toNamed(AppConstants.routes.teamsRanking),
              );
            }

            if (t == null) {
              return Center(
                child: Text(
                  controller.teamId == null
                      ? 'Missing team ID.'
                      : 'Team not found.',
                  style: const TextStyle(
                    color: Color(AppColors.textSecondaryColor),
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: controller.load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero header
                    TeamHeroHeader(team: t),

                    const SizedBox(height: 16),

                    // Quick stats
                    // if (t.matchesPlayed > 0) ...[
                    TeamQuickStatsBar(team: t),
                    const SizedBox(height: 24),
                    // ] else
                    //   const SizedBox(height: 8),

                    // About & Info
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const TeamSectionHeader(title: 'About'),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TeamInfoSection(team: t),
                    ),

                    const SizedBox(height: 28),

                    // Sport-specific stats
                    // Padding(
                    //   padding: const EdgeInsets.symmetric(horizontal: 20),
                    //   child: TeamSectionHeader(title: 'Stats'),
                    // ),
                    // const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TeamSportStatsSection(team: t),
                    ),
                    const SizedBox(height: 28),

                    // Members
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TeamSectionHeader(
                        title: 'Squad',
                        trailing:
                            controller.isMyTeamMode &&
                                controller.isOwner &&
                                t.id != null &&
                                t.id!.isNotEmpty
                            ? TextButton.icon(
                                onPressed: () => Get.toNamed(
                                  AppConstants.routes.teamRosterManage,
                                  arguments: {'teamId': t.id!},
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(
                                    AppColors.primaryColor,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                                icon: const Icon(
                                  Icons.manage_accounts,
                                  size: 16,
                                ),
                                label: const Text(
                                  'Manage',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (controller.isMyTeamMode &&
                        controller.isOwner &&
                        t.id != null &&
                        t.id!.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _PendingRequestsNotifierCard(teamId: t.id!),
                      ),
                      const SizedBox(height: 12),
                    ],
                    _MembersHorizontalList(members: controller.members),

                    const SizedBox(height: 28),

                    // Social links
                    if (t.socialLinks.instagram != null ||
                        t.socialLinks.twitter != null ||
                        t.socialLinks.facebook != null ||
                        t.socialLinks.youtube != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const TeamSectionHeader(title: 'Connect'),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: TeamSocialLinksRow(links: t.socialLinks),
                      ),
                      const SizedBox(height: 28),
                    ],

                    // Team actions (my-team mode)
                    if (controller.isMyTeamMode)
                      Obx(() {
                        final isOwner = controller.isOwner;
                        final isMember = controller.isMember;
                        final st = controller.team.value;
                        if (st == null || !isOwner && !isMember) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const TeamSectionHeader(title: 'Team Actions'),
                              const SizedBox(height: 12),
                              if (isOwner) ...[
                                TeamSettingsCard(
                                  controller: controller,
                                  team: st,
                                ),
                                const SizedBox(height: 18),
                              ],
                              TeamActionsCard(
                                isOwner: isOwner,
                                isMember: isMember,
                                isActionLoading:
                                    controller.isActionLoading.value,
                                teamStatus: t.status,
                                onToggleStatus: () =>
                                    _confirmToggleStatus(context, controller),
                                onLeave: () =>
                                    _confirmLeave(context, controller),
                              ),

                              const SizedBox(height: 28),
                            ],
                          ),
                        );
                      }),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          }),

          // Action-busy overlay
          if (controller.isMyTeamMode)
            Obx(
              () => controller.isActionLoading.value
                  ? Container(
                      color: Colors.black26,
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(AppColors.primaryColor),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }

  void _confirmToggleStatus(BuildContext context, TeamDetailController c) {
    final t = c.team.value;
    final name = t?.name ?? 'this team';
    final isActive = t?.status == TeamStatus.active;

    Get.dialog<void>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isActive ? 'Deactivate team?' : 'Activate team?'),
        content: Text(
          isActive
              ? '"$name" will be marked inactive.'
              : '"$name" will be marked active again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back<void>(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back<void>();
              isActive ? c.deactivateTeam() : c.activateTeam();
            },
            child: Text(
              isActive ? 'Deactivate' : 'Activate',
              style: TextStyle(
                color: isActive
                    ? const Color(AppColors.errorColor)
                    : const Color(AppColors.successColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLeave(BuildContext context, TeamDetailController c) {
    final name = c.team.value?.name ?? 'this team';
    Get.dialog<void>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Leave team?'),
        content: Text('Are you sure you want to leave "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back<void>(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back<void>();
              c.leaveTeam();
            },
            child: const Text(
              'Leave',
              style: TextStyle(color: Color(AppColors.errorColor)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom join bar (team-profile mode)
// ─────────────────────────────────────────────────────────────────────────────

class _BottomJoinBar extends StatelessWidget {
  const _BottomJoinBar({required this.controller});

  final TeamDetailController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final t = controller.team.value;
      if (t == null) return const SizedBox.shrink();
      if (controller.isOwner) return const SizedBox.shrink();

      if (controller.isMember) {
        return _bottomBarContainer(
          child: OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.check_circle, size: 20),
            label: const Text('You are a member'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        );
      }

      if (controller.hasPendingRequest) {
        return _bottomBarContainer(
          child: OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.hourglass_top, size: 20),
            label: const Text('Join request pending…'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        );
      }

      return _bottomBarContainer(
        child: ElevatedButton.icon(
          onPressed: controller.isJoining.value
              ? null
              : controller.sendJoinRequest,
          icon: controller.isJoining.value
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.group_add, size: 20),
          label: Text(
            controller.isJoining.value ? 'Sending…' : 'Send join request',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: const Color(AppColors.primaryColor),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
        ),
      );
    });
  }

  Widget _bottomBarContainer({required Widget child}) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Members horizontal scrollable list
// ─────────────────────────────────────────────────────────────────────────────

class _MembersHorizontalList extends StatelessWidget {
  const _MembersHorizontalList({required this.members});

  final List<TeamMemberModel> members;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (members.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
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
                  Icon(
                    Icons.group_outlined,
                    size: 40,
                    color: const Color(
                      AppColors.primaryColor,
                    ).withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No active members yet',
                    style: TextStyle(
                      color: Color(AppColors.textSecondaryColor),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 140,
              child: ListView.separated(
                padding: EdgeInsets.zero,
                scrollDirection: Axis.horizontal,
                itemCount: members.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => TeamMemberCard(member: members[i]),
              ),
            ),
        ],
      ),
    );
  }
}

class _PendingRequestsNotifierCard extends StatelessWidget {
  const _PendingRequestsNotifierCard({required this.teamId});

  final String teamId;

  @override
  Widget build(BuildContext context) {
    const placeholderCount = '--';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Get.toNamed(
          AppConstants.routes.teamJoinRequests,
          arguments: {'teamId': teamId},
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(AppColors.primaryColor).withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(
                AppColors.primaryColor,
              ).withValues(alpha: 0.22),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(
                    AppColors.primaryColor,
                  ).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.notifications_active_outlined,
                  size: 18,
                  color: Color(AppColors.primaryColor),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Players applied to join: --',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Color(AppColors.textColor),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  placeholderCount,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(AppColors.primaryColor),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: Color(AppColors.textSecondaryColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// No-team empty state (my-team mode)
// ─────────────────────────────────────────────────────────────────────────────

class _NoTeamBody extends StatelessWidget {
  const _NoTeamBody({required this.onAddTeam, required this.onJoinTeam});

  final VoidCallback onAddTeam;
  final VoidCallback onJoinTeam;

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
          'No team yet',
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
          onPressed: onAddTeam,
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
          onPressed: onJoinTeam,
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
