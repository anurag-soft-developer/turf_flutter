import 'package:flutter/material.dart';
import 'package:flutter_application_1/components/shared/app_drawer.dart';
import 'package:get/get.dart';

import '../components/match_up/my_team_selector.dart';
import '../components/shared/app_segmented_tabs/app_segmented_tabs.dart';
import '../components/match_up/team_logo.dart';
import '../components/match_up/team_stats_row.dart';
import '../core/config/constants.dart';
import '../team/members/model/team_member_model.dart';
import '../team/model/team_model.dart';
import 'match_up_controller.dart';

class MatchUpScreen extends StatefulWidget {
  const MatchUpScreen({super.key});

  @override
  State<MatchUpScreen> createState() => _MatchUpScreenState();
}

class _MatchUpScreenState extends State<MatchUpScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    final c = Get.find<MatchUpController>();
    final sports = TeamSportType.values;
    final selected = sports.indexOf(c.selectedSport.value);
    _tabController = TabController(
      length: sports.length,
      vsync: this,
      initialIndex: selected < 0 ? 0 : selected,
    );
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      final idx = _tabController.index;
      if (idx >= 0 && idx < sports.length) {
        c.switchSport(sports[idx]);
      }
    });
    c.ensureSportFeedLoaded(c.selectedSport.value);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MatchUpController c = Get.find();
    return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: const Text('Match Up'),
        actions: [
          IconButton(
            tooltip: 'Challenges',
            icon: const Icon(Icons.inbox_outlined),
            onPressed: () => Get.toNamed(AppConstants.routes.matchUpChallenges),
          ),
        ],
      ),
      body: Obx(() {
        final sports = TeamSportType.values;
        final currentIndex = sports.indexOf(c.selectedSport.value);
        final safeIndex = currentIndex < 0 ? 0 : currentIndex;

        if (_tabController.index != safeIndex) {
          _tabController.animateTo(safeIndex);
        }

        if (c.isLoadingMyTeams.value) {
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
            AppSegmentedTabs(
              controller: _tabController,
              onTap: (index) => c.switchSport(sports[index]),
              items: sports
                  .map(
                    (sport) => AppTabItem(
                      label: sport == TeamSportType.cricket
                          ? 'Cricket'
                          : 'Football',
                      icon: sport == TeamSportType.cricket
                          ? Icons.sports_cricket
                          : Icons.sports_soccer,
                    ),
                  )
                  .toList(),
            ),
            Expanded(
              child: AppSegmentedTabView(
                controller: _tabController,
                children: List.generate(sports.length, (index) {
                  final sport = sports[index];
                  final teamsForSport = _teamsForSport(c.myMemberships, sport);
                  final feedState = c.feedStateForSport(sport);

                  return _SportFeedSection(
                    sport: sport,
                    hasTeams: teamsForSport.isNotEmpty,
                    feedState: feedState,
                    onRefresh: () => c.reloadSport(sport),
                    onChallenge: (team) => _confirmChallenge(context, c, team),
                  );
                }),
              ),
            ),
          ],
        );
      }),
    );
  }

  List<TeamMemberFieldInstance> _teamsForSport(
    List<TeamMemberModel> memberships,
    TeamSportType sport,
  ) {
    final teams = <TeamMemberFieldInstance>[];
    for (final membership in memberships) {
      final team = membership.team;
      if (team is TeamMemberFieldInstance && team.sportType == sport) {
        teams.add(team);
      }
    }
    return teams;
  }

  void _confirmChallenge(
    BuildContext context,
    MatchUpController controller,
    TeamModel opponent,
  ) {
    final myTeam = controller.selectedTeam.value;
    if (myTeam == null) return;
    final teamsForSport = _teamsForSport(
      controller.myMemberships,
      controller.selectedSport.value,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChallengeSheet(
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
}

class _SportFeedSection extends StatelessWidget {
  const _SportFeedSection({
    required this.sport,
    required this.hasTeams,
    required this.feedState,
    required this.onRefresh,
    required this.onChallenge,
  });

  final TeamSportType sport;
  final bool hasTeams;
  final SegmentedTabDataState<TeamModel> feedState;
  final Future<void> Function() onRefresh;
  final ValueChanged<TeamModel> onChallenge;

  @override
  Widget build(BuildContext context) {
    if (!hasTeams) {
      return _NoTeamPlaceholder(sport: sport);
    }

    final isFirstLoad = !feedState.hasInitialized && feedState.items.isEmpty;
    if (isFirstLoad || (feedState.isFetching && feedState.items.isEmpty)) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Color(AppColors.primaryColor),
          ),
        ),
      );
    }

    if (feedState.error != null && feedState.items.isEmpty) {
      return _FeedErrorPlaceholder(
        sport: sport,
        message: feedState.error!,
        onRetry: onRefresh,
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: feedState.items.isEmpty
          ? ListView(children: [_EmptyFeedPlaceholder(sport: sport)])
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: feedState.items.length,
              itemBuilder: (context, index) {
                final team = feedState.items[index];
                return _OpponentCard(
                  team: team,
                  onChallenge: () => onChallenge(team),
                );
              },
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
                              const Icon(
                                Icons.location_on_outlined,
                                size: 13,
                                color: Color(AppColors.textSecondaryColor),
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  team.location!.address,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(AppColors.textSecondaryColor),
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
    required this.controller,
    required this.teamsForSport,
    required this.opponent,
    required this.onConfirm,
  });

  final MatchUpController controller;
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
            final double logoSize = 75;
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
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
          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
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

class _FeedErrorPlaceholder extends StatelessWidget {
  const _FeedErrorPlaceholder({
    required this.sport,
    required this.message,
    required this.onRetry,
  });

  final TeamSportType sport;
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final label = sport == TeamSportType.cricket ? 'cricket' : 'football';
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'Could not load $label teams',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(AppColors.textColor),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(AppColors.textSecondaryColor),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => onRetry(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(AppColors.primaryColor),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
