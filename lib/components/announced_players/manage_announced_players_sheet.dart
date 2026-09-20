import 'package:flutter/material.dart';
import 'package:flutter_application_1/components/shared/app_network_image.dart';
import 'package:get/get.dart';

import '../match_up/team_logo.dart';
import '../../core/config/constants.dart';
import '../../match_up/model/team_match_model.dart';
import 'util/announced_player_roles_helpers.dart';
import 'casual_guest_sheets.dart';
import 'manage_announced_players_controller.dart';

/// Opens a modal sheet to toggle active roster members as announced players.
Future<void> openManageAnnouncedPlayersSheet({
  required BuildContext context,
  required TeamMatchModel match,
  required String actorTeamId,
  required void Function(TeamMatchModel updated) onSaved,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: const Color(AppColors.backgroundColor),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => ManageAnnouncedPlayersSheet(
      match: match,
      actorTeamId: actorTeamId,
      onSaved: onSaved,
    ),
  );
}

class ManageAnnouncedPlayersSheet extends StatefulWidget {
  const ManageAnnouncedPlayersSheet({
    super.key,
    required this.match,
    required this.actorTeamId,
    required this.onSaved,
  });

  final TeamMatchModel match;
  final String actorTeamId;
  final void Function(TeamMatchModel updated) onSaved;

  @override
  State<ManageAnnouncedPlayersSheet> createState() =>
      _ManageAnnouncedPlayersSheetState();
}

class _ManageAnnouncedPlayersSheetState
    extends State<ManageAnnouncedPlayersSheet> {
  late final ManageAnnouncedPlayersController controller;

  @override
  void initState() {
    super.initState();
    controller = ManageAnnouncedPlayersController(
      match: widget.match,
      actorTeamId: widget.actorTeamId,
      onSaved: widget.onSaved,
    );
    // Not registered with Get — drive lifecycle manually.
    controller.onStart();
  }

  @override
  void dispose() {
    controller.onDelete();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
    final c = controller;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return Obx(() {
            final saving = c.saving.value;
            final loadingRoster = c.loadingRoster.value;
            // Read selection here — ListView.builder itemBuilder runs too late for Obx.
            final selectedIds = c.selectedUserIds.toSet();
            final guestRows = c.visibleGuestRows;
            final orphans = c.orphans;
            final roster = c.roster.toList();
            final rosterError = c.rosterError.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                  child: Row(
                    children: [
                      TeamLogo(url: c.teamLogo, size: 40),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          c.teamName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(AppColors.textColor),
                          ),
                        ),
                      ),
                      if (c.isCasual)
                        TextButton.icon(
                          onPressed: saving
                              ? null
                              : () async {
                                  final draft = await showAddGuestSheet(
                                    context: context,
                                    sport: widget.match.sportType,
                                  );
                                  if (draft == null) return;
                                  c.addPendingGuest(draft);
                                },
                          icon: const Icon(
                            Icons.person_add_alt_outlined,
                            size: 18,
                          ),
                          label: const Text('Add'),
                          style: TextButton.styleFrom(
                            foregroundColor:
                                const Color(AppColors.primaryColor),
                            visualDensity: VisualDensity.compact,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                    ],
                  ),
                ),
                if (c.isCasual && guestRows.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final g in guestRows)
                          _PlayerCard(
                            name: g.name,
                            avatar: g.avatar,
                            roleLabel: announcedRoleLabelForSport(
                              widget.match.sportType,
                              g.role,
                            ),
                            selected: true,
                            showCheckbox: false,
                            onTap: null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _CaptainViceToggles(
                                  controller: c,
                                  participantId: g.participantId,
                                ),
                                IconButton(
                                  tooltip: 'Remove guest',
                                  onPressed: saving
                                      ? null
                                      : () => c.removeGuestFromUi(
                                            g.participantId,
                                            pending: g.pending,
                                          ),
                                  icon: const Icon(Icons.close_rounded),
                                  color: const Color(
                                    AppColors.textSecondaryColor,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 36,
                                    minHeight: 36,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Expanded(
                  child: loadingRoster
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(AppColors.primaryColor),
                            ),
                          ),
                        )
                      : rosterError != null
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      rosterError,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Color(
                                          AppColors.textSecondaryColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextButton(
                                      onPressed: c.loadRoster,
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 8),
                              itemCount: orphans.length + roster.length,
                              itemBuilder: (context, i) {
                                if (i < orphans.length) {
                                  final o = orphans[i];
                                  final uid = o.userIdHelper.getId();
                                  if (uid == null) {
                                    return const SizedBox.shrink();
                                  }
                                  final selected = selectedIds.contains(uid);
                                  return _PlayerCard(
                                    name: o.name,
                                    avatar: o.avatar,
                                    roleLabel: announcedRoleLabelForSport(
                                      widget.match.sportType,
                                      o.role,
                                    ),
                                    selected: selected,
                                    highlight: true,
                                    onTap: saving
                                        ? null
                                        : () => c.toggle(uid),
                                    trailing: selected
                                        ? _CaptainViceToggles(
                                            controller: c,
                                            participantId: uid,
                                          )
                                        : null,
                                  );
                                }
                                final m = roster[i - orphans.length];
                                final uid = m.userHelper.getId();
                                if (uid == null) {
                                  return const SizedBox.shrink();
                                }
                                final selected = selectedIds.contains(uid);
                                return _PlayerCard(
                                  name: m.userHelper.getDisplayName(),
                                  avatar: m.userHelper.getAvatar(),
                                  roleLabel: announcedRoleLabelForSport(
                                    widget.match.sportType,
                                    c.roleForUserId(uid),
                                  ),
                                  selected: selected,
                                  onTap:
                                      saving ? null : () => c.toggle(uid),
                                  trailing: selected
                                      ? _CaptainViceToggles(
                                          controller: c,
                                          participantId: uid,
                                        )
                                      : null,
                                );
                              },
                            ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + bottomPad),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: saving || loadingRoster
                              ? null
                              : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(40),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: saving || loadingRoster
                              ? null
                              : () => c.save(context),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(40),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: saving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Save',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          });
        },
      ),
    );
  }
}

class _CaptainViceToggles extends StatelessWidget {
  const _CaptainViceToggles({
    required this.controller,
    required this.participantId,
  });

  final ManageAnnouncedPlayersController controller;
  final String participantId;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final cap = controller.captainParticipantId.value == participantId;
      final vice =
          controller.viceCaptainParticipantId.value == participantId;
      final disabled =
          controller.saving.value || controller.loadingRoster.value;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: cap ? 'Clear captain' : 'Captain',
            child: Material(
              color: cap
                  ? const Color(AppColors.primaryColor).withValues(alpha: 0.18)
                  : const Color(AppColors.backgroundColor),
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: disabled
                    ? null
                    : () => controller.onCaptainTap(participantId),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: cap
                          ? const Color(AppColors.primaryColor)
                          : const Color(AppColors.dividerColor),
                    ),
                  ),
                  child: Text(
                    'C',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 0.5,
                      color: cap
                          ? const Color(AppColors.primaryColor)
                          : const Color(AppColors.textSecondaryColor),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Tooltip(
            message: vice ? 'Clear vice-captain' : 'Vice-captain',
            child: Material(
              color: vice
                  ? const Color(AppColors.secondaryColor)
                      .withValues(alpha: 0.14)
                  : const Color(AppColors.backgroundColor),
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: disabled
                    ? null
                    : () => controller.onViceCaptainTap(participantId),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: vice
                          ? const Color(AppColors.secondaryColor)
                          : const Color(AppColors.dividerColor),
                    ),
                  ),
                  child: Text(
                    'VC',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 0.2,
                      color: vice
                          ? const Color(AppColors.secondaryColor)
                          : const Color(AppColors.textSecondaryColor),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({
    required this.name,
    required this.roleLabel,
    required this.selected,
    this.avatar,
    this.onTap,
    this.trailing,
    this.highlight = false,
    this.showCheckbox = true,
  });

  final String name;
  final String? avatar;
  final String roleLabel;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool highlight;
  final bool showCheckbox;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: highlight ? Colors.orange.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: highlight
                      ? Colors.orange.withValues(alpha: 0.2)
                      : const Color(AppColors.primaryColor)
                          .withValues(alpha: 0.1),
                  backgroundImage: avatar != null && avatar!.isNotEmpty
                      ? AppNetworkImage.provider(avatar!)
                      : null,
                  child: avatar == null || avatar!.isEmpty
                      ? Icon(
                          highlight
                              ? Icons.person_off_outlined
                              : Icons.person,
                          color: highlight
                              ? Colors.orange.shade800
                              : const Color(AppColors.primaryColor),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Color(AppColors.textColor),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        roleLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: highlight
                              ? Colors.orange.shade900
                              : const Color(AppColors.textSecondaryColor),
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                ],
                if (showCheckbox) ...[
                  const SizedBox(width: 8),
                  Icon(
                    selected ? Icons.check_circle : Icons.circle_outlined,
                    color: selected
                        ? const Color(AppColors.primaryColor)
                        : const Color(AppColors.textSecondaryColor),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
