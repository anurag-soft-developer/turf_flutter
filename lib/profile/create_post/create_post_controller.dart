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

class CreatePostController extends GetxController {
  final PostService _postService = PostService();

  final captionController = TextEditingController();
  final RxList<XFile> localFiles = <XFile>[].obs;
  final RxBool isSubmitting = false.obs;
  final RxString submitMessage = 'Uploading…'.obs;

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

  @override
  void onClose() {
    captionController.dispose();
    super.onClose();
  }
}
