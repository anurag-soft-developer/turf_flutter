import 'package:flutter/material.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../core/auth/auth_state_controller.dart';
import '../core/cache/app_image_cache.dart';
import '../core/components/image_editor/image_editor_page.dart';
import '../core/media/local_image_pipeline.dart';
import '../core/models/media_upload_models.dart';
import '../core/models/user/user_model.dart';
import '../core/query/query_keys.dart';
import '../core/services/media_upload_service.dart';
import '../core/utils/app_snackbar.dart';

class ProfileController extends GetxController {
  static ProfileController get instance => Get.find();

  static const _avatarEditorOptions = ImageEditorOptions(
    title: 'Avatar',
    cropAspectRatio: 1,
    lockCropAspectRatio: true,
  );

  final AuthStateController _authController = AuthStateController.instance;
  final EditedImageTempStore _tempStore = EditedImageTempStore();

  final avatarDraft = Rxn<LocalImageDraft>();
  final List<String> _pendingRemoteImageDeletes = [];

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  final GlobalKey<FormState> profileFormKey = GlobalKey<FormState>();

  final RxBool _isLoading = false.obs;
  final RxString submitMessage = 'Saving…'.obs;

  bool get isLoading => _isLoading.value;

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
  }

  @override
  void onClose() {
    fullNameController.dispose();
    bioController.dispose();
    emailController.dispose();
    phoneController.dispose();
    _tempStore.clear();
    super.onClose();
  }

  void _loadUserData() {
    _tempStore.clear();
    _pendingRemoteImageDeletes.clear();
    final user = _authController.user;
    if (user != null) {
      fullNameController.text = user.fullName ?? '';
      bioController.text = user.bio ?? '';
      emailController.text = user.email ?? '';
      phoneController.text = user.phone ?? '';
      final avatar = user.avatar?.trim();
      avatarDraft.value =
          (avatar != null && avatar.isNotEmpty) ? LocalImageDraft.remote(avatar) : null;
    } else {
      avatarDraft.value = null;
    }
  }

  Future<void> setAvatarFromPick(XFile file) async {
    final previous = avatarDraft.value;
    final result = await openImageEditor(
      images: [ImageEditorInput(original: file)],
      options: _avatarEditorOptions,
    );
    if (result == null || result.isEmpty) return;

    final out = result.first;
    _tempStore.delete(previous?.edited?.path);
    _tempStore.track(out.file.path);
    final oldRemote = previous?.remoteUrl?.trim();
    if (oldRemote != null && oldRemote.isNotEmpty) {
      _queueDeferredRemoteDeletion(oldRemote);
    }
    avatarDraft.value = LocalImageDraft.fromEditor(
      original: out.original,
      file: out.file,
      stateJson: out.stateJson,
    );
  }

  Future<void> reEditAvatar() async {
    final current = avatarDraft.value;
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
      options: _avatarEditorOptions,
    );
    if (result == null || result.isEmpty) return;

    final out = result.first;
    final next = current.copyWith(remoteUrl: current.remoteUrl);
    next.applyEditorOutput(
      out,
      trackTemp: _tempStore.track,
      deleteTemp: _tempStore.delete,
    );
    avatarDraft.value = next;
  }

  Future<XFile?> _ensureLocalFile(LocalImageDraft draft) async {
    final existing = draft.original ?? draft.edited;
    if (existing != null) return existing;
    final url = draft.remoteUrl?.trim() ?? '';
    if (url.isEmpty) return null;
    try {
      final file = await AppImageCache.instance.getSingleFile(url);
      return XFile(file.path);
    } catch (e) {
      debugPrint('Failed to cache avatar: $e');
      return null;
    }
  }

  void _queueDeferredRemoteDeletion(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return;
    if (!_pendingRemoteImageDeletes.contains(trimmed)) {
      _pendingRemoteImageDeletes.add(trimmed);
    }
  }

  Future<UserModel?> updateProfile() async {
    if (!(profileFormKey.currentState?.validate() ?? false)) return null;

    _isLoading.value = true;
    submitMessage.value = 'Saving…';
    var uploaded = <UploadedMediaRef>[];

    try {
      String? avatarUrl = avatarDraft.value?.remoteUrl?.trim();
      final local = avatarDraft.value?.localFile;
      if (local != null) {
        submitMessage.value = 'Uploading photo…';
        final refs = await DeferredMediaUpload.uploadAll(
          files: [local],
          purpose: MediaUploadPurpose.avatar,
        );
        if (refs == null || refs.isEmpty) {
          AppSnackbar.error(
            title: 'Upload failed',
            message: 'Could not upload photo. Try again.',
          );
          return null;
        }
        uploaded = refs;
        avatarUrl = refs.first.fileUrl;
        avatarDraft.value =
            avatarDraft.value?.copyWith(remoteUrl: avatarUrl) ??
            LocalImageDraft.remote(avatarUrl);
      }

      submitMessage.value = 'Saving…';
      final result = await _authController.updateUserProfile(
        fullName: fullNameController.text.trim(),
        bio: bioController.text.trim(),
        avatar: avatarUrl,
      );

      if (result == null) {
        await DeferredMediaUpload.rollback(uploaded);
        AppSnackbar.error(
          title: 'Failed',
          message: 'Could not update profile. Try again.',
        );
        return null;
      }

      await flushPendingRemoteImageDeletions(_pendingRemoteImageDeletes);
      _tempStore.clear();
      _leaveAfterSuccess(
        title: 'Profile updated',
        message: 'Your changes have been saved.',
      );
      return result;
    } catch (e) {
      debugPrint('Update profile error: $e');
      await DeferredMediaUpload.rollback(uploaded);
      AppSnackbar.error(
        title: 'Failed',
        message: 'Could not update profile. Try again.',
      );
      return null;
    } finally {
      if (!isClosed && _isLoading.value) {
        _isLoading.value = false;
      }
    }
  }

  /// Navigate first, then snackbar + invalidate after the frame (avoids Get.back
  /// closing a snackbar instead of the route).
  void _leaveAfterSuccess({
    required String title,
    required String message,
  }) {
    _isLoading.value = false;
    if (Get.isSnackbarOpen) {
      Get.closeAllSnackbars();
    }
    Get.back();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppSnackbar.success(title: title, message: message);
      _invalidateProfileQuery();
    });
  }

  Future<void> _invalidateProfileQuery() async {
    if (!Get.isRegistered<QueryClient>()) return;
    await Get.find<QueryClient>().invalidateQueries(
      queryKey: QueryKeys.profile,
    );
  }

  void refreshProfile() {
    _loadUserData();
    update();
  }
}
