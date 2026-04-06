import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/config/constants.dart';
import '../members/model/team_member_model.dart';
import '../model/team_model.dart';
import '../utils/team_media_url.dart';
import '../utils/team_ui.dart';
import 'team_detail_controller.dart';

class TeamDetailScreen extends StatelessWidget {
  const TeamDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TeamDetailController controller = Get.find();

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: Obx(() {
          final name = controller.team.value?.name;
          return Text(
            name ?? (controller.isMyTeamMode ? 'My Team' : 'Team Profile'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }),
        backgroundColor: const Color(AppColors.primaryColor),
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        // Edit only available in my-team mode, and only for owners.
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
      // Bottom bar: join actions for visitors (team-profile mode only).
      // The isMyTeamMode check is OUTSIDE the Obx so the Obx always
      // observes at least one reactive variable and GetX doesn't warn.
      bottomNavigationBar: controller.isMyTeamMode
          ? null
          : Obx(() {
              final t = controller.team.value;
              if (t == null) return const SizedBox.shrink();

              // Owners manage via in-body actions; no bottom bar for them.
              if (controller.isOwner) return const SizedBox.shrink();

              if (controller.isMember) {
                return SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: OutlinedButton(
                      onPressed: null,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('You are a member'),
                    ),
                  ),
                );
              }

              if (controller.hasPendingRequest) {
                return SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: OutlinedButton(
                      onPressed: null,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Join request pending…'),
                    ),
                  ),
                );
              }

              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: ElevatedButton(
                    onPressed: controller.isJoining.value
                        ? null
                        : controller.sendJoinRequest,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: const Color(AppColors.primaryColor),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: controller.isJoining.value
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Send joining request',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              );
            }),
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

            // My-Team mode: no team yet → show empty state
            if (t == null && controller.isMyTeamMode) {
              return _NoTeamBody(
                onAddTeam: () => Get.toNamed(AppConstants.routes.addTeam),
                onJoinTeam: () => Get.toNamed(AppConstants.routes.teamsRanking),
              );
            }

            // Team-profile mode or error: no team
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
                child: Column(
                  children: [
                    _TeamHeroHeader(team: t),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // About
                          if (t.description != null &&
                              t.description!.isNotEmpty) ...[
                            const _SectionTitle(text: 'About'),
                            const SizedBox(height: 12),
                            _InfoCard(
                              children: [
                                _InfoRow(
                                  icon: Icons.info_outline,
                                  label: 'Description',
                                  value: t.description!,
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                          ],

                          // Team info
                          const _SectionTitle(text: 'Team info'),
                          const SizedBox(height: 12),
                          _InfoCard(
                            children: [
                              _InfoRow(
                                icon: Icons.sports_soccer_outlined,
                                label: 'Sport',
                                value: teamSportLabel(t.sportType),
                              ),
                              const Divider(height: 1),
                              _InfoRow(
                                icon: Icons.visibility_outlined,
                                label: 'Visibility',
                                value: teamVisibilityLabel(t.visibility),
                              ),
                              const Divider(height: 1),
                              _InfoRow(
                                icon: Icons.how_to_reg_outlined,
                                label: 'Joining',
                                value: teamJoinModeLabel(t.joinMode),
                              ),
                              const Divider(height: 1),
                              _InfoRow(
                                icon: Icons.group_outlined,
                                label: 'Roster limit',
                                value: '${t.maxRosterSize} players',
                              ),
                              if (t.status != TeamStatus.active) ...[
                                const Divider(height: 1),
                                _InfoRow(
                                  icon: Icons.info_outline,
                                  label: 'Status',
                                  value: t.status.name.toUpperCase(),
                                  valueColor: const Color(AppColors.errorColor),
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 28),

                          // Members
                          const _SectionTitle(text: 'Members'),
                          const SizedBox(height: 12),
                          _MembersList(members: controller.members),

                          // Actions only shown in my-team mode.
                          // Ownership/membership is checked here AND enforced
                          // server-side through the controller guards.
                          if (controller.isMyTeamMode)
                            Obx(() {
                              final isOwner = controller.isOwner;
                              final isMember = controller.isMember;
                              if (!isOwner && !isMember) {
                                return const SizedBox.shrink();
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 28),
                                  const _SectionTitle(text: 'Team actions'),
                                  const SizedBox(height: 12),
                                  _TeamActionsCard(
                                    isOwner: isOwner,
                                    isMember: isMember,
                                    isActionLoading:
                                        controller.isActionLoading.value,
                                    teamStatus: t.status,
                                    onToggleStatus: () => _confirmToggleStatus(
                                      context,
                                      controller,
                                    ),
                                    onLeave: () =>
                                        _confirmLeave(context, controller),
                                  ),
                                ],
                              );
                            }),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          // Action-busy overlay (my-team mode only).
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
// Hero header
// ─────────────────────────────────────────────────────────────────────────────

class _TeamHeroHeader extends StatefulWidget {
  const _TeamHeroHeader({required this.team});

  final TeamModel team;

  @override
  State<_TeamHeroHeader> createState() => _TeamHeroHeaderState();
}

class _TeamHeroHeaderState extends State<_TeamHeroHeader> {
  final PageController _pageCtrl = PageController();
  int _current = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final covers = widget.team.coverImages
        .map(resolveTeamMediaUrl)
        .whereType<String>()
        .toList();
    final logoUrl = resolveTeamMediaUrl(widget.team.logo);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(AppColors.primaryColor),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Cover carousel
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
            child: covers.isEmpty
                ? Container(
                    height: 180,
                    color: Colors.white.withValues(alpha: 0.10),
                    child: const Center(
                      child: Icon(
                        Icons.image_outlined,
                        size: 56,
                        color: Colors.white54,
                      ),
                    ),
                  )
                : Column(
                    children: [
                      SizedBox(
                        height: 180,
                        child: PageView.builder(
                          controller: _pageCtrl,
                          itemCount: covers.length,
                          onPageChanged: (i) => setState(() => _current = i),
                          itemBuilder: (_, i) => Image.network(
                            covers[i],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.white.withValues(alpha: 0.10),
                              child: const Icon(
                                Icons.broken_image_outlined,
                                color: Colors.white54,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (covers.length > 1) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            covers.length,
                            (i) => AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: _current == i ? 20 : 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: _current == i
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),

          // Logo + name + sport + status badge
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            child: Column(
              children: [
                Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 4,
                  shadowColor: Colors.black38,
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: const Color(
                      AppColors.primaryColor,
                    ).withValues(alpha: 0.12),
                    backgroundImage: logoUrl != null
                        ? NetworkImage(logoUrl)
                        : null,
                    child: logoUrl == null
                        ? const Icon(
                            Icons.shield_outlined,
                            size: 44,
                            color: Color(AppColors.primaryColor),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.team.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  teamSportLabel(widget.team.sportType),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.90),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: widget.team.status == TeamStatus.active
                        ? const Color(AppColors.successColor)
                        : const Color(AppColors.errorColor),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.team.status == TeamStatus.active
                            ? Icons.verified
                            : Icons.block,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.team.status == TeamStatus.active
                            ? 'Active'
                            : 'Inactive',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Members list
// ─────────────────────────────────────────────────────────────────────────────

class _MembersList extends StatelessWidget {
  const _MembersList({required this.members});

  final List<TeamMemberModel> members;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return Card(
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Center(
            child: Text(
              'No active members yet.',
              style: TextStyle(color: Color(AppColors.textSecondaryColor)),
            ),
          ),
        ),
      );
    }

    return Card(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          for (int i = 0; i < members.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            _MemberRow(member: members[i]),
          ],
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member});

  final TeamMemberModel member;

  @override
  Widget build(BuildContext context) {
    final helper = member.userHelper;
    final role = leadershipRoleLabel(member.leadershipRole);
    final subtitle = role.isEmpty ? teamMemberStatusLabel(member.status) : role;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(
          AppColors.primaryColor,
        ).withValues(alpha: 0.12),
        backgroundImage:
            helper.getAvatar() != null && helper.getAvatar()!.isNotEmpty
            ? NetworkImage(helper.getAvatar()!)
            : null,
        child: helper.getAvatar() == null || helper.getAvatar()!.isEmpty
            ? const Icon(Icons.person, color: Color(AppColors.primaryColor))
            : null,
      ),
      title: Text(
        helper.getDisplayName(),
        style: const TextStyle(
          color: Color(AppColors.textColor),
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Color(AppColors.textSecondaryColor)),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => Get.toNamed(
        AppConstants.routes.teamMemberProfile,
        arguments: {'user': member.user},
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Team actions card
// ─────────────────────────────────────────────────────────────────────────────

class _TeamActionsCard extends StatelessWidget {
  const _TeamActionsCard({
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

    return Card(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          if (isOwner) ...[
            ListTile(
              leading: Icon(
                isActive ? Icons.block_outlined : Icons.check_circle_outline,
                color: isActive
                    ? const Color(AppColors.errorColor)
                    : const Color(AppColors.successColor),
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
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: isActionLoading ? null : onToggleStatus,
            ),
            if (isMember) const Divider(height: 1),
          ],
          if (isMember)
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text(
                'Leave team',
                style: TextStyle(color: Colors.red),
              ),
              subtitle: const Text(
                'Remove yourself from this team',
                style: TextStyle(color: Color(AppColors.textSecondaryColor)),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: isActionLoading ? null : onLeave,
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared small widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(AppColors.textColor),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: children),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(AppColors.primaryColor)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(AppColors.textSecondaryColor),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? const Color(AppColors.textColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// No-team empty state (my-team mode only)
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
        const SizedBox(height: 48),
        Icon(
          Icons.groups_2_outlined,
          size: 88,
          color: const Color(AppColors.primaryColor).withValues(alpha: 0.35),
        ),
        const SizedBox(height: 24),
        const Text(
          'No team yet',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(AppColors.textColor),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Create your own squad or browse public teams and ask to join.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: Color(AppColors.textSecondaryColor),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 36),
        ElevatedButton(
          onPressed: onAddTeam,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: const Color(AppColors.primaryColor),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Add your own team'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: onJoinTeam,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            foregroundColor: const Color(AppColors.primaryColor),
            side: const BorderSide(color: Color(AppColors.primaryColor)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Join a team'),
        ),
      ],
    );
  }
}
