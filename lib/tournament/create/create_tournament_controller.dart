import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/components/image_editor/image_editor_page.dart';
import '../../core/media/local_image_pipeline.dart';
import '../../core/models/media_upload_models.dart';
import '../../core/utils/app_snackbar.dart';

class CreateTournamentController extends GetxController {
  static const int maxCoverImages = 5;

  static const _coverEditorOptions = ImageEditorOptions(
    title: 'Cover',
    cropAspectRatio: 16 / 9,
    lockCropAspectRatio: true,
  );

  final EditedImageTempStore _tempStore = EditedImageTempStore();
  final RxList<LocalImageDraft> coverDrafts = <LocalImageDraft>[].obs;

  bool get canAddMoreCovers => coverDrafts.length < maxCoverImages;
  int get remainingCoverSlots => maxCoverImages - coverDrafts.length;

  @override
  void onClose() {
    _tempStore.clear();
    super.onClose();
  }

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
    final local = current.localFile;
    if (local == null) {
      AppSnackbar.error(
        title: 'Could not edit',
        message: 'This photo is not available locally.',
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
  }

  /// Uploads local drafts and returns storage URLs in carousel order.
  Future<List<String>?> coverUrlsForCreate() async {
    final files = <XFile>[];
    final indices = <int>[];
    for (var i = 0; i < coverDrafts.length; i++) {
      final draft = coverDrafts[i];
      if (draft.localFile != null) {
        files.add(draft.localFile!);
        indices.add(i);
      }
    }

    if (files.isNotEmpty) {
      final uploaded = await DeferredMediaUpload.uploadAll(
        files: files,
        purpose: MediaUploadPurpose.teamMedia,
      );
      if (uploaded == null) {
        AppSnackbar.error(
          title: 'Upload failed',
          message: 'Could not upload cover photos. Try again.',
        );
        return null;
      }
      for (var u = 0; u < indices.length; u++) {
        coverDrafts[indices[u]] =
            coverDrafts[indices[u]].copyWith(remoteUrl: uploaded[u].fileUrl);
      }
    }

    final urls = <String>[
      for (final draft in coverDrafts)
        if (draft.remoteUrl != null && draft.remoteUrl!.trim().isNotEmpty)
          draft.remoteUrl!.trim(),
    ];
    return urls;
  }
}
