import 'package:flutter/material.dart';
import 'package:flutter_application_1/components/match_up/my_team_selector.dart';
import 'package:get/get.dart';

import '../../components/match_history/match_history_placeholders.dart';
import '../../components/match_history/match_history_tabs.dart';
import '../../core/config/constants.dart';
import 'match_history_controller.dart';

class MatchHistoryScreen extends StatelessWidget {
  const MatchHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final MatchHistoryController c = Get.find();

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(title: const Text('Match History')),
      body: Obx(() {
        if (c.isLoadingTeams.value) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Color(AppColors.primaryColor),
              ),
            ),
          );
        }

        if (c.allTeams.isEmpty) {
          return const NoTeamsPlaceholder();
        }

        return Column(
          children: [
            MyTeamSelector(
              selectedTeam: c.selectedTeam.value,
              teams: c.allTeams,
              onTeamSelected: (team) => c.selectTeam(team),
            ),
            Expanded(child: MatchHistoryTabs(controller: c)),
          ],
        );
      }),
    );
  }
}
