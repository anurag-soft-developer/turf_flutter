import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../components/challenges/match_challenge_respond_actions.dart';
import '../../components/match_history/match_card.dart'
    show MatchCard, MatchChallengeInboxKind;
import '../../components/shared/app_segmented_tabs/app_segmented_tabs.dart';
import '../../core/config/constants.dart';
import '../../core/models/paginated_response.dart';
import '../../core/query/query_keys.dart';
import '../matchmaking_service.dart';
import '../model/team_match_model.dart';
import '../shared/match_infinite_query_pane.dart';
import '../shared/match_list_scaffold.dart';
import 'match_challenge_detail_screen.dart';
import 'match_challenges_controller.dart';

class MatchChallengesScreen extends StatelessWidget {
  const MatchChallengesScreen({super.key});

  static const _tabs = [
    AppTabItem(label: 'Received'),
    AppTabItem(label: 'Sent'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = Get.find<MatchChallengesController>();

    return MatchListScaffold(
      title: 'Challenges',
      teamSheetTitle: 'Show challenges for',
      emptyTeamsMessage:
          'Join or create a team to send and receive match challenges.',
      controller: c,
      tabs: _tabs,
      initialTabIndex: c.selectedTab.value.index,
      onTabChanged: c.switchTab,
      buildPanes: (filterKey) => [
        _ChallengeInboxPane(
          key: ValueKey('received|$filterKey'),
          tab: MatchChallengesTab.received,
          teamFilter: filterKey,
          emptyMessage: 'No challenges received yet.',
          itemBuilder: (m) => _ReceivedChallengeCard(match: m, controller: c),
        ),
        _ChallengeInboxPane(
          key: ValueKey('sent|$filterKey'),
          tab: MatchChallengesTab.sent,
          teamFilter: filterKey,
          emptyMessage: 'No challenges sent yet.',
          itemBuilder: (m) => _SentChallengeCard(match: m, controller: c),
        ),
      ],
    );
  }
}

Future<PaginatedResponse<TeamMatchModel>> _fetchInboxPage({
  required MatchChallengesTab tab,
  required List<String> teamIds,
  required int page,
}) async {
  if (teamIds.isEmpty) {
    return EmptyPaginatedResponse<TeamMatchModel>();
  }

  final inbox = await MatchmakingService().listInbox(
    ListPreMatchInboxFilterQuery(
      type: tab == MatchChallengesTab.received
          ? NegotiationListType.incoming
          : NegotiationListType.outgoing,
      teamIds: teamIds,
      page: page,
      limit: 20,
      sort: 'createdAt:desc',
    ),
  );
  return inbox ?? EmptyPaginatedResponse<TeamMatchModel>();
}

class _ChallengeInboxPane extends StatelessWidget {
  const _ChallengeInboxPane({
    super.key,
    required this.tab,
    required this.teamFilter,
    required this.emptyMessage,
    required this.itemBuilder,
  });

  final MatchChallengesTab tab;
  final String teamFilter;
  final String emptyMessage;
  final Widget Function(TeamMatchModel match) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<MatchChallengesController>();
    final teamIds = c.activeTeamIdsForList();

    return MatchInfiniteQueryPane(
      queryKey: QueryKeys.matchChallenges(
        tab: tab.name,
        teamFilter: teamFilter,
      ),
      fetchPage: (page) =>
          _fetchInboxPage(tab: tab, teamIds: teamIds, page: page),
      empty: Center(
        child: Text(
          emptyMessage,
          style: const TextStyle(
            color: Color(AppColors.textSecondaryColor),
            fontSize: 15,
          ),
        ),
      ),
      itemBuilder: (match, _, _) => itemBuilder(match),
    );
  }
}

class _ReceivedChallengeCard extends StatelessWidget {
  const _ReceivedChallengeCard({required this.match, required this.controller});

  final TeamMatchModel match;
  final MatchChallengesController controller;

  @override
  Widget build(BuildContext context) {
    final canRespond =
        match.status == TeamMatchStatus.requested &&
        !_matchShowsAsExpired(match);

    return MatchCard(
      match: match,
      isHistory: false,
      challengeInboxKind: MatchChallengeInboxKind.received,
      onTap: () async {
        await openMatchChallengeDetail(match: match, isIncoming: true);
      },
      footer: canRespond
          ? Obx(() {
              final id = match.id;
              final accepting =
                  id != null && controller.acceptingMatchId.value == id;
              final rejecting =
                  id != null && controller.rejectingMatchId.value == id;
              return MatchChallengeRespondActions(
                compact: true,
                isRejecting: rejecting,
                isAccepting: accepting,
                onReject: () => controller.rejectChallenge(match),
                onAccept: () => controller.acceptChallenge(match),
              );
            })
          : null,
    );
  }
}

class _SentChallengeCard extends StatelessWidget {
  const _SentChallengeCard({required this.match, required this.controller});

  final TeamMatchModel match;
  final MatchChallengesController controller;

  @override
  Widget build(BuildContext context) {
    return MatchCard(
      match: match,
      isHistory: false,
      challengeInboxKind: MatchChallengeInboxKind.sent,
      onTap: () async {
        await openMatchChallengeDetail(match: match, isIncoming: false);
      },
    );
  }
}

bool _matchShowsAsExpired(TeamMatchModel m) {
  if (m.status == TeamMatchStatus.expired) return true;
  final ex = m.expiresAt;
  if (ex == null) return false;
  if (!DateTime.now().isAfter(ex.toLocal())) return false;
  return switch (m.status) {
    TeamMatchStatus.requested => true,
    TeamMatchStatus.accepted => true,
    TeamMatchStatus.negotiating => true,
    _ => false,
  };
}
