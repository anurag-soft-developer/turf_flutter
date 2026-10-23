import 'package:get/get.dart';

import '../../core/auth/auth_state_controller.dart';
import '../../core/routes/route_query.dart';
import '../model/tournament_models.dart';
import '../tournament_service.dart';

class TournamentDetailController extends GetxController {
  final TournamentService _service = TournamentService();

  late final String tournamentId;
  final RxBool loading = true.obs;
  final Rxn<TournamentModel> tournament = Rxn<TournamentModel>();
  /// Accepted teams for the tournament screen.
  final RxList<TournamentEntryModel> entries = <TournamentEntryModel>[].obs;

  /// Full invitation list. Loaded only when Teams & invites is open.
  final RxList<TournamentEntryModel> invitations = <TournamentEntryModel>[].obs;
  bool _invitationsRequested = false;
  final RxList<TournamentFixtureModel> fixtures = <TournamentFixtureModel>[].obs;
  final Rxn<TournamentTableModel> table = Rxn<TournamentTableModel>();
  final RxList<TournamentTeamRef> actingTeams = <TournamentTeamRef>[].obs;

  bool get isOrganizer {
    final userId = Get.find<AuthStateController>().user?.id;
    return tournament.value?.isOrganizer(userId) ?? false;
  }

  Set<String> get actingTeamIds => actingTeams.map((team) => team.id).toSet();

  /// Teams the user leads in this tournament's sport.
  List<TournamentTeamRef> get eligibleActingTeams {
    final sport = tournament.value?.sportType ?? 'cricket';
    return actingTeams.where((team) => team.sportType == sport).toList();
  }

  int get acceptedCount =>
      entries.where((entry) => entry.status == 'accepted').length;

  List<TournamentEntryModel> get visibleEntries =>
      invitations.where((entry) => entry.status != 'declined').toList();

  /// Compact label for invite sheet: Sent / Joined (or Requested if team applied).
  String? inviteSheetChipLabel(
    String teamId, {
    Iterable<TournamentEntryModel>? from,
  }) {
    if (teamId.isEmpty) return null;
    for (final entry in from ?? invitations) {
      if (entry.teamId != teamId) continue;
      if (entry.status == 'accepted') return 'Joined';
      if (entry.status == 'pending') {
        return entry.direction == 'request' ? 'Requested' : 'Sent';
      }
    }
    return null;
  }

  bool get isRosterLocked => tournament.value?.rosterLockedAt != null;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    final fromArgs = args is Map ? args['tournamentId']?.toString() : null;
    tournamentId = routeParam('id') ?? fromArgs ?? '';
    load();
  }

  Future<void> load() async {
    if (tournamentId.isEmpty) {
      loading.value = false;
      return;
    }
    final block = tournament.value == null;
    if (block) loading.value = true;
    try {
      // Fixtures and the table sync results first, then the tournament is
      // read so a completed final shows up as completed.
      final listed = await Future.wait([
        _collectEntries(status: 'accepted'),
        _service.fixtures(tournamentId),
        _service.table(tournamentId),
        _service.actingTeams(),
      ]);
      final fresh = await _service.getOne(tournamentId);
      entries.assignAll(listed[0] as List<TournamentEntryModel>);
      fixtures.assignAll(listed[1] as List<TournamentFixtureModel>);
      table.value = listed[2] as TournamentTableModel?;
      actingTeams.assignAll(listed[3] as List<TournamentTeamRef>);
      tournament.value = fresh;
    } finally {
      loading.value = false;
    }
  }

  Future<bool> invite(String teamId) async {
    final ok = await _service.invite(tournamentId, teamId);
    if (ok) await _refreshRoster();
    return ok;
  }

  Future<bool> requestToJoin(String teamId) async {
    final ok = await _service.requestToJoin(tournamentId, teamId);
    if (ok) await _refreshRoster();
    return ok;
  }

  Future<bool> acceptInvite(String entryId) async {
    final ok = await _service.acceptInvite(tournamentId, entryId);
    if (ok) await _refreshRoster();
    return ok;
  }

  Future<bool> declineInvite(String entryId) async {
    final ok = await _service.declineInvite(tournamentId, entryId);
    if (ok) await _refreshRoster();
    return ok;
  }

  Future<bool> acceptRequest(String entryId) async {
    final ok = await _service.acceptRequest(tournamentId, entryId);
    if (ok) await _refreshRoster();
    return ok;
  }

  Future<bool> declineRequest(String entryId) async {
    final ok = await _service.declineRequest(tournamentId, entryId);
    if (ok) await _refreshRoster();
    return ok;
  }

  Future<bool> withdrawRequest(String entryId) async {
    final ok = await _service.withdrawRequest(tournamentId, entryId);
    if (ok) await _refreshRoster();
    return ok;
  }

  Future<bool> revokeInvite(String invitationId) async {
    final ok = await _service.revokeInvite(tournamentId, invitationId);
    if (ok) await _refreshRoster();
    return ok;
  }

  /// Invitation pages for Teams & invites. Not called from the tournament screen.
  Future<void> loadInvitations() async {
    _invitationsRequested = true;
    if (tournamentId.isEmpty) {
      invitations.clear();
      return;
    }
    invitations.assignAll(await _collectEntries());
  }

  bool isMyTeamEntry(TournamentEntryModel entry) =>
      actingTeamIds.contains(entry.teamId);

  Future<bool> lockRoster() async {
    final ok = await _service.lockRoster(tournamentId);
    if (ok) await load();
    return ok;
  }

  Future<bool> removeAcceptedTeam(String entryId) async {
    final ok = await _service.removeAcceptedTeam(tournamentId, entryId);
    if (ok) await _refreshRoster();
    return ok;
  }

  Future<bool> generateDraw() async {
    final ok = await _service.generateDraw(tournamentId);
    if (ok) await load();
    return ok;
  }

  Future<bool> cancel() async {
    final ok = await _service.cancel(tournamentId);
    if (ok) await load();
    return ok;
  }

  Future<bool> deleteTournament() async {
    return _service.deleteTournament(tournamentId);
  }

  bool get canDelete {
    final status = tournament.value?.status;
    return isOrganizer &&
        (status == 'draft' || status == 'inviting');
  }

  Future<bool> pickBracketWinner(String matchId, String teamId) async {
    final ok = await _service.pickBracketWinner(tournamentId, matchId, teamId);
    if (ok) await load();
    return ok;
  }

  Future<bool> addOrganizer(String userId) async {
    final ok = await _service.addOrganizer(tournamentId, userId);
    if (ok) await load();
    return ok;
  }

  Future<bool> removeOrganizer(String userId) async {
    final ok = await _service.removeOrganizer(tournamentId, userId);
    if (ok) await load();
    return ok;
  }

  Future<bool> pickQualifiers(String groupLabel, List<String> teamIds) async {
    final ok = await _service.pickQualifiers(tournamentId, groupLabel, teamIds);
    if (ok) await load();
    return ok;
  }

  Future<void> _refreshRoster() async {
    await load();
    if (_invitationsRequested) await loadInvitations();
  }

  Future<List<TournamentEntryModel>> _collectEntries({String? status}) async {
    final items = <TournamentEntryModel>[];
    var page = 1;
    while (page <= 20) {
      final result = await _service.entries(
        tournamentId,
        status: status,
        page: page,
        limit: 100,
      );
      items.addAll(result.data);
      if (!result.hasNextPage || result.data.isEmpty) break;
      page += 1;
    }
    return items;
  }

  Future<bool> updateFixtureTeams(
    String matchId, {
    String? fromTeamId,
    String? toTeamId,
  }) async {
    final ok = await _service.updateFixtureTeams(
      tournamentId,
      matchId,
      fromTeamId: fromTeamId,
      toTeamId: toTeamId,
    );
    if (ok) await load();
    return ok;
  }
}
