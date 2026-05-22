import 'package:flutter/material.dart';

import '../../../components/shared/app_segmented_tabs/app_segmented_tabs.dart';
import '../../../core/config/constants.dart';
import '../../../core/models/user_field_instance.dart';
import '../../../match_up/model/team_match_model.dart';
import '../model/football_match_event_model.dart';
import '../model/football_scoring_models.dart';
import '../util/football_scoring_helpers.dart';

class FootballScorecard extends StatelessWidget {
  const FootballScorecard({
    super.key,
    required this.match,
    required this.events,
    this.parentTabController,
    required this.isLoading,
    required this.onRetry,
  });

  final TeamMatchModel match;
  final List<FootballMatchEvent> events;
  final TabController? parentTabController;
  final bool isLoading;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final fs = match.footballState;
    final fromName = match.fromTeamHelper.getDisplayName();
    final toName = match.toTeamHelper.getDisplayName();

    Widget body;
    if (isLoading && fs == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (fs == null) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Scoring has not started yet.',
              style: TextStyle(color: Color(AppColors.textSecondaryColor)),
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Refresh')),
          ],
        ),
      );
    } else {
      body = ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(fromName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        '${fs.scoreTeamOne}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Color(AppColors.primaryColor),
                        ),
                      ),
                    ],
                  ),
                ),
                const Text('–', style: TextStyle(fontSize: 24)),
                Expanded(
                  child: Column(
                    children: [
                      Text(toName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        '${fs.scoreTeamTwo}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Color(AppColors.primaryColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (events.isEmpty)
            const Text(
              'No events recorded.',
              style: TextStyle(color: Color(AppColors.textSecondaryColor)),
            )
          else
            ...events.map((e) {
              final primary = UserFieldInstance(e.primaryUserId).getDisplayName();
              return ListTile(
                leading: Icon(eventKindIcon(e.kind)),
                title: Text('#${e.sequence} ${eventKindLabel(e.kind)}'),
                subtitle: primary.isNotEmpty && primary != 'Unknown'
                    ? Text(primary)
                    : null,
                trailing: Text(periodLabel(e.period)),
              );
            }),
        ],
      );
    }

    final parent = parentTabController;
    if (parent == null) return body;
    return ParentLinkedHorizontalSwipe(parentController: parent, child: body);
  }
}
