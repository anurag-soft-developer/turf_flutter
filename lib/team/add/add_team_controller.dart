import 'package:flutter/material.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/cache/app_image_cache.dart';
import '../../core/components/image_editor/image_editor_page.dart';
import '../../core/config/constants.dart';
import '../../core/models/media_upload_models.dart';
import '../../core/query/query_keys.dart';
import '../../core/media/local_image_pipeline.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/services/media_upload_service.dart';
import '../model/team_model.dart';
import '../team_service.dart';
import '../utils/team_media_url.dart';

class AddTeamController extends GetxController {
  static const int maxCoverImages = 5;

  static const _coverEditorOptions = ImageEditorOptions(
    title: 'Cover',
    cropAspectRatio: 16 / 9,
    lockCropAspectRatio: true,
  );

  static const _logoEditorOptions = ImageEditorOptions(
    title: 'Logo',
    cropAspectRatio: 1,
    lockCropAspectRatio: true,
  );

  final TeamService _teamService = TeamService();
  final EditedImageTempStore _tempStore = EditedImageTempStore();

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
  final RxString submitMessage = 'Saving…'.obs;

  /// Create-mode stepper index (0 = sport, 1 = basic info). Unused in edit mode.
  final RxInt currentStep = 0.obs;

  final logoDraft = Rxn<LocalImageDraft>();
  final RxList<LocalImageDraft> coverDrafts = <LocalImageDraft>[].obs;

  SelectedLocation? _selectedLocation;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  String? _editingTeamId;

  /// Storage URLs removed while editing; deleted after a successful team update.
  final List<String> _pendingRemoteImageDeletes = [];

  bool get isEditing => _editingTeamId != null;
  bool get canAddMoreCovers => coverDrafts.length < maxCoverImages;
  int get remainingCoverSlots => maxCoverImages - coverDrafts.length;

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
      _selectedLocation = SelectedLocation(
        address: t.location!.address,
        latitude: t.location!.latitude,
        longitude: t.location!.longitude,
        city: t.location!.city,
        state: t.location!.state,
        zip: t.location!.zip,
        country: t.location!.country,
      );
    }

    if (t.logo.isNotEmpty) {
      logoDraft.value = LocalImageDraft.remote(t.logo);
    }
    coverDrafts.assignAll(
      t.coverImages
          .where((url) => url.trim().isNotEmpty)
          .map(LocalImageDraft.remote),
    );
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
    _tempStore.clear();
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

  void onLocationSelected(SelectedLocation location) {
    _selectedLocation = location;
    addressController.text = location.address;
    latController.text = location.latitude.toString();
    lngController.text = location.longitude.toString();
  }

  // ── Media drafts (local until Save) ──────────────────────────────────────

  Future<void> addCovers(List<XFile> incoming, int afterIndex) async {
    if (incoming.isEmpty || remainingCoverSlots <= 0) return;

    final accepted = incoming.take(remainingCoverSlots).toList();
    final result = await openImageEditor(
      images: [
        for (final file in accepted) ImageEditorInput(original: file),
      ],
      options: _coverEditorOptions,
    );
    if (result == null || result.isEmpty) return;

    final insertAt = (afterIndex >= 0 && afterIndex < coverDrafts.length)
        ? afterIndex + 1
        : coverDrafts.length;

    var at = insertAt;
    for (final out in result) {
      coverDrafts.insert(
        at,
        LocalImageDraft.fromEditor(
          original: out.original,
          file: out.file,
          stateJson: out.stateJson,
        ),
      );
      _tempStore.track(out.file.path);
      at++;
    }
  }

  Future<void> reEditCoverAt(int index) async {
    if (index < 0 || index >= coverDrafts.length) return;
    final current = coverDrafts[index];
    final local = await _ensureLocalFile(current);
    if (local == null) {
      AppSnackbar.error(
        title: 'Could not edit',
        message: 'Download the photo and try again.',
      );
      return;
    }

    final result = await openImageEditor(
      images: [current.toEditorInput(originalOverride: local)],
      options: _coverEditorOptions,
    );
    if (result == null || result.isEmpty) return;

    final out = result.first;
    final next = current.copyWith(remoteUrl: current.remoteUrl);
    next.applyEditorOutput(
      out,
      trackTemp: _tempStore.track,
      deleteTemp: _tempStore.delete,
    );
    coverDrafts[index] = next;
  }

  void removeCoverAt(int index) {
    if (index < 0 || index >= coverDrafts.length) return;
    final removed = coverDrafts.removeAt(index);
    _tempStore.delete(removed.edited?.path);
    final remote = removed.remoteUrl?.trim();
    if (remote != null && remote.isNotEmpty) {
      queueDeferredRemoteImageDeletion(remote);
    }
  }

  Future<void> setLogoFromPick(XFile file) async {
    final previous = logoDraft.value;
    final result = await openImageEditor(
      images: [ImageEditorInput(original: file)],
      options: _logoEditorOptions,
    );
    if (result == null || result.isEmpty) return;

    final out = result.first;
    _tempStore.delete(previous?.edited?.path);
    _tempStore.track(out.file.path);
    final oldRemote = previous?.remoteUrl?.trim();
    if (oldRemote != null && oldRemote.isNotEmpty) {
      queueDeferredRemoteImageDeletion(oldRemote);
    }
    logoDraft.value = LocalImageDraft.fromEditor(
      original: out.original,
      file: out.file,
      stateJson: out.stateJson,
    );
  }

  Future<void> reEditLogo() async {
    final current = logoDraft.value;
    if (current == null) return;
    final local = await _ensureLocalFile(current);
    if (local == null) {
      AppSnackbar.error(
        title: 'Could not edit',
        message: 'Download the photo and try again.',
      );
      return;
    }

    final result = await openImageEditor(
      images: [current.toEditorInput(originalOverride: local)],
      options: _logoEditorOptions,
    );
    if (result == null || result.isEmpty) return;

    final out = result.first;
    final next = current.copyWith(remoteUrl: current.remoteUrl);
    next.applyEditorOutput(
      out,
      trackTemp: _tempStore.track,
      deleteTemp: _tempStore.delete,
    );
    logoDraft.value = next;
  }

  Future<XFile?> _ensureLocalFile(LocalImageDraft draft) async {
    final existing = draft.original ?? draft.edited;
    if (existing != null) return existing;
    final url = resolveTeamMediaUrl(draft.remoteUrl ?? '');
    if (url == null || url.isEmpty) return null;
    try {
      final file = await AppImageCache.instance.getSingleFile(url);
      return XFile(file.path);
    } catch (e) {
      debugPrint('Failed to cache team image: $e');
      return null;
    }
  }

  Future<List<UploadedMediaRef>> _uploadLocalDrafts() async {
    final files = <XFile>[];
    final logo = logoDraft.value;
    final logoHadLocal = logo?.localFile != null;
    if (logoHadLocal) files.add(logo!.localFile!);

    final coverIndices = <int>[];
    for (var i = 0; i < coverDrafts.length; i++) {
      final draft = coverDrafts[i];
      if (draft.localFile == null) continue;
      files.add(draft.localFile!);
      coverIndices.add(i);
    }

    final uploaded = await DeferredMediaUpload.uploadAll(
      files: files,
      purpose: MediaUploadPurpose.teamMedia,
    );
    if (uploaded == null) return [];

    var ui = 0;
    if (logoHadLocal) {
      logoDraft.value = logo!.copyWith(remoteUrl: uploaded[ui++].fileUrl);
    }
    for (final i in coverIndices) {
      coverDrafts[i] =
          coverDrafts[i].copyWith(remoteUrl: uploaded[ui++].fileUrl);
    }
    return uploaded;
  }

  String? _logoUrlForRequest() {
    final draft = logoDraft.value;
    if (draft == null) return null;
    return draft.remoteUrl?.trim().isNotEmpty == true
        ? draft.remoteUrl!.trim()
        : null;
  }

  List<String> _coverUrlsForRequest() {
    return [
      for (final draft in coverDrafts)
        if (draft.remoteUrl != null && draft.remoteUrl!.trim().isNotEmpty)
          draft.remoteUrl!.trim(),
    ];
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
    final selected = _selectedLocation;
    if (selected != null) {
      return selected.toLocationModel();
    }

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

    isSubmitting.value = true;
    submitMessage.value = 'Uploading photos…';
    var uploaded = <UploadedMediaRef>[];

    try {
      final hadLocal = logoDraft.value?.hasLocal == true ||
          coverDrafts.any((d) => d.hasLocal);
      uploaded = await _uploadLocalDrafts();
      if (hadLocal && uploaded.isEmpty) {
        AppSnackbar.error(
          title: 'Upload failed',
          message: 'Could not upload photos. Try again.',
        );
        return;
      }

      final logo = _logoUrlForRequest();
      final covers = _coverUrlsForRequest();
      final shortName = shortNameController.text.trim();
      final tagline = taglineController.text.trim();
      final description = descriptionController.text.trim();
      final social = _collectSocialLinks();
      final founded = _collectFoundedYear();
      final playDays = _collectPlayDays();
      final tagsVal = tags.isNotEmpty ? tags.toList() : null;
      final notices = pinnedNotices.isNotEmpty ? pinnedNotices.toList() : null;
      final location = _collectLocation();

      submitMessage.value = isEditing ? 'Saving…' : 'Creating team…';
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
        if (updated == null) {
          await DeferredMediaUpload.rollback(uploaded);
          AppSnackbar.error(
            title: 'Failed',
            message: 'Could not update team. Try again.',
          );
          return;
        }
        await flushPendingRemoteImageDeletions(_pendingRemoteImageDeletes);
        _tempStore.clear();
        _leaveAfterSuccess(
          teamId: updated.id,
          title: 'Team updated',
          message: updated.name,
        );
        return;
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
            coverImages: covers.isEmpty ? null : covers,
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
        if (created == null) {
          await DeferredMediaUpload.rollback(uploaded);
          AppSnackbar.error(
            title: 'Failed',
            message: 'Could not create team. Try again.',
          );
          return;
        }
        _tempStore.clear();
        _leaveAfterSuccess(
          teamId: created.id,
          title: 'Team created',
          message: '${created.name} is ready.',
        );
        return;
      }
    } catch (e) {
      debugPrint('Team submit error: $e');
      await DeferredMediaUpload.rollback(uploaded);
      AppSnackbar.error(
        title: 'Failed',
        message: 'Could not save team. Try again.',
      );
    } finally {
      if (!isClosed && isSubmitting.value) {
        isSubmitting.value = false;
      }
    }
  }

  /// Navigate first, then snackbar + invalidate after the frame (avoids Get.back
  /// closing a snackbar instead of the route).
  void _leaveAfterSuccess({
    required String? teamId,
    required String title,
    required String message,
  }) {
    isSubmitting.value = false;
    if (Get.isSnackbarOpen) {
      Get.closeAllSnackbars();
    }
    if (isEditing) {
      Get.back();
    } else {
      Get.offNamed(AppConstants.routes.myTeams);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppSnackbar.success(title: title, message: message);
      _invalidateTeamQueries(teamId);
    });
  }

  Future<void> _invalidateTeamQueries(String? teamId) async {
    if (!Get.isRegistered<QueryClient>()) return;
    final client = Get.find<QueryClient>();
    final futures = <Future<void>>[
      client.invalidateQueries(queryKey: QueryKeys.myMemberships),
    ];
    if (teamId != null && teamId.isNotEmpty) {
      futures.add(
        client.invalidateQueries(queryKey: QueryKeys.teamDetail(teamId)),
      );
    }
    await Future.wait(futures);
  }
}
