import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../match_up/team_logo.dart';
import '../shared/app_search_field.dart';
import '../../core/config/constants.dart';
import '../../core/models/paginated_response.dart';
import '../../core/query/query_keys.dart';
import '../../core/query/query_retry.dart';
import '../../team/model/team_model.dart';
import '../../team/team_service.dart';
import '../../tournament/model/tournament_models.dart';
import '../../tournament/detail/tournament_detail_controller.dart';

Future<void> showTournamentInviteTeamSheet(
  BuildContext context, {
  required TournamentDetailController controller,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) {
      final sheetHeight = MediaQuery.sizeOf(context).height * 0.8;
      return SizedBox(
        height: sheetHeight,
        child: _TournamentInviteTeamSheetBody(controller: controller),
      );
    },
  );
}

class _TournamentInviteTeamSheetBody extends HookWidget {
  const _TournamentInviteTeamSheetBody({required this.controller});

  final TournamentDetailController controller;

  @override
  Widget build(BuildContext context) {
    final searchController = useTextEditingController();
    final searchText = useState('');
    final debouncedSearch = useState('');
    final sentTeamIds = useState<Set<String>>(<String>{});
    final sendingTeamIds = useState<Set<String>>(<String>{});

    useEffect(() {
      final timer = Timer(const Duration(milliseconds: 400), () {
        debouncedSearch.value = searchText.value.trim();
      });
      return timer.cancel;
    }, [searchText.value]);

    final sport = controller.tournament.value?.sportType ?? 'cricket';
    final sportType = sport == 'football'
        ? TeamSportType.football
        : TeamSportType.cricket;
    final queryTerm = debouncedSearch.value;

    final teamsQuery =
        useInfiniteQuery<PaginatedResponse<TeamModel>, Object, int>(
      QueryKeys.tournamentInviteTeams(
        sportType: sportType.name,
        search: queryTerm.isNotEmpty ? queryTerm : null,
      ),
      (ctx) async {
        final page = await TeamService().findMany(
          TeamFilterQuery(
            sportType: sportType,
            status: TeamStatus.active,
            search: queryTerm.isNotEmpty ? queryTerm : null,
            page: ctx.pageParam,
            limit: 20,
          ),
        );
        return page ?? EmptyPaginatedResponse<TeamModel>();
      },
      initialPageParam: 1,
      retry: noRetry,
      nextPageParamBuilder: (data) {
        final last = data.pages.isNotEmpty ? data.pages.last : null;
        if (last == null || !last.hasNextPage) return null;
        return last.page + 1;
      },
    );

    final results =
        teamsQuery.data?.pages.expand((p) => p.data).toList() ??
        const <TeamModel>[];
    final searching = teamsQuery.isLoading ||
        (teamsQuery.isFetching && results.isEmpty);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'Invite a team',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: AppSearchField(
              controller: searchController,
              hintText: 'Search by team name',
              onChanged: (value) => searchText.value = value,
              onCleared: () {
                searchText.value = '';
                debouncedSearch.value = '';
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification.metrics.pixels >=
                    notification.metrics.maxScrollExtent - 160) {
                  if (teamsQuery.hasNextPage &&
                      !teamsQuery.isFetchingNextPage) {
                    teamsQuery.fetchNextPage();
                  }
                }
                return false;
              },
              child: Obx(() {
                final tournamentEntries = controller.invitations.toList();
                return _resultsBody(
                  controller: controller,
                  tournamentEntries: tournamentEntries,
                  results: results,
                  searching: searching,
                  queryTerm: queryTerm,
                  isFetchingNextPage: teamsQuery.isFetchingNextPage,
                  sentTeamIds: sentTeamIds.value,
                  sendingTeamIds: sendingTeamIds.value,
                  onInvite: (teamId) async {
                    sendingTeamIds.value = {...sendingTeamIds.value, teamId};
                    final ok = await controller.invite(teamId);
                    sendingTeamIds.value = {...sendingTeamIds.value}
                      ..remove(teamId);
                    if (!ok) return;
                    sentTeamIds.value = {...sentTeamIds.value, teamId};
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _resultsBody({
  required List<TournamentEntryModel> tournamentEntries,
  required List<TeamModel> results,
  required bool searching,
  required String queryTerm,
  required bool isFetchingNextPage,
  required TournamentDetailController controller,
  required Set<String> sentTeamIds,
  required Set<String> sendingTeamIds,
  required Future<void> Function(String teamId) onInvite,
}) {
  if (searching) {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(
          Color(AppColors.primaryColor),
        ),
      ),
    );
  }
  if (results.isEmpty) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          queryTerm.isEmpty
              ? 'No teams available to invite.'
              : 'No teams found. Try another name.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
  return ListView.builder(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
    itemCount: results.length + (isFetchingNextPage ? 1 : 0),
    itemBuilder: (context, index) {
      if (index >= results.length) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      }
      final team = results[index];
      final id = team.id;
      final sending = id != null && sendingTeamIds.contains(id);
      final chipLabel = id == null
          ? null
          : controller.inviteSheetChipLabel(
                id,
                from: tournamentEntries,
              ) ??
              (sentTeamIds.contains(id) ? 'Sent' : null);
      final blocked = chipLabel != null || sending;
      final subtitle = _teamLocationSubtitle(team);
      return Card(
        child: ListTile(
          leading: TeamLogo(
            url: team.logo,
            size: 48,
            teamId: id,
          ),
          title: Text(team.name),
          subtitle: subtitle,
          trailing: sending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : chipLabel != null
                  ? _InviteSheetStatusChip(label: chipLabel)
                  : null,
          enabled: id != null && !blocked,
          onTap: id == null || blocked ? null : () => onInvite(id),
        ),
      );
    },
  );
}

Widget? _teamLocationSubtitle(TeamModel team) {
  final place = team.location?.shortPlaceLabel?.trim();
  if (place == null || place.isEmpty) return null;
  return Text(
    place,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
  );
}

class _InviteSheetStatusChip extends StatelessWidget {
  const _InviteSheetStatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final joined = label == 'Joined';
    final bg = joined
        ? const Color(0xFFD1FAE5)
        : const Color(0xFFE0E7FF);
    final fg = joined
        ? const Color(0xFF047857)
        : const Color(AppColors.primaryColor);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
          height: 1.1,
        ),
      ),
    );
  }
}
