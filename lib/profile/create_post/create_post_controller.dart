import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/auth/auth_state_controller.dart';
import '../../core/models/media_upload_models.dart';
import '../../core/query/query_keys.dart';
import '../../core/services/media_upload_service.dart';
import '../../core/utils/app_snackbar.dart';
import '../../explore/model/content_post_model.dart';
import '../../explore/post_service.dart';
import 'widgets/create_post_image_editor.dart';

enum CreatePostStep { pick, edit, caption }

class PostDraftImage {
  PostDraftImage({
    required this.original,
    this.edited,
    this.stateJson,
  });

  final XFile original;
  XFile? edited;
  String? stateJson;

  XFile get display => edited ?? original;
}

class CreatePostController extends GetxController {
  static const int maxImages = 10;

  final PostService _postService = PostService();

  final captionController = TextEditingController();
  final Rx<CreatePostStep> step = CreatePostStep.pick.obs;
  final RxList<XFile> localFiles = <XFile>[].obs;
  final RxInt previewIndex = 0.obs;
  final RxBool isSubmitting = false.obs;
  final RxString submitMessage = 'Uploading…'.obs;

  final List<PostDraftImage> drafts = [];
  final List<String> _tempEditedPaths = [];

  bool get canAddMore => drafts.length < maxImages;
  int get remainingSlots => maxImages - drafts.length;

  CreatePostEditorImage _toEditorImage(PostDraftImage draft) {
    return CreatePostEditorImage(
      original: draft.original,
      preview: draft.edited,
      stateJson: draft.stateJson,
    );
  }

  Future<void> onPhotosPicked(List<XFile> incoming, int afterIndex) async {
    if (incoming.isEmpty || remainingSlots <= 0) return;

    final existing = {
      ...drafts.map((d) => d.original.path),
      ...drafts.map((d) => d.edited?.path).whereType<String>(),
    };
    final accepted = <XFile>[];
    for (final file in incoming) {
      if (accepted.length >= remainingSlots) break;
      if (existing.contains(file.path)) continue;
      accepted.add(file);
    }
    if (accepted.isEmpty) return;

    final insertAt = (afterIndex >= 0 && afterIndex < drafts.length)
        ? afterIndex + 1
        : drafts.length;

    final images = <CreatePostEditorImage>[
      for (var i = 0; i < insertAt; i++) _toEditorImage(drafts[i]),
      for (final file in accepted) CreatePostEditorImage(original: file),
      for (var i = insertAt; i < drafts.length; i++) _toEditorImage(drafts[i]),
    ];

    final result = await _openEditor(images, initialIndex: insertAt);
    if (result == null || result.length != images.length) {
      _restoreStep();
      return;
    }

    final newPaths = {for (final file in accepted) file.path};
    _replaceDraftsFromOutput(result);
    previewIndex.value = drafts.indexWhere(
      (d) => newPaths.contains(d.original.path),
    ).clamp(0, drafts.length - 1);
    _syncLocalFiles();
    step.value = CreatePostStep.caption;
  }

  Future<void> reEditAt(int index) async {
    if (index < 0 || index >= drafts.length) return;

    final focused = drafts[index].original.path;
    final result = await _openEditor(
      drafts.map(_toEditorImage).toList(),
      initialIndex: index,
    );
    if (result == null || result.length != drafts.length) {
      previewIndex.value = index;
      step.value = CreatePostStep.caption;
      return;
    }

    _replaceDraftsFromOutput(result);
    final nextIndex = drafts.indexWhere((d) => d.original.path == focused);
    previewIndex.value = nextIndex >= 0 ? nextIndex : 0;
    _syncLocalFiles();
    step.value = CreatePostStep.caption;
  }

  void _replaceDraftsFromOutput(List<CreatePostEditorOutput> result) {
    final byOriginal = {for (final d in drafts) d.original.path: d};
    final nextDrafts = <PostDraftImage>[];
    for (final out in result) {
      final prev = byOriginal[out.original.path];
      if (prev != null) {
        prev.stateJson = out.stateJson;
        if (out.file.path != prev.display.path) {
          _deleteTemp(prev.edited?.path);
          prev.edited = out.file;
          _trackTemp(out.file.path);
        }
        nextDrafts.add(prev);
      } else {
        nextDrafts.add(
          PostDraftImage(
            original: out.original,
            edited: out.file,
            stateJson: out.stateJson,
          ),
        );
        _trackTemp(out.file.path);
      }
    }
    drafts
      ..clear()
      ..addAll(nextDrafts);
  }

  Future<List<CreatePostEditorOutput>?> _openEditor(
    List<CreatePostEditorImage> images, {
    int initialIndex = 0,
  }) async {
    if (images.isEmpty) return null;
    step.value = CreatePostStep.edit;
    if (isClosed) return null;
    return Get.to<List<CreatePostEditorOutput>>(
      () => CreatePostImageEditorPage(
        images: images,
        initialIndex: initialIndex,
      ),
      fullscreenDialog: true,
      transition: Transition.cupertino,
      preventDuplicates: false,
    );
  }

  void onEditedFileRemoved(XFile file) {
    final i = drafts.indexWhere(
      (d) => d.edited?.path == file.path || d.original.path == file.path,
    );
    if (i >= 0) {
      _deleteTemp(drafts[i].edited?.path);
      drafts.removeAt(i);
    } else {
      _deleteTemp(file.path);
    }
    if (drafts.isEmpty) {
      localFiles.clear();
      previewIndex.value = 0;
      step.value = CreatePostStep.pick;
    } else {
      previewIndex.value = previewIndex.value.clamp(0, drafts.length - 1);
    }
  }

  void _restoreStep() {
    step.value = drafts.isEmpty ? CreatePostStep.pick : CreatePostStep.caption;
  }

  void _syncLocalFiles() {
    localFiles.assignAll(drafts.map((d) => d.display));
  }

  void _trackTemp(String path) {
    if (!_tempEditedPaths.contains(path)) {
      _tempEditedPaths.add(path);
    }
  }

  Future<void> submit() async {
    if (isSubmitting.value) return;

    final files = List<XFile>.from(localFiles);
    final content = captionController.text.trim();

    if (files.isEmpty) {
      AppSnackbar.error(
        title: 'Photo required',
        message: 'Add at least one photo to publish.',
      );
      return;
    }

    isSubmitting.value = true;
    submitMessage.value = 'Uploading…';
    final uploaded = <UploadedMediaRef>[];

    try {
      for (final xfile in files) {
        final ref = await MediaUploadService.instance.uploadLocalFile(
          file: File(xfile.path),
          purpose: MediaUploadPurpose.postMedia,
          onProgress: (_) {},
        );
        if (ref == null) {
          await _rollbackUploads(uploaded);
          AppSnackbar.error(
            title: 'Upload failed',
            message: 'Could not upload photos. Try again.',
          );
          return;
        }
        uploaded.add(ref);
      }

      submitMessage.value = 'Publishing…';
      final created = await _postService.create(
        CreatePostRequest(
          content: content,
          status: PostStatus.published,
          media: uploaded
              .map(
                (ref) => CreatePostMediaInput(
                  url: ref.fileUrl,
                  kind: MediaKind.image,
                ),
              )
              .toList(),
        ),
      );

      if (created == null) {
        await _rollbackUploads(uploaded);
        AppSnackbar.error(
          title: 'Failed',
          message: 'Could not publish post. Try again.',
        );
        return;
      }

      await _invalidateQueries();

      _clearTempFiles();
      isSubmitting.value = false;
      Get.back();
      AppSnackbar.success(
        title: 'Published',
        message: 'Your photo post is live.',
      );
    } catch (e) {
      debugPrint('Create post submit error: $e');
      await _rollbackUploads(uploaded);
      AppSnackbar.error(
        title: 'Failed',
        message: 'Could not publish post. Try again.',
      );
    } finally {
      if (isSubmitting.value) {
        isSubmitting.value = false;
      }
    }
  }

  Future<void> _rollbackUploads(List<UploadedMediaRef> uploaded) async {
    if (uploaded.isEmpty) return;
    try {
      await MediaUploadService.instance.deleteObjects(
        uploaded.map((u) => u.objectKey).toList(),
      );
    } catch (e) {
      debugPrint('Failed to roll back unpublished uploads: $e');
    }
  }

  Future<void> _invalidateQueries() async {
    if (!Get.isRegistered<QueryClient>()) return;
    final client = Get.find<QueryClient>();
    final userId = Get.find<AuthStateController>().user?.id;
    final futures = <Future<void>>[
      client.invalidateQueries(queryKey: QueryKeys.explorePrefix),
    ];
    if (userId != null && userId.isNotEmpty) {
      futures.add(
        client.invalidateQueries(queryKey: QueryKeys.userPosts(userId)),
      );
    }
    await Future.wait(futures);
  }

  void _deleteTemp(String? path) {
    if (path == null || path.isEmpty) return;
    if (!_tempEditedPaths.remove(path)) return;
    try {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    } catch (e) {
      debugPrint('Failed to delete temp post image: $e');
    }
  }

  void _clearTempFiles() {
    for (final path in List<String>.from(_tempEditedPaths)) {
      _deleteTemp(path);
    }
  }

  @override
  void onClose() {
    captionController.dispose();
    _clearTempFiles();
    super.onClose();
  }
}
