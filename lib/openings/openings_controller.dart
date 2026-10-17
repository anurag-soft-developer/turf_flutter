import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../core/auth/auth_state_controller.dart';
import '../core/query/query_keys.dart';
import '../core/utils/app_snackbar.dart';
import '../team/members/model/team_member_model.dart';
import '../team/team_service.dart';
import 'model/enrollment_model.dart';
import 'model/opening_model.dart';
import 'opening_service.dart';

void ensureOpeningsController() {
  if (!Get.isRegistered<OpeningsController>()) {
    Get.put(OpeningsController(), permanent: true);
  }
}

/// UI + enroll mutation state. List fetching is owned by flutter_query on the screen.
class OpeningsController extends GetxController {
  final TeamService _teamService = TeamService();
  final OpeningService _openingService = OpeningService();

  /// `null` = all sports (no sportType filter).
  final Rxn<TeamSportType> selectedSport = Rxn<TeamSportType>();

  /// `null` = teams and tournaments.
  final Rxn<OpeningType> selectedType = Rxn<OpeningType>();
  final enrollingIds = <String>[].obs;

  /// Teams and tournaments the signed-in user can post for.
  final RxList<OwnedOpening> owned = <OwnedOpening>[].obs;
  final RxBool ownedLoading = false.obs;
  final RxnString updatingTargetId = RxnString();

  int _ownedLoadGen = 0;

  String get openingsQuerySportKey => selectedSport.value?.name ?? 'all';

  List<OwnedOpening> get postableHosts => owned.toList();

  List<ManagedOpening> get managedOpenings => [
    for (final host in owned)
      for (final opening in host.openings)
        ManagedOpening(host: host, opening: opening),
  ];

  void switchSport(TeamSportType? sport) {
    if (selectedSport.value == sport) return;
    selectedSport.value = sport;
  }

  void switchType(OpeningType? type) {
    if (selectedType.value == type) return;
    selectedType.value = type;
  }

  Future<bool> enroll(OpeningModel opening, {String? teamId}) async {
    final openingId = opening.id;
    if (openingId == null || openingId.isEmpty) return false;
    if (enrollingIds.contains(openingId)) return false;
    enrollingIds.add(openingId);
    final result = await _openingService.enroll(openingId, teamId: teamId);
    var ok = false;
    if (result != null) {
      final joined = result.status == EnrollmentStatus.accepted;
      AppSnackbar.success(
        title: joined ? 'Enrolled' : 'Request sent',
        message: joined
            ? 'You are in ${opening.hostName}.'
            : 'Your enrollment is waiting for review.',
      );
      await _invalidateAfterEnroll(joined: joined);
      ok = true;
    }
    enrollingIds.remove(openingId);
    return ok;
  }

  /// Teams this user can enter in a tournament: owner, captain, or vice captain.
  Future<List<TeamMemberFieldInstance>> enterableTeams(String? sport) async {
    final sportType = _sportOf(sport);
    final page = await _teamService.memberService.myMemberships(
      MyTeamMembershipsFilterQuery(
        status: TeamMemberStatus.active,
        sportType: sportType,
        limit: 50,
      ),
    );
    final uid = Get.isRegistered<AuthStateController>()
        ? Get.find<AuthStateController>().user?.id
        : null;
    final teams = <TeamMemberFieldInstance>[];
    final seen = <String>{};
    for (final membership in page?.data ?? const <TeamMemberModel>[]) {
      final team = membership.team;
      if (team is! TeamMemberFieldInstance) continue;
      final id = team.id;
      if (id == null || id.isEmpty || !seen.add(id)) continue;
      final owner = uid != null && team.ownerIds.contains(uid);
      final lead =
          membership.leadershipRole == LeadershipRole.captain ||
          membership.leadershipRole == LeadershipRole.viceCaptain;
      if (owner || lead) teams.add(team);
    }
    return teams;
  }

  Future<void> loadOwnedOpenings() async {
    final gen = ++_ownedLoadGen;
    if (owned.isEmpty) ownedLoading.value = true;
    try {
      final rows = await _openingService.mine();
      if (gen != _ownedLoadGen || rows == null) return;
      owned.assignAll(rows);
    } finally {
      if (gen == _ownedLoadGen) ownedLoading.value = false;
    }
  }

  Future<bool> postOpening({
    required String targetId,
    required OpeningType type,
    required String title,
    int maxPendingJoinRequests = 50,
  }) async {
    final item = _ownedByTargetId(targetId);
    final trimmed = title.trim();
    if (item == null || item.type != type) return false;
    if (trimmed.isEmpty) {
      AppSnackbar.warning(
        title: 'Opening',
        message: 'Describe what you need.',
      );
      return false;
    }
    if (updatingTargetId.value != null) return false;
    updatingTargetId.value = targetId;
    final created = await _openingService.create(
      type: type,
      targetId: targetId,
      title: trimmed,
      maxPendingJoinRequests: item.isTeam ? maxPendingJoinRequests : 50,
    );
    var ok = false;
    if (created != null) {
      _upsertOpening(targetId, created);
      await _invalidateOpeningsFeed();
      AppSnackbar.success(title: 'Opening posted', message: created.title);
      ok = true;
    }
    updatingTargetId.value = null;
    return ok;
  }

  /// Saves title and, for team openings, the pending-request cap.
  ///
  /// Returns true when nothing changed or the update succeeded.
  Future<bool> saveOpeningEdits(
    String hostId,
    String openingId, {
    required String title,
    int? maxPendingJoinRequests,
  }) async {
    final opening = _openingOn(hostId, openingId);
    final trimmed = title.trim();
    if (opening == null) return false;
    if (trimmed.isEmpty) {
      AppSnackbar.warning(
        title: 'Opening',
        message: 'Describe what you need.',
      );
      return false;
    }
    final titleChanged = trimmed != opening.title;
    final pendingChanged =
        maxPendingJoinRequests != null &&
        maxPendingJoinRequests != opening.maxPendingJoinRequests;
    if (!titleChanged && !pendingChanged) return true;
    if (updatingTargetId.value != null) return false;
    updatingTargetId.value = openingId;
    final updated = await _openingService.update(
      openingId,
      title: titleChanged ? trimmed : null,
      maxPendingJoinRequests: pendingChanged ? maxPendingJoinRequests : null,
    );
    var ok = false;
    if (updated != null) {
      _upsertOpening(hostId, updated);
      await _invalidateOpeningsFeed();
      AppSnackbar.success(title: 'Opening updated', message: updated.title);
      ok = true;
    }
    updatingTargetId.value = null;
    return ok;
  }

  Future<void> setOpeningStatus(
    String hostId,
    String openingId,
    OpeningStatus status,
  ) async {
    if (updatingTargetId.value != null) return;
    updatingTargetId.value = openingId;
    final updated = await _openingService.update(openingId, status: status);
    if (updated != null) {
      if (updated.status == OpeningStatus.closed) {
        _dropOpening(hostId, openingId);
      } else {
        _upsertOpening(hostId, updated);
      }
      await _invalidateOpeningsFeed();
      AppSnackbar.success(
        title: 'Opening updated',
        message: switch (status) {
          OpeningStatus.open => 'Opening is live again.',
          OpeningStatus.onHold => 'Opening is on hold.',
          OpeningStatus.closed => 'Opening closed.',
        },
      );
    }
    updatingTargetId.value = null;
  }

  OwnedOpening? _ownedByTargetId(String targetId) {
    for (final item in owned) {
      if (item.id == targetId) return item;
    }
    return null;
  }

  OpeningModel? _openingOn(String hostId, String openingId) {
    final host = _ownedByTargetId(hostId);
    if (host == null) return null;
    for (final opening in host.openings) {
      if (opening.id == openingId) return opening;
    }
    return null;
  }

  void _upsertOpening(String hostId, OpeningModel opening) {
    final index = owned.indexWhere((item) => item.id == hostId);
    if (index < 0) return;
    final current = owned[index];
    final next = <OpeningModel>[
      for (final row in current.openings)
        if (row.id != opening.id) row,
    ];
    next.insert(0, opening);
    owned[index] = current.copyWith(openings: next);
  }

  void _dropOpening(String hostId, String openingId) {
    final index = owned.indexWhere((item) => item.id == hostId);
    if (index < 0) return;
    final current = owned[index];
    owned[index] = current.copyWith(
      openings: [
        for (final row in current.openings)
          if (row.id != openingId) row,
      ],
    );
  }

  Future<void> _invalidateAfterEnroll({required bool joined}) async {
    if (!Get.isRegistered<QueryClient>()) return;
    final client = Get.find<QueryClient>();
    final futures = <Future<void>>[
      client.invalidateQueries(queryKey: QueryKeys.openingsPrefix),
      client.invalidateQueries(queryKey: QueryKeys.explorePrefix),
      client.invalidateQueries(queryKey: QueryKeys.myEnrollmentsPrefix),
    ];
    if (joined) {
      futures.add(client.invalidateQueries(queryKey: QueryKeys.myMemberships));
    }
    await Future.wait(futures);
  }

  Future<void> _invalidateOpeningsFeed() async {
    if (!Get.isRegistered<QueryClient>()) return;
    final client = Get.find<QueryClient>();
    await Future.wait([
      client.invalidateQueries(queryKey: QueryKeys.openingsPrefix),
      client.invalidateQueries(queryKey: QueryKeys.explorePrefix),
    ]);
  }
}

TeamSportType? _sportOf(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  for (final sport in TeamSportType.values) {
    if (sport.name == raw) return sport;
  }
  return null;
}
