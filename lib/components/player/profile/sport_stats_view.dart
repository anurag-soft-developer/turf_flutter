import 'package:flutter/material.dart';

import '../../../core/config/constants.dart';
import '../../../core/models/user/player_stats_models.dart';
import 'stats_grid.dart';

class SportStatsView extends StatelessWidget {
  const SportStatsView({super.key, required this.sport, this.stats});

  final SportType sport;
  final PlayerSportEntry? stats;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (sport == SportType.football)
            _buildFootballStats()
          else if (sport == SportType.cricket)
            _buildCricketStats(),
        ],
      ),
    );
  }

  Widget _buildFootballStats() {
    final footballStats = stats?.footballStats ?? const FootballPlayerStats();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.trending_up,
              size: 20,
              color: const Color(AppColors.primaryColor),
            ),
            const SizedBox(width: 8),
            const Text(
              'Performance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(AppColors.textColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        StatsGrid(
          items: [
            StatItem(
              value: footballStats.matchesPlayed.toString(),
              label: 'Matches',
              icon: Icons.sports_soccer,
              color: const Color(AppColors.primaryColor),
            ),
            StatItem(
              value: footballStats.matchesWon.toString(),
              label: 'Wins',
              icon: Icons.emoji_events,
              color: const Color(AppColors.successColor),
            ),
            StatItem(
              value: footballStats.goalsScored.toString(),
              label: 'Goals',
              icon: Icons.sports_score,
              color: const Color(AppColors.accentColor),
            ),
            StatItem(
              value: footballStats.assists.toString(),
              label: 'Assists',
              icon: Icons.handshake,
              color: const Color(0xFF10B981),
            ),
            StatItem(
              value: footballStats.cleanSheets.toString(),
              label: 'Clean Sheets',
              icon: Icons.shield,
              color: const Color(AppColors.primaryColor),
            ),
            StatItem(
              value: footballStats.saves.toString(),
              label: 'Saves',
              icon: Icons.sports_handball,
              color: const Color(0xFF8B5CF6),
            ),
          ],
        ),

        const SizedBox(height: 24),

        Row(
          children: [
            Icon(
              Icons.policy,
              size: 20,
              color: const Color(AppColors.errorColor),
            ),
            const SizedBox(width: 8),
            const Text(
              'Discipline',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(AppColors.textColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        StatsGrid(
          items: [
            StatItem(
              value: footballStats.yellowCards.toString(),
              label: 'Yellow Cards',
              icon: Icons.rectangle,
              color: const Color(0xFFF59E0B),
            ),
            StatItem(
              value: footballStats.redCards.toString(),
              label: 'Red Cards',
              icon: Icons.rectangle,
              color: const Color(AppColors.errorColor),
            ),
            StatItem(
              value: footballStats.hatTricks.toString(),
              label: 'Hat Tricks',
              icon: Icons.military_tech,
              color: const Color(0xFFFF6B35),
            ),
            StatItem(
              value: footballStats.penaltiesScored.toString(),
              label: 'Penalties',
              icon: Icons.gps_fixed,
              color: const Color(AppColors.accentColor),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCricketStats() {
    final cricketStats = stats?.cricketStats ?? const CricketPlayerStats();
    final batting = cricketStats.batting;
    final bowling = cricketStats.bowling;
    final fielding = cricketStats.fielding;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Batting Stats
        Row(
          children: [
            Icon(
              Icons.sports_cricket,
              size: 20,
              color: const Color(AppColors.primaryColor),
            ),
            const SizedBox(width: 8),
            const Text(
              'Batting',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(AppColors.textColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        StatsGrid(
          items: [
            StatItem(
              value: batting.innings.toString(),
              label: 'Innings',
              icon: Icons.sports_cricket,
              color: const Color(AppColors.primaryColor),
            ),
            StatItem(
              value: batting.runsScored.toString(),
              label: 'Runs',
              icon: Icons.trending_up,
              color: const Color(AppColors.successColor),
            ),
            StatItem(
              value: batting.highestScore.toString(),
              label: 'High Score',
              icon: Icons.star,
              color: const Color(AppColors.accentColor),
            ),
            StatItem(
              value: batting.average.toStringAsFixed(1),
              label: 'Average',
              icon: Icons.analytics,
              color: const Color(0xFF10B981),
            ),
            StatItem(
              value: batting.fours.toString(),
              label: 'Fours',
              icon: Icons.looks_4,
              color: const Color(0xFF8B5CF6),
            ),
            StatItem(
              value: batting.sixes.toString(),
              label: 'Sixes',
              icon: Icons.looks_6,
              color: const Color(0xFFFF6B35),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Bowling Stats
        Row(
          children: [
            Icon(
              Icons.sports_tennis,
              size: 20,
              color: const Color(AppColors.accentColor),
            ),
            const SizedBox(width: 8),
            const Text(
              'Bowling',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(AppColors.textColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        StatsGrid(
          items: [
            StatItem(
              value: bowling.oversBowled.toString(),
              label: 'Overs',
              icon: Icons.sports_cricket,
              color: const Color(AppColors.primaryColor),
            ),
            StatItem(
              value: bowling.wicketsTaken.toString(),
              label: 'Wickets',
              icon: Icons.bolt,
              color: const Color(AppColors.errorColor),
            ),
            StatItem(
              value: bowling.runsConceded.toString(),
              label: 'Runs Given',
              icon: Icons.trending_down,
              color: const Color(0xFF6B7280),
            ),
            StatItem(
              value: bowling.economy.toStringAsFixed(1),
              label: 'Economy',
              icon: Icons.speed,
              color: const Color(AppColors.accentColor),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Fielding Stats
        Row(
          children: [
            Icon(
              Icons.pan_tool,
              size: 20,
              color: const Color(AppColors.successColor),
            ),
            const SizedBox(width: 8),
            const Text(
              'Fielding',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(AppColors.textColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        StatsGrid(
          items: [
            StatItem(
              value: fielding.catches.toString(),
              label: 'Catches',
              icon: Icons.pan_tool,
              color: const Color(AppColors.primaryColor),
            ),
            StatItem(
              value: fielding.runOuts.toString(),
              label: 'Run Outs',
              icon: Icons.directions_run,
              color: const Color(AppColors.successColor),
            ),
            StatItem(
              value: fielding.stumpings.toString(),
              label: 'Stumpings',
              icon: Icons.sports_kabaddi,
              color: const Color(AppColors.accentColor),
            ),
          ],
        ),
      ],
    );
  }
}
