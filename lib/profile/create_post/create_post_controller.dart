import 'package:flutter/material.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/auth/auth_state_controller.dart';
import '../../core/components/image_editor/image_editor_page.dart';
import '../../core/media/local_image_pipeline.dart';
import '../../core/models/media_upload_models.dart';
import '../../core/query/query_keys.dart';
import '../../core/utils/app_snackbar.dart';
import '../../explore/model/content_post_model.dart';
import '../../explore/post_service.dart';
import 'widgets/create_post_mention_sheet.dart';

enum CreatePostStep { pick, edit, caption }

class PostMentionRef {
  const PostMentionRef({
    required this.id,
    required this.label,
    this.imageUrl,
    this.secondaryImageUrl,
    this.subtitle,
  });

  final String id;
  final String label;
  final String? imageUrl;
  final String? secondaryImageUrl;
  final String? subtitle;
}

class CreatePostController extends GetxController {
  static const int maxImages = 10;

  final PostService _postService = PostService();
  final EditedImageTempStore _tempStore = EditedImageTempStore();

  final captionController = TextEditingController();
  final Rx<CreatePostStep> step = CreatePostStep.pick.obs;
  final RxList<XFile> localFiles = <XFile>[].obs;
  final RxInt previewIndex = 0.obs;
  final RxBool isSubmitting = false.obs;
  final RxString submitMessage = 'Uploading…'.obs;
  final mentionedTeam = Rxn<PostMentionRef>();
  final mentionedMatch = Rxn<PostMentionRef>();
  final mentionedTurf = Rxn<PostMentionRef>();

  final List<LocalImageDraft> drafts = [];

  bool get canAddMore => drafts.length < maxImages;
  int get remainingSlots => maxImages - drafts.length;

  Future<void> onPhotosPicked(List<XFile> incoming, int afterIndex) async {
    if (incoming.isEmpty || remainingSlots <= 0) return;

    final existing = {
      ...drafts.map((d) => d.original?.path).whereType<String>(),
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

    final images = <ImageEditorInput>[
      for (var i = 0; i < insertAt; i++) drafts[i].toEditorInput(),
      for (final file in accepted) ImageEditorInput(original: file),
      for (var i = insertAt; i < drafts.length; i++) drafts[i].toEditorInput(),
    ];

    final result = await _openEditor(images, initialIndex: insertAt);
    if (result == null || result.length != images.length) {
      _restoreStep();
      return;
    }

    final newPaths = {for (final file in accepted) file.path};
    _replaceDraftsFromOutput(result);
    previewIndex.value = drafts
        .indexWhere((d) => newPaths.contains(d.original?.path))
        .clamp(0, drafts.length - 1);
    _syncLocalFiles();
    step.value = CreatePostStep.caption;
  }

  Future<void> reEditAt(int index) async {
    if (index < 0 || index >= drafts.length) return;

    final focused = drafts[index].original?.path;
    final result = await _openEditor(
      drafts.map((d) => d.toEditorInput()).toList(),
      initialIndex: index,
    );
    if (result == null || result.length != drafts.length) {
      previewIndex.value = index;
      step.value = CreatePostStep.caption;
      return;
    }

    _replaceDraftsFromOutput(result);
    final nextIndex = focused == null
        ? -1
        : drafts.indexWhere((d) => d.original?.path == focused);
    previewIndex.value = nextIndex >= 0 ? nextIndex : 0;
    _syncLocalFiles();
    step.value = CreatePostStep.caption;
  }

  void _replaceDraftsFromOutput(List<ImageEditorOutput> result) {
    final byOriginal = {
      for (final d in drafts)
        if (d.original != null) d.original!.path: d,
    };
    final nextDrafts = <LocalImageDraft>[];
    for (final out in result) {
      final prev = byOriginal[out.original.path];
      if (prev != null) {
        prev.applyEditorOutput(
          out,
          trackTemp: _tempStore.track,
          deleteTemp: _tempStore.delete,
        );
        nextDrafts.add(prev);
      } else {
        nextDrafts.add(
          LocalImageDraft.fromEditor(
            original: out.original,
            file: out.file,
            stateJson: out.stateJson,
          ),
        );
        _tempStore.track(out.file.path);
      }
    }
    drafts
      ..clear()
      ..addAll(nextDrafts);
  }

  Future<List<ImageEditorOutput>?> _openEditor(
    List<ImageEditorInput> images, {
    int initialIndex = 0,
  }) async {
    if (images.isEmpty) return null;
    step.value = CreatePostStep.edit;
    if (isClosed) return null;
    return openImageEditor(images: images, initialIndex: initialIndex);
  }

  void onEditedFileRemoved(XFile file) {
    final i = drafts.indexWhere(
      (d) => d.edited?.path == file.path || d.original?.path == file.path,
    );
    if (i >= 0) {
      _tempStore.delete(drafts[i].edited?.path);
      drafts.removeAt(i);
    } else {
      _tempStore.delete(file.path);
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
    var uploaded = <UploadedMediaRef>[];

    try {
      final refs = await DeferredMediaUpload.uploadAll(
        files: files,
        purpose: MediaUploadPurpose.postMedia,
      );
      if (refs == null) {
        AppSnackbar.error(
          title: 'Upload failed',
          message: 'Could not upload photos. Try again.',
        );
        return;
      }
      uploaded = refs;

      submitMessage.value = 'Publishing…';
      final created = await _postService.create(
        CreatePostRequest(
          content: content,
          status: PostStatus.published,
          team: mentionedTeam.value?.id,
          match: mentionedMatch.value?.id,
          turf: mentionedTurf.value?.id,
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
        await DeferredMediaUpload.rollback(uploaded);
        AppSnackbar.error(
          title: 'Failed',
          message: 'Could not publish post. Try again.',
        );
        return;
      }

      await _invalidateQueries();

      _tempStore.clear();
      isSubmitting.value = false;
      Get.back();
      AppSnackbar.success(
        title: 'Published',
        message: 'Your photo post is live.',
      );
    } catch (e) {
      debugPrint('Create post submit error: $e');
      await DeferredMediaUpload.rollback(uploaded);
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
    futures.add(
      client.invalidateQueries(queryKey: QueryKeys.taggedPostsPrefix),
    );
    await Future.wait(futures);
  }

  Future<void> pickTeam(BuildContext context) async {
    final team = await showCreatePostTeamPicker(context);
    final id = team?.id?.trim();
    if (id == null || id.isEmpty) return;
    mentionedTeam.value = PostMentionRef(
      id: id,
      label: team!.name,
      imageUrl: createPostTeamLogoUrl(team.logo),
      subtitle: team.location?.shortPlaceLabel,
    );
  }

  Future<void> pickMatch(BuildContext context) async {
    final match = await showCreatePostMatchPicker(context);
    final id = match?.id?.trim();
    if (id == null || id.isEmpty) return;
    final from = match!.fromTeamHelper.getSubsetModel();
    final to = match.toTeamHelper.getSubsetModel();
    mentionedMatch.value = PostMentionRef(
      id: id,
      label: match.versusLabel,
      imageUrl: createPostTeamLogoUrl(from?.logo),
      secondaryImageUrl: createPostTeamLogoUrl(to?.logo),
      subtitle: createPostMatchScheduleLabel(match),
    );
    final turf = match.selectedTurfProposal;
    final helper = turf?.turfIdHelper;
    final turfId = helper?.getId()?.trim();
    if (turfId != null && turfId.isNotEmpty) {
      mentionedTurf.value = PostMentionRef(
        id: turfId,
        label: helper!.getDisplayName(),
        imageUrl: helper.getMainImage(),
        subtitle: helper.getLocation()?.shortPlaceLabel ?? helper.getAddress(),
      );
    }
  }

  Future<void> pickTurf(BuildContext context) async {
    final turf = await showCreatePostTurfPicker(context);
    final id = turf?.id?.trim();
    if (id == null || id.isEmpty) return;
    mentionedTurf.value = PostMentionRef(
      id: id,
      label: turf!.displayName,
      imageUrl: turf.mainImage,
      subtitle: turf.location?.shortPlaceLabel ?? turf.location?.address,
    );
  }

  @override
  void onClose() {
    captionController.dispose();
    _tempStore.clear();
    super.onClose();
  }
}
