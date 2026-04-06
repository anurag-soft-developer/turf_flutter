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

  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final maxRosterController = TextEditingController(text: '20');
  final maxPendingController = TextEditingController(text: '10');

  final Rx<TeamSportType> sportType = TeamSportType.football.obs;
  final Rx<TeamVisibility> visibility = TeamVisibility.public.obs;
  final Rx<TeamJoinMode> joinMode = TeamJoinMode.approval.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool isLoadingImage = false.obs;

  /// Reactive list for logo image (max 1).
  final RxList<String> logoImages = <String>[].obs;

  /// Reactive list for cover images.
  final RxList<String> coverImages = <String>[].obs;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  String? _editingTeamId;

  bool get isEditing => _editingTeamId != null;

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
    descriptionController.text = t.description ?? '';
    sportType.value = t.sportType;
    maxRosterController.text = '${t.maxRosterSize}';
    maxPendingController.text = '${t.maxPendingJoinRequests}';
    visibility.value = t.visibility;
    joinMode.value = t.joinMode;
    if (t.logo.isNotEmpty) logoImages.add(t.logo);
    coverImages.addAll(t.coverImages);
  }

  @override
  void onClose() {
    nameController.dispose();
    descriptionController.dispose();
    maxRosterController.dispose();
    maxPendingController.dispose();
    super.onClose();
  }

  // ── Logo image helpers ──────────────────────────────────────────────────────

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

  // ── Cover image helpers ─────────────────────────────────────────────────────

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

  // ── Shared image-picking internals ──────────────────────────────────────────

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

  // ── Submit ──────────────────────────────────────────────────────────────────

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    final maxRoster = int.tryParse(maxRosterController.text.trim());
    final maxPending = int.tryParse(maxPendingController.text.trim());
    if (maxRoster == null || maxRoster < 1) {
      AppSnackbar.error(
        title: 'Invalid roster size',
        message: 'Enter a positive number.',
      );
      return;
    }
    if (maxPending == null || maxPending < 0) {
      AppSnackbar.error(
        title: 'Invalid pending requests',
        message: 'Enter zero or a positive number.',
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

    isSubmitting.value = true;
    try {
      if (isEditing) {
        final updated = await _teamService.update(
          _editingTeamId!,
          UpdateTeamRequest(
            name: nameController.text.trim(),
            description: descriptionController.text.trim().isEmpty
                ? null
                : descriptionController.text.trim(),
            sportType: sportType.value,
            maxRosterSize: maxRoster,
            maxPendingJoinRequests: maxPending,
            logo: logo,
            coverImages: covers,
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
            description: descriptionController.text.trim().isEmpty
                ? null
                : descriptionController.text.trim(),
            sportType: sportType.value,
            maxRosterSize: maxRoster,
            maxPendingJoinRequests: maxPending,
            logo: logo,
            coverImages: covers,
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
