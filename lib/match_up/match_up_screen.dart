import 'package:flutter/material.dart';
import 'package:flutter_application_1/components/shared/app_drawer.dart';
import 'package:get/get.dart';

import '../components/match_up/sport_tabs.dart';
import '../components/match_up/team_logo.dart';
import '../components/match_up/team_stats_row.dart';
import '../core/config/constants.dart';
import '../core/models/team/team_member_field_instance.dart';
import '../team/model/team_model.dart';
import 'match_up_controller.dart';

class MatchUpScreen extends StatelessWidget {
  const MatchUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final MatchUpController c = Get.find();

    return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: const Text('Match Up'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Obx(() => SportTabs(
                selected: c.selectedSport.value,
                onChanged: c.switchSport,
              )),
        ),
      ),
      body: Obx(() {
        if (c.isLoadingMyTeams.value) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Color(AppColors.primaryColor),
              ),
            ),
          );
        }

        if (!c.hasTeamForSport) {
          return _NoTeamPlaceholder(sport: c.selectedSport.value);
        }

        if (c.isLoadingFeed.value && c.feedTeams.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Color(AppColors.primaryColor),
              ),
            ),
          );
        }

        return Column(
          children: [
            _MyTeamSelector(controller: c),
            Expanded(
              child: RefreshIndicator(
                onRefresh: c.reload,
                child: c.feedTeams.isEmpty
                    ? ListView(
                        children: [
                          _EmptyFeedPlaceholder(
                              sport: c.selectedSport.value),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: c.feedTeams.length,
                        itemBuilder: (context, index) {
                          final team = c.feedTeams[index];
                          return _OpponentCard(
                            team: team,
                            onChallenge: () =>
                                _confirmChallenge(context, c, team),
                          );
                        },
                      ),
              ),
            ),
          ],
        );
      }),
    );
  }

  void _confirmChallenge(
    BuildContext context,
    MatchUpController controller,
    TeamModel opponent,
  ) {
    final myTeam = controller.selectedTeam.value;
    if (myTeam == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChallengeSheet(
        myTeamName: myTeam.name,
        myTeamLogo: myTeam.logo,
        opponent: opponent,
        onConfirm: () {
          Navigator.pop(context);
          controller.sendChallenge(opponent);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// My-team selector banner
// ---------------------------------------------------------------------------

class _MyTeamSelector extends StatelessWidget {
  const _MyTeamSelector({required this.controller});

  final MatchUpController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final teams = controller.myTeamsForSport;
      final selected = controller.selectedTeam.value;
      if (selected == null) return const SizedBox.shrink();

      final hasMultiple = teams.length > 1;

      return Container(
        color: const Color(AppColors.backgroundColor),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
        child: GestureDetector(
          onTap: hasMultiple ? () => _showTeamPicker(context, teams) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(AppColors.primaryColor),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(AppColors.primaryColor)
                      .withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  child: selected.logo.isEmpty
                      ? const Icon(Icons.shield_outlined,
                          size: 16, color: Colors.white)
                      : ClipOval(
                          child: Image.network(
                            selected.logo,
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.shield_outlined,
                                size: 16,
                                color: Colors.white),
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Your Team',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.7),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        selected.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (hasMultiple)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.swap_horiz,
                            size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Switch',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  void _showTeamPicker(
    BuildContext context,
    List<TeamMemberFieldInstance> teams,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
            const SizedBox(height: 20),
            const Text(
              'Select your team',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(AppColors.textColor),
              ),
            ),
            const SizedBox(height: 16),
            ...teams.map((team) {
              final isSelected = team.id == controller.selectedTeam.value?.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: isSelected
                      ? const Color(AppColors.primaryColor)
                          .withValues(alpha: 0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      controller.selectTeam(team);
                      Navigator.pop(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          TeamLogo(url: team.logo, size: 40),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              team.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: const Color(AppColors.textColor),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle,
                                size: 22,
                                color: Color(AppColors.primaryColor)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Opponent card — responsive layout
// ---------------------------------------------------------------------------

class _OpponentCard extends StatelessWidget {
  const _OpponentCard({required this.team, required this.onChallenge});

  final TeamModel team;
  final VoidCallback onChallenge;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(AppColors.dividerColor).withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          final id = team.id;
          if (id != null && id.isNotEmpty) {
            Get.toNamed(
              AppConstants.routes.teamProfile,
              arguments: {'teamId': id},
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  TeamLogo(url: team.logo, size: 48, teamId: team.id),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          team.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(AppColors.textColor),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (team.location != null) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 13,
                                  color:
                                      Color(AppColors.textSecondaryColor)),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  team.location!.address,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color:
                                        Color(AppColors.textSecondaryColor),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TeamStatsRow(team: team)),
                  const SizedBox(width: 12),
                  _ChallengeButton(onTap: onChallenge),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChallengeButton extends StatelessWidget {
  const _ChallengeButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(AppColors.primaryColor),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sports_mma, size: 16, color: Colors.white),
              SizedBox(width: 6),
              Text(
                'Challenge',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Challenge confirmation bottom sheet
// ---------------------------------------------------------------------------

class _ChallengeSheet extends StatelessWidget {
  const _ChallengeSheet({
    required this.myTeamName,
    required this.myTeamLogo,
    required this.opponent,
    required this.onConfirm,
  });

  final String myTeamName;
  final String myTeamLogo;
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TeamLogo(url: myTeamLogo, size: 56),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'VS',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: const Color(AppColors.primaryColor)
                        .withValues(alpha: 0.7),
                  ),
                ),
              ),
              TeamLogo(url: opponent.logo, size: 56),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '$myTeamName  vs  ${opponent.name}',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(AppColors.textColor),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Send a friendly match request?\nThey\'ll have 2 hours to respond.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(AppColors.textSecondaryColor),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
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
                        color: Color(AppColors.dividerColor)),
                  ),
                  child: const Text('Cancel',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(AppColors.textSecondaryColor))),
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
                      Text('Send Challenge',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
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

// ---------------------------------------------------------------------------
// Placeholders
// ---------------------------------------------------------------------------

class _NoTeamPlaceholder extends StatelessWidget {
  const _NoTeamPlaceholder({required this.sport});

  final TeamSportType sport;

  @override
  Widget build(BuildContext context) {
    final label = sport == TeamSportType.cricket ? 'cricket' : 'football';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No $label team yet',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(AppColors.textColor),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Join or create a $label team to find opponents and challenge them.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(AppColors.textSecondaryColor),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Get.toNamed(AppConstants.routes.addTeam),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create Team'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(AppColors.primaryColor),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFeedPlaceholder extends StatelessWidget {
  const _EmptyFeedPlaceholder({required this.sport});

  final TeamSportType sport;

  @override
  Widget build(BuildContext context) {
    final label = sport == TeamSportType.cricket ? 'cricket' : 'football';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'No opponents found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(AppColors.textColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No $label teams are open for matches right now.\nCheck back later!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(AppColors.textSecondaryColor),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
