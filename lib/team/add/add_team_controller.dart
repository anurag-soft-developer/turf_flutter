import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/config/constants.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/exception_handler.dart';
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
  final RxBool isLoadingImage = false.obs;

  final RxList<String> logoImages = <String>[].obs;
  final RxList<String> coverImages = <String>[].obs;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  String? _editingTeamId;

  bool get isEditing => _editingTeamId != null;

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

  // ── Logo image helpers ───────────────────────────────────────────────────

  void addLogoUrl(String url) {
    if (url.isNotEmpty) {
      logoImages
        ..clear()
        ..add(url);
    }
  }

  void removeLogo(String url) => logoImages.remove(url);

  Future<void> pickLogoFromGallery() async =>
      _pickImage(ImageSource.gallery, isLogo: true);

  Future<void> pickLogoFromCamera() async =>
      _pickImage(ImageSource.camera, isLogo: true);

  void showLogoPickerOptions() => _showPickerSheet(isLogo: true);

  // ── Cover image helpers ──────────────────────────────────────────────────

  void addCoverUrl(String url) {
    if (url.isNotEmpty && !coverImages.contains(url)) {
      coverImages.add(url);
    }
  }

  void removeCover(String url) => coverImages.remove(url);

  Future<void> pickCoverFromGallery() async =>
      _pickImage(ImageSource.gallery, isLogo: false);

  Future<void> pickCoverFromCamera() async =>
      _pickImage(ImageSource.camera, isLogo: false);

  void showCoverPickerOptions() => _showPickerSheet(isLogo: false);

  // ── Shared image-picking internals ───────────────────────────────────────

  Future<void> _pickImage(ImageSource source, {required bool isLogo}) async {
    try {
      final XFile? image = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );
      if (image != null) {
        await _uploadImage(File(image.path), isLogo: isLogo);
      }
    } on PlatformException catch (e) {
      String msg = source == ImageSource.camera
          ? 'Failed to take photo'
          : 'Failed to pick image from gallery';
      if (e.code == 'channel-error') {
        msg =
            'Camera/Gallery service unavailable. Restart the app and try again.';
      } else if (e.message?.contains('Permission denied') == true) {
        msg = 'Permission denied. Enable access in device settings.';
      }
      debugPrint('Image picker error: ${e.code} - ${e.message}');
      ExceptionHandler.showErrorToast(msg);
    } on Exception catch (e) {
      debugPrint('Image picker error: $e');
      ExceptionHandler.showErrorToast('Failed to pick image');
    }
  }

  Future<void> _uploadImage(File imageFile, {required bool isLogo}) async {
    try {
      isLoadingImage.value = true;
      // TODO: replace with your actual upload service
      await Future.delayed(const Duration(seconds: 1));
      const String uploadedUrl =
          'https://fastly.picsum.photos/id/363/200/300.jpg?hmac=LvonEMeE2QnwxULuBZW5xHtdjkz844GnAPpEhDwGvMY';
      if (isLogo) {
        logoImages
          ..clear()
          ..add(uploadedUrl);
      } else {
        coverImages.add(uploadedUrl);
      }
      ExceptionHandler.showSuccessToast('Image uploaded successfully');
    } catch (e) {
      ExceptionHandler.showErrorToast('Failed to upload image');
    } finally {
      isLoadingImage.value = false;
    }
  }

  void _showPickerSheet({required bool isLogo}) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isLogo ? 'Set Logo' : 'Add Cover Image',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Get.back();
                isLogo ? pickLogoFromCamera() : pickCoverFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Get.back();
                isLogo ? pickLogoFromGallery() : pickCoverFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Image URL'),
              subtitle: const Text('Add from web URL'),
              onTap: () {
                Get.back();
                _showUrlDialog(isLogo: isLogo);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showUrlDialog({required bool isLogo}) {
    final urlCtrl = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: Text(isLogo ? 'Set Logo URL' : 'Add Cover Image URL'),
        content: TextField(
          controller: urlCtrl,
          decoration: const InputDecoration(
            hintText: 'Paste image URL here',
            prefixIcon: Icon(Icons.link),
          ),
          onSubmitted: (v) {
            if (v.trim().isNotEmpty) {
              isLogo ? addLogoUrl(v.trim()) : addCoverUrl(v.trim());
              Get.back();
            }
          },
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final url = urlCtrl.text.trim();
              if (url.isNotEmpty) {
                isLogo ? addLogoUrl(url) : addCoverUrl(url);
                Get.back();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
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
          ),
        );
        if (updated != null) {
          AppSnackbar.success(title: 'Team updated', message: updated.name);
          if (Get.isRegistered<TeamDetailController>()) {
            await Get.find<TeamDetailController>().load();
          }
          Get.offNamed(AppConstants.routes.myTeam);
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
          Get.offNamed(AppConstants.routes.myTeam);
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
