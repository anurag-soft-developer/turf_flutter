import 'package:flutter/material.dart';

import '../../core/components/search/app_search_screen.dart';
import '../../core/services/search/search_history_store.dart';
import 'my_teams_memberships_body.dart';

class MyTeamsSearchScreen extends StatelessWidget {
  const MyTeamsSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSearchScreen(
      historyScope: SearchHistoryScope.myTeams,
      hintText: 'Search by team name',
      resultsBuilder: (context, query) => MyTeamsMembershipsBody(
        key: ValueKey('my-teams-search|$query'),
        search: query,
        bottomPadding: 24,
      ),
    );
  }
}
