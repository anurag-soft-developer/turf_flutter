import 'package:flutter/material.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../components/shared/app_segmented_tabs/app_segmented_tabs.dart';
import '../../components/tournaments/tournament_list_card.dart';
import '../../components/tournaments/tournament_list_sub_filters.dart';
import '../../core/config/constants.dart';
import '../../core/query/query_keys.dart';
import '../../team/model/team_model.dart';
import '../model/tournament_models.dart';
import '../tournament_service.dart';
import 'tournament_infinite_query_pane.dart';
import 'tournament_list_controller.dart';
import 'tournament_list_scaffold.dart';

class TournamentListScreen extends StatelessWidget {
  const TournamentListScreen({super.key});

  static const _tabs = [
    AppTabItem(label: 'All'),
    AppTabItem(label: 'Live'),
    AppTabItem(label: 'Upcoming'),
    AppTabItem(label: 'Others'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = Get.find<TournamentListController>();

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Get.toNamed(AppConstants.routes.createTournament);
          if (Get.isRegistered<QueryClient>()) {
            await Get.find<QueryClient>().invalidateQueries(
              queryKey: QueryKeys.tournamentsMinePrefix,
            );
          }
        },
        backgroundColor: const Color(AppColors.primaryColor),
        icon: const Icon(Icons.add),
        label: const Text('Create'),
      ),
      body: TournamentListScaffold(
        title: 'Tournaments',
        controller: c,
        tabs: _tabs,
        initialTabIndex: c.selectedTab.value.index,
        onTabChanged: c.switchTab,
        belowTabs: const TournamentListSubFilters(),
        buildPanes: (sportKey) {
          final sport = c.sportFilter.value;
          return [
            for (final tab in TournamentListTab.values)
              _TournamentListPane(
                key: ValueKey('${tab.name}|$sportKey'),
                tab: tab,
                sportFilter: sport,
              ),
          ];
        },
      ),
    );
  }
}

class _TournamentListPane extends StatelessWidget {
  const _TournamentListPane({
    super.key,
    required this.tab,
    required this.sportFilter,
  });

  final TournamentListTab tab;
  final TeamSportType? sportFilter;

  @override
  Widget build(BuildContext context) {
    return TournamentInfiniteQueryPane(
      queryKey: QueryKeys.tournamentsMine(
        tab: tab.name,
        sportType: sportFilter?.name,
      ),
      fetchPage: (page) async {
        final result = await TournamentService().listMine(
          page: page,
          sportType: sportFilter?.name,
          status: tab.apiStatuses,
        );
        return result ??
            TournamentPage(items: const [], total: 0, page: page);
      },
      empty: _TournamentEmptyPlaceholder(
        title: tab.emptyTitle,
        subtitle: tab.emptySubtitle,
      ),
      itemBuilder: (item, _, __) => TournamentListCard(
        tournament: item,
        onTap: () => Get.toNamed(AppConstants.routes.tournamentDetail(item.id)),
      ),
    );
  }
}

class _TournamentEmptyPlaceholder extends StatelessWidget {
  const _TournamentEmptyPlaceholder({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 48,
              color: const Color(AppColors.primaryColor).withValues(alpha: 0.35),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(AppColors.textColor),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(AppColors.textSecondaryColor),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
