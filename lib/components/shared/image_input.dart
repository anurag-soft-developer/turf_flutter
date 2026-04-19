import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/config/constants.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/models/media_upload_models.dart';
import '../../core/services/media_upload_service.dart';
import '../../core/utils/exception_handler.dart';
import '../create_turf/section_container.dart';

/// Gallery / camera image field with optional presigned URL upload and progress.
///
/// Requires a reactive list and [onChange] whenever the effective list of URLs
/// changes (add, remove, or replace). Defaults handle picking + upload unless
/// you pass custom callbacks.
class ImageInput extends StatefulWidget {
  final String title;
  final IconData icon;
  final RxList<String> imageUrls;
  final void Function(List<String> urls)? onChange;

  /// When set, a hint is shown until at least this many images exist.
  final int minImages;

  /// Maximum images (omit for no limit). When `1`, new uploads replace the slot.
  final int? maxImages;

  /// Backend storage category for presigned uploads (ignored when using custom pick handlers).
  final MediaUploadPurpose uploadPurpose;

  /// Adds a bottom-sheet option to paste a public image URL (no upload).
  final bool allowPasteUrl;

  /// Override default camera behavior (pick + presigned upload).
  final Future<void> Function()? pickImageFromCamera;

  /// Override default gallery behavior (pick + presigned upload).
  final Future<void> Function()? pickImageFromGallery;

  /// Override default bottom sheet (camera / gallery / optional URL).
  final void Function()? showImagePickerOptions;

  /// When false, removing or replacing an image does not call the storage delete
  /// API; use [onDeferredRemoteRemoval] to queue deletes until the parent saves.
  final bool deleteRemoteOnRemove;

  /// Called when [deleteRemoteOnRemove] is false and the user removes a URL or
  /// replaces the slot ([maxImages] == 1). Parent should delete after a successful save.
  final void Function(String url)? onDeferredRemoteRemoval;

  /// When set, this widget is shown instead of [SectionContainer]. The whole
  /// widget receives taps that open the image source sheet (camera / gallery).
  final Widget? buttonChild;

  const ImageInput({
    super.key,
    this.title = 'Images',
    this.icon = Icons.image,
    required this.imageUrls,
    this.onChange,
    this.minImages = 0,
    this.maxImages,
    this.uploadPurpose = MediaUploadPurpose.turfMedia,
    this.allowPasteUrl = false,
    this.pickImageFromCamera,
    this.pickImageFromGallery,
    this.showImagePickerOptions,
    this.deleteRemoteOnRemove = true,
    this.onDeferredRemoteRemoval,
    this.buttonChild,
  });

  @override
  State<ImageInput> createState() => _ImageInputState();
}

class _ImageInputState extends State<ImageInput> {
  final MediaUploadService _upload = MediaUploadService.instance;

  final Set<String> _removingUrls = {};
  bool _uploading = false;
  double _progress = 0;

  void _notifyChanged() {
    widget.onChange?.call(widget.imageUrls.toList());
  }

  void _afterAddUrl(String url) {
    if (url.isEmpty) return;
    if (widget.maxImages == 1) {
      widget.imageUrls
        ..clear()
        ..add(url);
    } else if (!widget.imageUrls.contains(url)) {
      widget.imageUrls.add(url);
    }
    _notifyChanged();
  }

  /// Deletes the Spaces object when [url] is ours; succeeds with no remote key (e.g. pasted URL).
  Future<bool> _deleteRemoteObjectForUrl(String url) async {
    final key = MediaUploadService.inferObjectKeyFromPublicUrl(url);
    if (key == null) return true;

    final result = await _upload.deleteObjects([key]);
    if (result == null) return false;
    if (result.failed.any((f) => f.objectKey == key)) return false;
    if (!result.deleted.contains(key)) return false;
    return true;
  }

  Future<bool> _afterUpload(UploadedMediaRef ref) async {
    if (widget.maxImages == 1 && widget.imageUrls.isNotEmpty) {
      final oldUrl = widget.imageUrls.first;
      if (widget.deleteRemoteOnRemove) {
        if (!await _deleteRemoteObjectForUrl(oldUrl)) {
          if (mounted) {
            ExceptionHandler.showErrorToast(
              'Could not replace image (delete failed)',
            );
          }
          return false;
        }
      } else {
        widget.onDeferredRemoteRemoval?.call(oldUrl);
      }
    }

    _afterAddUrl(ref.fileUrl);
    return true;
  }

  Future<void> _removeUrl(String url) async {
    if (widget.deleteRemoteOnRemove) {
      if (!await _deleteRemoteObjectForUrl(url)) {
        if (mounted) {
          ExceptionHandler.showErrorToast('Could not delete file from storage');
        }
        return;
      }
    } else {
      widget.onDeferredRemoteRemoval?.call(url);
    }

    widget.imageUrls.remove(url);
    _notifyChanged();
  }

  Future<void> _defaultPick(ImageSource source) async {
    if (!_canAddMore()) return;

    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );

      if (image == null || !mounted) return;

      setState(() {
        _uploading = true;
        _progress = 0;
      });

      final uploaded = await _upload.uploadLocalFile(
        file: File(image.path),
        purpose: widget.uploadPurpose,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );

      if (!mounted) return;

      if (uploaded != null) {
        final applied = await _afterUpload(uploaded);
        if (mounted && applied) {
          ExceptionHandler.showSuccessToast('Image uploaded successfully');
        }
      }
    } on PlatformException catch (e) {
      String message = source == ImageSource.camera
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
    } on FormatException catch (_) {
      ExceptionHandler.showErrorToast('Unsupported file type');
    } catch (e) {
      debugPrint('Upload error: $e');
      ExceptionHandler.showErrorToast('Failed to upload image');
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
          _progress = 0;
        });
      }
    }
  }

  bool _canAddMore() {
    final max = widget.maxImages;
    if (max == null) return true;
    if (widget.imageUrls.length < max) return true;
    // Single-image fields (avatar, cover): allow picking again to replace.
    return max == 1;
  }

  /// Pops the sheet first; opening the picker in the same frame often fails.
  void _closeSheetThenRun(VoidCallback action) {
    Get.back();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      action();
    });
  }

  void _defaultShowImagePickerOptions() {
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
              widget.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(AppColors.primaryColor),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(
                Icons.camera_alt,
                color: Color(AppColors.primaryColor),
              ),
              title: Text(
                'Camera',
                style: TextStyle(color: Color(AppColors.textColor)),
              ),
              onTap: () {
                _closeSheetThenRun(() {
                  final pick = widget.pickImageFromCamera;
                  if (pick != null) {
                    pick();
                  } else {
                    _defaultPick(ImageSource.camera);
                  }
                });
              },
            ),
            ListTile(
              leading: Icon(
                Icons.photo_library,
                color: Color(AppColors.primaryColor),
              ),
              title: Text(
                'Gallery',
                style: TextStyle(color: Color(AppColors.textColor)),
              ),
              onTap: () {
                _closeSheetThenRun(() {
                  final pick = widget.pickImageFromGallery;
                  if (pick != null) {
                    pick();
                  } else {
                    _defaultPick(ImageSource.gallery);
                  }
                });
              },
            ),
            if (widget.allowPasteUrl) ...[
              ListTile(
                leading: Icon(Icons.link, color: Color(AppColors.primaryColor)),
                title: Text(
                  'Image URL',
                  style: TextStyle(color: Color(AppColors.textColor)),
                ),
                subtitle: Text(
                  'Add from web URL',
                  style: TextStyle(color: Color(AppColors.textColor)),
                ),
                onTap: () {
                  _closeSheetThenRun(_showUrlDialog);
                },
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showUrlDialog() {
    final urlController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Add Image URL'),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(
            hintText: 'Paste image URL here',
            prefixIcon: Icon(Icons.link),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              _afterAddUrl(value.trim());
              Get.back();
            }
          },
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final url = urlController.text.trim();
              if (url.isNotEmpty) {
                _afterAddUrl(url);
                Get.back();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _onShowOptionsTap() {
    final show = widget.showImagePickerOptions;
    if (show != null) {
      show();
    } else {
      _defaultShowImagePickerOptions();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.buttonChild != null) {
      return Obx(() {
        widget.imageUrls.length;
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _uploading ? null : _onShowOptionsTap,
              child: widget.buttonChild!,
            ),
            if (_uploading)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.35),
                    child: const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      });
    }

    return SectionContainer(
      title: widget.title,
      icon: widget.icon,
      children: [
        Obx(() {
          final bool canAddMore = _canAddMore();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_uploading) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    minHeight: 8,
                    value: _progress > 0 ? _progress : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 8),
                  child: Text(
                    _progress > 0
                        ? 'Uploading… ${(_progress * 100).round()}%'
                        : 'Uploading…',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ),
              ],
              if (widget.imageUrls.isEmpty && canAddMore)
                _buildEmptyPlaceholder(context)
              else if (widget.imageUrls.isNotEmpty) ...[
                _buildImagePreviewGrid(),
                const SizedBox(height: 10),
              ],
              if (canAddMore)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: _compactSourceButton(
                          context,
                          icon: Icons.add_photo_alternate_outlined,
                          label: widget.maxImages == 1 ? 'Replace' : 'Add',
                          onTap: _uploading ? null : _onShowOptionsTap,
                        ),
                      ),
                    ],
                  ),
                ),
              if (widget.minImages > 0 &&
                  widget.imageUrls.length < widget.minImages)
                _buildMinImagesWarning(),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildImagePreviewGrid() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.imageUrls.length,
        itemBuilder: (context, index) {
          final url = widget.imageUrls[index];
          return Container(
            width: 100,
            margin: const EdgeInsets.only(right: 8),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    url,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: _removingUrls.contains(url)
                        ? null
                        : () async {
                            setState(() => _removingUrls.add(url));
                            try {
                              await _removeUrl(url);
                            } finally {
                              if (mounted) {
                                setState(() => _removingUrls.remove(url));
                              }
                            }
                          },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyPlaceholder(BuildContext context) {
    final borderColor = Colors.grey.shade300;
    final isSingle = widget.maxImages == 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: _uploading ? null : _onShowOptionsTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 108,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 32,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isSingle ? 'No image yet' : 'No images yet',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isSingle
                        ? 'Tap to choose or use camera'
                        : 'Tap to add photos',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _compactSourceButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(AppColors.textColor),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        visualDensity: VisualDensity.compact,
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(AppColors.primaryColor)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildMinImagesWarning() {
    final n = widget.minImages;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        n == 1
            ? 'Please add at least one image'
            : 'Please add at least $n images',
        style: const TextStyle(color: Colors.red, fontSize: 12),
      ),
    );
  }
}
