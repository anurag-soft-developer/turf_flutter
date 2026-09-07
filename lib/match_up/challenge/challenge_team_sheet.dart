import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../components/match_up/my_team_selector.dart';
import '../../components/match_up/team_logo.dart';
import '../../core/config/constants.dart';
import '../../core/models/team/team_member_field_instance.dart';
import '../../team/model/team_model.dart';
import 'challenge_controller.dart';

void onChallengePressed({
  required BuildContext context,
  required ChallengeController controller,
  required TeamModel opponent,
}) {
  if (controller.hasTeamToChallengeWith(opponent)) {
    showChallengeTeamSheet(
      context: context,
      controller: controller,
      opponent: opponent,
    );
    return;
  }
  showCreateTeamForChallengeDialog(context, controller, opponent);
}

Future<void> showCreateTeamForChallengeDialog(
  BuildContext context,
  ChallengeController controller,
  TeamModel opponent,
) async {
  final sportLabel = opponent.sportType.label;
  final create = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('No $sportLabel team'),
      content: Text(
        'Create a $sportLabel team to challenge ${opponent.name}.',
        style: const TextStyle(
          fontSize: 14,
          color: Color(AppColors.textSecondaryColor),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Create Team'),
        ),
      ],
    ),
  );
  if (create == true) {
    await Get.toNamed(AppConstants.routes.addTeam);
    await controller.loadMemberships();
  }
}

void showChallengeTeamSheet({
  required BuildContext context,
  required ChallengeController controller,
  required TeamModel opponent,
}) {
  controller.prepareForOpponent(opponent);
  final teamsForSport = controller.myTeamsForSport(opponent.sportType);
  if (controller.selectedTeam.value == null || teamsForSport.isEmpty) {
    showCreateTeamForChallengeDialog(context, controller, opponent);
    return;
  }

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => ChallengeTeamSheet(
      controller: controller,
      teamsForSport: teamsForSport,
      opponent: opponent,
      onConfirm: () {
        Navigator.pop(context);
        controller.sendChallenge(opponent);
      },
    ),
  );
}

class ChallengeTeamSheet extends StatelessWidget {
  const ChallengeTeamSheet({
    super.key,
    required this.controller,
    required this.teamsForSport,
    required this.opponent,
    required this.onConfirm,
  });

  final ChallengeController controller;
  final List<TeamMemberFieldInstance> teamsForSport;
  final TeamModel opponent;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Obx(() {
            final selected = controller.selectedTeam.value;
            final myTeamName = selected?.name ?? 'Your Team';
            final myTeamLogo = selected?.logo ?? '';
            const double logoSize = 75;
            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 92,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MyTeamSelector(
                            teams: teamsForSport
                                .where((t) => t.id != opponent.id)
                                .toList(),
                            selectedTeam: selected,
                            onTeamSelected: controller.selectTeam,
                            buttonChild: SizedBox(
                              width: logoSize,
                              height: logoSize,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  TeamLogo(url: myTeamLogo, size: logoSize),
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          AppColors.primaryColor,
                                        ),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.edit,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            myTeamName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(AppColors.textColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'VS',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: const Color(
                            AppColors.primaryColor,
                          ).withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 92,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TeamLogo(url: opponent.logo, size: logoSize),
                          const SizedBox(height: 8),
                          Text(
                            opponent.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(AppColors.textColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            );
          }),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    side: const BorderSide(
                      color: Color(AppColors.dividerColor),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(AppColors.textSecondaryColor),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(AppColors.primaryColor),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sports_mma, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Send Challenge',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ChallengeButton extends StatelessWidget {
  const ChallengeButton({
    super.key,
    required this.isSent,
    this.isReceived = false,
    this.onTap,
  });

  final bool isSent;
  final bool isReceived;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor;
    final Color foregroundColor;
    final IconData icon;
    final String label;
    final bool enabled;

    if (isReceived) {
      backgroundColor = const Color(AppColors.secondaryColor);
      foregroundColor = Colors.white;
      icon = Icons.inbox_outlined;
      label = 'Received';
      enabled = onTap != null;
    } else if (isSent) {
      backgroundColor = const Color(AppColors.dividerColor);
      foregroundColor = const Color(AppColors.textSecondaryColor);
      icon = Icons.check_circle_outline;
      label = 'Sent';
      enabled = false;
    } else {
      backgroundColor = const Color(AppColors.primaryColor);
      foregroundColor = Colors.white;
      icon = Icons.sports_mma;
      label = 'Challenge';
      enabled = onTap != null;
    }

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: foregroundColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: foregroundColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
