import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../components/match_up/match_pick_versus_row.dart';
import '../../components/match_up/my_team_selector.dart';
import '../../components/match_up/team_logo.dart';
import '../../components/shared/app_search_field.dart';
import '../../core/components/app_bar/app_bar_background.dart';
import '../../core/config/constants.dart';
import '../../core/models/paginated_response.dart';
import '../../core/query/query_keys.dart';
import '../../core/query/query_retry.dart';
import '../../core/utils/app_snackbar.dart';
import '../../team/members/model/team_member_model.dart';
import '../../team/model/team_model.dart';
import '../../team/team_service.dart';
import '../../team/utils/team_ui.dart';
import '../matchmaking_service.dart';
import '../model/team_match_model.dart';
import 'match_start_controller.dart';

class MatchStartScreen extends HookWidget {
  const MatchStartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MatchStartController>();
    final sport = controller.sport;
    final ranked = controller.isRanked;

    if (!controller.isSportSupported) {
      return Scaffold(
        backgroundColor: const Color(AppColors.backgroundColor),
        appBar: AppAppBar(title: Text(controller.screenTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '${controller.modeLabel} matches are not available for this sport yet.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(AppColors.textSecondaryColor),
              ),
            ),
          ),
        ),
      );
    }

    final selectedTeam = useState<TeamMemberFieldInstance?>(null);
    final selectedOpponent = useState<TeamModel?>(null);
    final creating = useState(false);

    final membershipsQuery = useQuery<List<TeamMemberModel>, Object>(
      QueryKeys.myMemberships,
      (_) async {
        final result = await TeamService().memberService.myMemberships(
          const MyTeamMembershipsFilterQuery(
            status: TeamMemberStatus.active,
            limit: 50,
          ),
        );
        return result?.data ?? const <TeamMemberModel>[];
      },
      retry: noRetry,
    );

    final mySportTeams = useMemoized(() {
      final list = <TeamMemberFieldInstance>[];
      for (final m in membershipsQuery.data ?? const <TeamMemberModel>[]) {
        final t = m.team;
        if (t is TeamMemberFieldInstance &&
            t.sportType == sport &&
            t.id != null &&
            t.id!.isNotEmpty) {
          list.add(t);
        }
      }
      return list;
    }, [membershipsQuery.data, sport]);

    useEffect(() {
      final current = selectedTeam.value;
      if (current != null && mySportTeams.any((t) => t.id == current.id)) {
        return null;
      }
      selectedTeam.value = mySportTeams.isEmpty ? null : mySportTeams.first;
      return null;
    }, [mySportTeams]);

    useEffect(() {
      final opponent = selectedOpponent.value;
      final fromId = selectedTeam.value?.id;
      if (opponent != null && opponent.id != null && opponent.id == fromId) {
        selectedOpponent.value = null;
      }
      return null;
    }, [selectedTeam.value?.id]);

    Future<void> pickOpponent() async {
      final fromId = selectedTeam.value?.id;
      if (fromId == null || fromId.isEmpty) return;

      final picked = await showOpponentPickerSheet(
        context: context,
        fromTeamId: fromId,
        sport: sport,
        openForMatch: ranked,
      );
      if (picked != null) {
        selectedOpponent.value = picked;
      }
    }

    Future<void> startMatch() async {
      final fromId = selectedTeam.value?.id;
      final opponent = selectedOpponent.value;
      final toId = opponent?.id;
      if (fromId == null || fromId.isEmpty || toId == null || toId.isEmpty) {
        return;
      }
      if (creating.value) return;

      final opponentIsAlsoMine = mySportTeams.any((t) => t.id == toId);

      creating.value = true;
      try {
        final match = ranked
            ? await MatchmakingService().sendRequest(
                SendMatchRequest(fromTeamId: fromId, toTeamId: toId),
              )
            : await MatchmakingService().createUnrankedMatch(
                CreateUnrankedMatchRequest(fromTeamId: fromId, toTeamId: toId),
              );
        final matchId = match?.id;
        if (matchId == null || matchId.isEmpty) return;
        if (ranked || !opponentIsAlsoMine) {
          AppSnackbar.success(
            title: ranked ? 'Challenge sent' : 'Request sent',
            message: 'Waiting for the other team to accept.',
          );
        }
        await Get.offNamed(
          AppConstants.routes.matchChallengeDetail(matchId),
          arguments: {'isIncoming': false},
        );
      } catch (e) {
        AppSnackbar.error(
          title: ranked
              ? 'Could not send challenge'
              : opponentIsAlsoMine
              ? 'Could not start match'
              : 'Could not send request',
          message: e.toString(),
        );
      } finally {
        creating.value = false;
      }
    }

    final membershipsLoading =
        membershipsQuery.isLoading ||
        (membershipsQuery.isFetching && membershipsQuery.data == null);
    final canStart =
        selectedTeam.value?.id != null &&
        selectedOpponent.value?.id != null &&
        !creating.value;

    final myTeam = selectedTeam.value;
    final opponent = selectedOpponent.value;
    final pickerTeams = mySportTeams
        .where((t) => t.id != opponent?.id)
        .toList();
    final opponentIsAlsoMine =
        opponent?.id != null && mySportTeams.any((t) => t.id == opponent!.id);
    final primaryLabel = ranked
        ? 'Send challenge'
        : (opponentIsAlsoMine ? 'Start' : 'Send request');
    final sportLabel = controller.sportLabel;
    final screenTitle = controller.screenTitle;

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppAppBar(title: Text(screenTitle)),
      body: membershipsLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color(AppColors.primaryColor),
                ),
              ),
            )
          : mySportTeams.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(sport.icon, size: 56, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      ranked
                          ? 'Join or create a $sportLabel team first. Only captains and owners can send a ranked challenge.'
                          : 'Join or create a $sportLabel team first. Only captains and owners can start an unranked match.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(AppColors.textSecondaryColor),
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => Get.toNamed(AppConstants.routes.myTeams),
                      child: const Text('My teams'),
                    ),
                  ],
                ),
              ),
            )
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Column(
                  children: [
                    const Spacer(),
                    MatchPickVersusRow(
                      left: MatchPickVersusTeam(
                        name: myTeam?.name ?? 'Your team',
                        logoUrl: myTeam?.logo ?? '',
                        showEditBadge: pickerTeams.length > 1,
                        wrapLogo: (logo) => MyTeamSelector(
                          teams: pickerTeams,
                          selectedTeam: myTeam,
                          sheetTitle: 'Select your $sportLabel team',
                          onTeamSelected: (team) => selectedTeam.value = team,
                          buttonChild: logo,
                        ),
                      ),
                      right: MatchPickVersusTeam(
                        name: opponent?.name ?? 'Select opponent',
                        logoUrl: opponent?.logo ?? '',
                        placeholder: opponent == null,
                        showEditBadge: true,
                        onTap: pickOpponent,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: canStart ? startMatch : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(AppColors.primaryColor),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(
                            AppColors.dividerColor,
                          ),
                          disabledForegroundColor: const Color(
                            AppColors.textSecondaryColor,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: creating.value
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                primaryLabel,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

Future<TeamModel?> showOpponentPickerSheet({
  required BuildContext context,
  required String fromTeamId,
  required TeamSportType sport,
  bool openForMatch = false,
}) {
  return showModalBottomSheet<TeamModel>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _OpponentPickerSheet(
      fromTeamId: fromTeamId,
      sport: sport,
      openForMatch: openForMatch,
    ),
  );
}

class _OpponentPickerSheet extends HookWidget {
  const _OpponentPickerSheet({
    required this.fromTeamId,
    required this.sport,
    required this.openForMatch,
  });

  final String fromTeamId;
  final TeamSportType sport;
  final bool openForMatch;

  @override
  Widget build(BuildContext context) {
    final searchController = useTextEditingController();
    final searchText = useState('');
    final debouncedSearch = useState('');

    useEffect(() {
      void listener() => searchText.value = searchController.text;
      searchController.addListener(listener);
      return () => searchController.removeListener(listener);
    }, [searchController]);

    useEffect(() {
      final timer = Timer(const Duration(milliseconds: 400), () {
        debouncedSearch.value = searchText.value.trim();
      });
      return timer.cancel;
    }, [searchText.value]);

    final query = debouncedSearch.value;
    final sportLabel = sport.label.toLowerCase();

    final opponentsQuery =
        useInfiniteQuery<PaginatedResponse<TeamModel>, Object, int>(
          QueryKeys.unrankedOpponentSearch(
            fromTeamId: fromTeamId,
            query: query,
            sportType: sport.name,
            openForMatch: openForMatch,
          ),
          (ctx) async {
            final result = await TeamService().findMany(
              TeamFilterQuery(
                status: TeamStatus.active,
                sportType: sport,
                search: query.isEmpty ? null : query,
                teamOpenForMatch: openForMatch ? true : null,
                skipTeamsWithSentRequest: openForMatch ? true : null,
                fromTeamId: openForMatch ? fromTeamId : null,
                page: ctx.pageParam,
                limit: 20,
              ),
            );
            return result ?? EmptyPaginatedResponse<TeamModel>();
          },
          initialPageParam: 1,
          retry: noRetry,
          nextPageParamBuilder: (data) {
            final last = data.pages.isNotEmpty ? data.pages.last : null;
            if (last == null || !last.hasNextPage) return null;
            return last.page + 1;
          },
        );

    final opponents =
        opponentsQuery.data?.pages
            .expand((p) => p.data)
            .where((t) => t.id != null && t.id != fromTeamId)
            .toList() ??
        const <TeamModel>[];

    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return Container(
      height: maxHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Select opponent',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(AppColors.textColor),
            ),
          ),
          const SizedBox(height: 14),
          AppSearchField(
            controller: searchController,
            hintText: 'Search $sportLabel teams',
          ),
          const SizedBox(height: 12),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification.metrics.pixels >=
                    notification.metrics.maxScrollExtent - 160) {
                  if (opponentsQuery.hasNextPage &&
                      !opponentsQuery.isFetchingNextPage) {
                    opponentsQuery.fetchNextPage();
                  }
                }
                return false;
              },
              child: _OpponentList(
                query: opponentsQuery,
                items: opponents,
                sportLabel: sportLabel,
                openForMatch: openForMatch,
                onPick: (team) => Navigator.pop(context, team),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OpponentList extends StatelessWidget {
  const _OpponentList({
    required this.query,
    required this.items,
    required this.sportLabel,
    required this.openForMatch,
    required this.onPick,
  });

  final InfiniteQueryResult<PaginatedResponse<TeamModel>, Object, int> query;
  final List<TeamModel> items;
  final String sportLabel;
  final bool openForMatch;
  final ValueChanged<TeamModel> onPick;

  @override
  Widget build(BuildContext context) {
    if (query.isLoading || (query.isFetching && items.isEmpty)) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Color(AppColors.primaryColor),
          ),
        ),
      );
    }

    if (query.isError && items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Could not load teams.',
              style: TextStyle(color: Color(AppColors.textSecondaryColor)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => query.refetch(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            openForMatch
                ? 'No open $sportLabel teams found. The other team must be open for matches.'
                : 'No $sportLabel teams found. Try another search.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(AppColors.textSecondaryColor)),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewPadding.bottom + 8,
      ),
      itemCount: items.length + (query.isFetchingNextPage ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index >= items.length) {
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
        final team = items[index];
        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onPick(team),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                children: [
                  TeamLogo(url: team.logo, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          team.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Color(AppColors.textColor),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            teamSportLabel(team.sportType),
                            if (team.location?.shortPlaceLabel case final place?
                                when place.isNotEmpty)
                              place,
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(AppColors.textSecondaryColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(AppColors.textSecondaryColor),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
