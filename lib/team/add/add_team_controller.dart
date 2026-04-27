import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/services/media_upload_service.dart';
import 'package:get/get.dart';

import '../../core/config/constants.dart';
import '../../core/models/location_model.dart';
import '../../core/utils/app_snackbar.dart';
import '../model/team_model.dart';
import '../team_service.dart';
import '../details/team_detail_controller.dart';

class AddTeamController extends GetxController {
  final TeamService _teamService = TeamService();

  // ── Text controllers ─────────────────────────────────────────────────────

  final nameController = TextEditingController();
  final shortNameController = TextEditingController();
  final taglineController = TextEditingController();
  final descriptionController = TextEditingController();
  final foundedYearController = TextEditingController();
  final maxPendingController = TextEditingController(text: '10');

  final instagramController = TextEditingController();
  final twitterController = TextEditingController();
  final facebookController = TextEditingController();
  final youtubeController = TextEditingController();

  final tagInputController = TextEditingController();
  final noticeInputController = TextEditingController();
  final addressController = TextEditingController();
  final latController = TextEditingController();
  final lngController = TextEditingController();

  // ── Reactive state ───────────────────────────────────────────────────────

  final Rx<TeamSportType> sportType = TeamSportType.football.obs;
  final Rx<TeamVisibility> visibility = TeamVisibility.public.obs;
  final Rx<TeamJoinMode> joinMode = TeamJoinMode.approval.obs;
  final Rxn<TeamGenderCategory> genderCategory = Rxn<TeamGenderCategory>();
  final Rxn<TeamPreferredTimeSlot> preferredTimeSlot =
      Rxn<TeamPreferredTimeSlot>();

  final RxSet<TeamDayOfWeek> preferredPlayDays = <TeamDayOfWeek>{}.obs;
  final RxBool lookingForMembers = false.obs;
  final RxList<String> tags = <String>[].obs;
  final RxList<String> pinnedNotices = <String>[].obs;

  final RxBool isSubmitting = false.obs;

  final RxList<String> logoImages = <String>[].obs;
  final RxList<String> coverImages = <String>[].obs;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  String? _editingTeamId;

  /// Storage URLs removed while editing; deleted after a successful team update.
  final List<String> _pendingRemoteImageDeletes = [];

  bool get isEditing => _editingTeamId != null;

  void queueDeferredRemoteImageDeletion(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return;
    if (!_pendingRemoteImageDeletes.contains(trimmed)) {
      _pendingRemoteImageDeletes.add(trimmed);
    }
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      final t = args['team'];
      if (t is TeamModel && t.id != null && t.id!.isNotEmpty) {
        _editingTeamId = t.id;
        _applyExistingTeam(t);
      }
    }
  }

  void _applyExistingTeam(TeamModel t) {
    _pendingRemoteImageDeletes.clear();

    nameController.text = t.name;
    shortNameController.text = t.shortName ?? '';
    taglineController.text = t.tagline ?? '';
    descriptionController.text = t.description ?? '';
    if (t.foundedYear != null) {
      foundedYearController.text = t.foundedYear.toString();
    }
    maxPendingController.text = '${t.maxPendingJoinRequests}';

    sportType.value = t.sportType;
    visibility.value = t.visibility;
    joinMode.value = t.joinMode;
    genderCategory.value = t.genderCategory;
    preferredTimeSlot.value = t.preferredTimeSlot;
    lookingForMembers.value = t.lookingForMembers;

    for (final dayStr in t.preferredPlayDays) {
      final match = TeamDayOfWeek.values.where((d) => d.name == dayStr);
      if (match.isNotEmpty) preferredPlayDays.add(match.first);
    }

    instagramController.text = t.socialLinks.instagram ?? '';
    twitterController.text = t.socialLinks.twitter ?? '';
    facebookController.text = t.socialLinks.facebook ?? '';
    youtubeController.text = t.socialLinks.youtube ?? '';

    tags.assignAll(t.tags);
    pinnedNotices.assignAll(t.pinnedNotices);
    addressController.text = t.location?.address ?? '';
    if (t.location != null) {
      latController.text = t.location!.latitude.toString();
      lngController.text = t.location!.longitude.toString();
    }

    if (t.logo.isNotEmpty) logoImages.add(t.logo);
    coverImages.addAll(t.coverImages);
  }

  @override
  void onClose() {
    nameController.dispose();
    shortNameController.dispose();
    taglineController.dispose();
    descriptionController.dispose();
    foundedYearController.dispose();
    maxPendingController.dispose();
    instagramController.dispose();
    twitterController.dispose();
    facebookController.dispose();
    youtubeController.dispose();
    tagInputController.dispose();
    noticeInputController.dispose();
    addressController.dispose();
    latController.dispose();
    lngController.dispose();
    super.onClose();
  }

  // ── Tag helpers ──────────────────────────────────────────────────────────

  void addTag() {
    final raw = tagInputController.text.trim();
    if (raw.isNotEmpty && !tags.contains(raw)) {
      tags.add(raw);
      tagInputController.clear();
    }
  }

  void removeTag(String tag) => tags.remove(tag);

  // ── Notice helpers ───────────────────────────────────────────────────────

  void addNotice() {
    final raw = noticeInputController.text.trim();
    if (raw.isNotEmpty) {
      pinnedNotices.add(raw);
      noticeInputController.clear();
    }
  }

  void removeNotice(int index) {
    if (index >= 0 && index < pinnedNotices.length) {
      pinnedNotices.removeAt(index);
    }
  }

  // ── Day toggle ───────────────────────────────────────────────────────────

  void toggleDay(TeamDayOfWeek day) {
    if (preferredPlayDays.contains(day)) {
      preferredPlayDays.remove(day);
    } else {
      preferredPlayDays.add(day);
    }
  }

  // ── Collected DTO helpers ────────────────────────────────────────────────

  TeamSocialLinks? _collectSocialLinks() {
    final ig = instagramController.text.trim();
    final tw = twitterController.text.trim();
    final fb = facebookController.text.trim();
    final yt = youtubeController.text.trim();
    if (ig.isEmpty && tw.isEmpty && fb.isEmpty && yt.isEmpty) return null;
    return TeamSocialLinks(
      instagram: ig.isEmpty ? null : ig,
      twitter: tw.isEmpty ? null : tw,
      facebook: fb.isEmpty ? null : fb,
      youtube: yt.isEmpty ? null : yt,
    );
  }

  int? _collectFoundedYear() {
    final raw = foundedYearController.text.trim();
    if (raw.isEmpty) return null;
    return int.tryParse(raw);
  }

  List<TeamDayOfWeek>? _collectPlayDays() {
    if (preferredPlayDays.isEmpty) return null;
    return preferredPlayDays.toList()
      ..sort((a, b) => a.index.compareTo(b.index));
  }

  LocationModel? _collectLocation() {
    final address = addressController.text.trim();
    final latitude = double.tryParse(latController.text.trim());
    final longitude = double.tryParse(lngController.text.trim());
    if (address.isEmpty || latitude == null || longitude == null) return null;
    return LocationModel(
      address: address,
      coordinates: GeoPointModel.fromLngLat(
        longitude: longitude,
        latitude: latitude,
      ),
    );
  }

  // ── Submit ───────────────────────────────────────────────────────────────

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    final maxPending = int.tryParse(maxPendingController.text.trim());
    if (maxPending == null || maxPending < 0 || maxPending > 1000) {
      AppSnackbar.error(
        title: 'Invalid pending requests',
        message: 'Enter a number from 0 to 1000.',
      );
      return;
    }

    if (visibility.value == TeamVisibility.private &&
        joinMode.value == TeamJoinMode.open) {
      AppSnackbar.warning(
        title: 'Join mode',
        message:
            'Private teams cannot use open join. Switch to approval or make the team public.',
      );
      return;
    }

    final logo = logoImages.isNotEmpty ? logoImages.first : null;
    final covers = coverImages.isNotEmpty ? coverImages.toList() : null;
    final shortName = shortNameController.text.trim();
    final tagline = taglineController.text.trim();
    final description = descriptionController.text.trim();
    final social = _collectSocialLinks();
    final founded = _collectFoundedYear();
    final playDays = _collectPlayDays();
    final tagsVal = tags.isNotEmpty ? tags.toList() : null;
    final notices = pinnedNotices.isNotEmpty ? pinnedNotices.toList() : null;
    final location = _collectLocation();

    isSubmitting.value = true;
    try {
      if (isEditing) {
        final updated = await _teamService.update(
          _editingTeamId!,
          UpdateTeamRequest(
            name: nameController.text.trim(),
            shortName: shortName.isEmpty ? null : shortName,
            description: description.isEmpty ? null : description,
            tagline: tagline.isEmpty ? null : tagline,
            socialLinks: social,
            foundedYear: founded,
            genderCategory: genderCategory.value,
            maxPendingJoinRequests: maxPending,
            logo: logo,
            coverImages: covers,
            tags: tagsVal,
            preferredPlayDays: playDays,
            preferredTimeSlot: preferredTimeSlot.value,
            lookingForMembers: lookingForMembers.value,
            pinnedNotices: notices,
            visibility: visibility.value,
            joinMode: joinMode.value,
            location: location,
          ),
        );
        if (updated != null) {
          await flushPendingRemoteImageDeletions(_pendingRemoteImageDeletes);
          AppSnackbar.success(title: 'Team updated', message: updated.name);
          if (Get.isRegistered<TeamDetailController>()) {
            await Get.find<TeamDetailController>().load();
          }
          Get.offNamed(AppConstants.routes.myTeams);
        } else {
          AppSnackbar.error(
            title: 'Update failed',
            message: 'Check your connection and try again.',
          );
        }
      } else {
        final created = await _teamService.create(
          CreateTeamRequest(
            name: nameController.text.trim(),
            shortName: shortName.isEmpty ? null : shortName,
            description: description.isEmpty ? null : description,
            tagline: tagline.isEmpty ? null : tagline,
            socialLinks: social,
            foundedYear: founded,
            genderCategory: genderCategory.value,
            maxPendingJoinRequests: maxPending,
            logo: logo,
            coverImages: covers,
            tags: tagsVal,
            preferredPlayDays: playDays,
            preferredTimeSlot: preferredTimeSlot.value,
            lookingForMembers: lookingForMembers.value,
            pinnedNotices: notices,
            sportType: sportType.value,
            visibility: visibility.value,
            joinMode: joinMode.value,
            location: location,
          ),
        );
        if (created != null) {
          AppSnackbar.success(
            title: 'Team created',
            message: '${created.name} is ready.',
          );
          if (Get.isRegistered<TeamDetailController>()) {
            await Get.find<TeamDetailController>().load();
          }
          Get.offNamed(AppConstants.routes.myTeams);
        } else {
          AppSnackbar.error(
            title: 'Could not create team',
            message: 'Check your connection and try again.',
          );
        }
      }
    } finally {
      isSubmitting.value = false;
    }
  }
}
