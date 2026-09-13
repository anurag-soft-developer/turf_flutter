import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../components/image_editor/image_editor_page.dart';
import '../config/constants.dart';
import '../models/media_upload_models.dart';
import '../services/media_upload_service.dart';
import '../utils/exception_handler.dart';

/// Local editor output and/or an existing remote URL for one image.
///
/// Used by create-post and team media flows that edit locally and upload on save.
class LocalImageDraft {
  String? remoteUrl;
  XFile? original;
  XFile? edited;
  String? stateJson;

  LocalImageDraft({
    this.remoteUrl,
    this.original,
    this.edited,
    this.stateJson,
  });

  factory LocalImageDraft.remote(String url) => LocalImageDraft(remoteUrl: url);

  factory LocalImageDraft.fromEditor({
    required XFile original,
    required XFile file,
    String? stateJson,
    String? remoteUrl,
  }) {
    return LocalImageDraft(
      remoteUrl: remoteUrl,
      original: original,
      edited: file,
      stateJson: stateJson,
    );
  }

  /// Prefer edited preview; fall back to original pick / cache file.
  XFile? get localFile => edited ?? original;

  /// Same as [localFile] for callers that always have a local original.
  XFile get display => edited ?? original!;

  bool get hasLocal => localFile != null;

  ImageEditorInput toEditorInput({XFile? originalOverride}) {
    return ImageEditorInput(
      original: originalOverride ?? original ?? display,
      preview: edited,
      stateJson: stateJson,
    );
  }

  void applyEditorOutput(
    ImageEditorOutput out, {
    void Function(String path)? trackTemp,
    void Function(String? path)? deleteTemp,
  }) {
    stateJson = out.stateJson;
    original = out.original;
    if (out.file.path != localFile?.path) {
      deleteTemp?.call(edited?.path);
      edited = out.file;
      trackTemp?.call(out.file.path);
    }
  }

  LocalImageDraft copyWith({
    String? remoteUrl,
    XFile? original,
    XFile? edited,
    String? stateJson,
    bool clearRemote = false,
  }) {
    return LocalImageDraft(
      remoteUrl: clearRemote ? null : (remoteUrl ?? this.remoteUrl),
      original: original ?? this.original,
      edited: edited ?? this.edited,
      stateJson: stateJson ?? this.stateJson,
    );
  }
}

/// Tracks temporary edited image files and deletes them when replaced or cleared.
class EditedImageTempStore {
  final List<String> _paths = [];

  void track(String path) {
    if (path.isEmpty) return;
    if (!_paths.contains(path)) {
      _paths.add(path);
    }
  }

  void delete(String? path) {
    if (path == null || path.isEmpty) return;
    if (!_paths.remove(path)) return;
    try {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    } catch (e) {
      debugPrint('Failed to delete temp edited image: $e');
    }
  }

  void clear() {
    for (final path in List<String>.from(_paths)) {
      delete(path);
    }
  }
}

/// Upload local files on save, with rollback of successful uploads on failure.
class DeferredMediaUpload {
  DeferredMediaUpload._();

  /// Uploads [files] in order. On any failure, rolls back what was uploaded
  /// and returns `null`.
  static Future<List<UploadedMediaRef>?> uploadAll({
    required List<XFile> files,
    required MediaUploadPurpose purpose,
  }) async {
    if (files.isEmpty) return [];

    final uploaded = <UploadedMediaRef>[];
    for (final xfile in files) {
      final ref = await MediaUploadService.instance.uploadLocalFile(
        file: File(xfile.path),
        purpose: purpose,
        onProgress: (_) {},
      );
      if (ref == null) {
        await rollback(uploaded);
        return null;
      }
      uploaded.add(ref);
    }
    return uploaded;
  }

  static Future<void> rollback(List<UploadedMediaRef> uploaded) async {
    if (uploaded.isEmpty) return;
    try {
      await MediaUploadService.instance.deleteObjects(
        uploaded.map((u) => u.objectKey).toList(),
      );
    } catch (e) {
      debugPrint('Failed to roll back media uploads: $e');
    }
  }
}

/// Shared camera / gallery source sheet and pick helpers.
class ImageSourcePicker {
  ImageSourcePicker._();

  static void showSourceSheet({
    required String title,
    required VoidCallback onCamera,
    required VoidCallback onGallery,
    bool Function()? isMounted,
  }) {
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
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(AppColors.primaryColor),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(
                Icons.camera_alt,
                color: Color(AppColors.primaryColor),
              ),
              title: const Text(
                'Camera',
                style: TextStyle(color: Color(AppColors.textColor)),
              ),
              onTap: () => _closeSheetThenRun(onCamera, isMounted: isMounted),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: Color(AppColors.primaryColor),
              ),
              title: const Text(
                'Gallery',
                style: TextStyle(color: Color(AppColors.textColor)),
              ),
              onTap: () => _closeSheetThenRun(onGallery, isMounted: isMounted),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  static void _closeSheetThenRun(
    VoidCallback action, {
    bool Function()? isMounted,
  }) {
    Get.back();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isMounted != null && !isMounted()) return;
      action();
    });
  }

  static Future<List<XFile>> pickFromGallery({
    required ImagePicker picker,
    int? limit,
  }) async {
    try {
      final picked = await picker.pickMultiImage(limit: limit);
      return picked;
    } on PlatformException catch (e) {
      handlePickerError(e, fromCamera: false);
      return const [];
    } catch (e) {
      debugPrint('Gallery pick error: $e');
      ExceptionHandler.showErrorToast('Failed to pick images');
      return const [];
    }
  }

  static Future<XFile?> pickFromCamera({
    required ImagePicker picker,
  }) async {
    try {
      return await picker.pickImage(source: ImageSource.camera);
    } on PlatformException catch (e) {
      handlePickerError(e, fromCamera: true);
      return null;
    } catch (e) {
      debugPrint('Camera pick error: $e');
      ExceptionHandler.showErrorToast('Failed to take photo');
      return null;
    }
  }

  static Future<XFile?> pickSingle({
    required ImagePicker picker,
    required ImageSource source,
  }) async {
    try {
      return await picker.pickImage(source: source);
    } on PlatformException catch (e) {
      handlePickerError(e, fromCamera: source == ImageSource.camera);
      return null;
    } catch (e) {
      debugPrint('Image pick error: $e');
      ExceptionHandler.showErrorToast(
        source == ImageSource.camera
            ? 'Failed to take photo'
            : 'Failed to pick image',
      );
      return null;
    }
  }

  static void handlePickerError(
    PlatformException e, {
    required bool fromCamera,
  }) {
    var message = fromCamera
        ? 'Failed to take photo'
        : 'Failed to pick image from gallery';

    if (e.code == 'channel-error') {
      message =
          'Camera/Gallery service unavailable. Please restart the app and try again.';
    } else if (e.code == 'photo_access_denied' ||
        e.code == 'camera_access_denied' ||
        e.message?.contains('Permission denied') == true) {
      message =
          'Permission denied. Please enable access in your device settings.';
    } else if (e.code == 'photo_access_restricted' ||
        e.code == 'camera_access_restricted') {
      message = 'Access is restricted on this device.';
    } else if (e.code == 'camera_no_available') {
      message = 'No camera available on this device.';
    }

    debugPrint('Image picker error: ${e.code} - ${e.message}');
    ExceptionHandler.showErrorToast(message);
  }
}
