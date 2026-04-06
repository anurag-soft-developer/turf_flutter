import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/config/constants.dart';
import '../model/team_model.dart';
import '../utils/team_ui.dart';
import 'teams_ranking_controller.dart';

class TeamsRankingScreen extends StatelessWidget {
  const TeamsRankingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TeamsRankingController controller = Get.find();

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(title: const Text('Team rankings')),
      body: Obx(() {
        if (controller.isLoading.value && controller.teams.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Color(AppColors.primaryColor),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.reload,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Ordered by default for now. Backend ranking will replace this order later.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(AppColors.textSecondaryColor),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              if (controller.teams.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Text(
                      'No public teams to show yet.',
                      style: TextStyle(
                        color: Color(AppColors.textSecondaryColor),
                      ),
                    ),
                  ),
                )
              else
                ...controller.teams.asMap().entries.map(
                  (e) => _RankRow(rank: e.key + 1, team: e.value),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.rank, required this.team});

  final int rank;
  final TeamModel team;

  @override
  Widget build(BuildContext context) {
    final id = team.id;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(
            AppColors.primaryColor,
          ).withValues(alpha: 0.12),
          child: Text(
            '#$rank',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(AppColors.primaryColor),
            ),
          ),
        ),
        title: Text(team.name),
        subtitle: Text(teamSportLabel(team.sportType)),
        trailing: const Icon(Icons.chevron_right),
        onTap: id == null || id.isEmpty
            ? null
            : () => Get.toNamed(
                AppConstants.routes.teamProfile,
                arguments: {'teamId': id},
              ),
      ),
    );
  }
}
