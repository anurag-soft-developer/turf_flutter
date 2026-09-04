import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/config/constants.dart';
import '../../../core/utils/exception_handler.dart';

/// Local-only gallery/camera picker with an Instagram-style carousel preview.
/// Does not upload; [onPicked] delivers originals for the editor to process.
class CreatePostMediaPicker extends StatefulWidget {
  final RxList<XFile> files;
  final int maxImages;
  final bool autoOpenSource;
  final Future<void> Function(List<XFile> files, int afterIndex) onPicked;
  final ValueChanged<XFile>? onFileRemoved;
  final ValueChanged<int>? onEdit;
  final RxInt? focusIndex;

  const CreatePostMediaPicker({
    super.key,
    required this.files,
    required this.onPicked,
    this.onFileRemoved,
    this.onEdit,
    this.focusIndex,
    this.maxImages = 10,
    this.autoOpenSource = false,
  });

  @override
  State<CreatePostMediaPicker> createState() => _CreatePostMediaPickerState();
}

class _CreatePostMediaPickerState extends State<CreatePostMediaPicker> {
  final ImagePicker _picker = ImagePicker();
  late final PageController _pageController;
  late int _pageIndex;

  @override
  void initState() {
    super.initState();
    final fileCount = widget.files.length;
    final raw = widget.focusIndex?.value ?? 0;
    final initial = fileCount <= 0 ? 0 : raw.clamp(0, fileCount - 1);
    _pageIndex = initial;
    _pageController = PageController(initialPage: initial);
    if (widget.autoOpenSource) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || widget.files.isNotEmpty) return;
        _showSourceSheet();
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _canAddMore => widget.files.length < widget.maxImages;

  void _jumpToPage(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients) return;
      final max = widget.files.length - 1;
      if (max < 0) return;
      final clamped = index.clamp(0, max);
      _pageController.jumpToPage(clamped);
      setState(() => _pageIndex = clamped);
    });
  }

  void _closeSheetThenRun(VoidCallback action) {
    Get.back();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      action();
    });
  }

  void _showSourceSheet() {
    if (!_canAddMore) {
      ExceptionHandler.showInfoToast(
        'You can add up to ${widget.maxImages} photos',
      );
      return;
    }

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
            const Text(
              'Add photos',
              style: TextStyle(
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
              onTap: () => _closeSheetThenRun(_pickFromCamera),
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
              onTap: () => _closeSheetThenRun(_pickFromGallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _emitPicked(List<XFile> picked) async {
    final after = widget.files.isEmpty
        ? -1
        : _pageIndex.clamp(0, widget.files.length - 1);
    final beforeCount = widget.files.length;
    await widget.onPicked(picked, after);
    if (!mounted || widget.files.length <= beforeCount) return;
    _jumpToPage(after < 0 ? 0 : after + 1);
  }

  Future<void> _pickFromGallery() async {
    if (!_canAddMore) return;
    try {
      final remaining = widget.maxImages - widget.files.length;
      final picked = await _picker.pickMultiImage(limit: remaining);
      if (!mounted || picked.isEmpty) return;
      await _emitPicked(picked);
    } on PlatformException catch (e) {
      _handlePickerError(e, fromCamera: false);
    } catch (e) {
      debugPrint('Gallery pick error: $e');
      ExceptionHandler.showErrorToast('Failed to pick images');
    }
  }

  Future<void> _pickFromCamera() async {
    if (!_canAddMore) return;
    try {
      final image = await _picker.pickImage(source: ImageSource.camera);
      if (!mounted || image == null) return;
      await _emitPicked([image]);
    } on PlatformException catch (e) {
      _handlePickerError(e, fromCamera: true);
    } catch (e) {
      debugPrint('Camera pick error: $e');
      ExceptionHandler.showErrorToast('Failed to take photo');
    }
  }

  void _removeCurrent() {
    if (widget.files.isEmpty) return;
    final index = _pageIndex.clamp(0, widget.files.length - 1);
    final removed = widget.files.removeAt(index);
    widget.onFileRemoved?.call(removed);
    if (widget.files.isEmpty) {
      setState(() => _pageIndex = 0);
      return;
    }
    _jumpToPage(index.clamp(0, widget.files.length - 1));
  }

  void _handlePickerError(PlatformException e, {required bool fromCamera}) {
    String message = fromCamera
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

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (widget.files.isEmpty) {
        return _EmptyState(onTap: _showSourceSheet, maxImages: widget.maxImages);
      }
      return _Carousel(
        files: widget.files,
        pageController: _pageController,
        pageIndex: _pageIndex,
        canAddMore: _canAddMore,
        onPageChanged: (index) => setState(() => _pageIndex = index),
        onRemove: _removeCurrent,
        onAdd: _showSourceSheet,
        onEdit: widget.onEdit == null
            ? null
            : () => widget.onEdit!(
                _pageIndex.clamp(0, widget.files.length - 1),
              ),
      );
    });
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onTap;
  final int maxImages;

  const _EmptyState({required this.onTap, required this.maxImages});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 12),
                Text(
                  'Add photos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gallery or camera · up to $maxImages',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Carousel extends StatefulWidget {
  final List<XFile> files;
  final PageController pageController;
  final int pageIndex;
  final bool canAddMore;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onRemove;
  final VoidCallback onAdd;
  final VoidCallback? onEdit;

  const _Carousel({
    required this.files,
    required this.pageController,
    required this.pageIndex,
    required this.canAddMore,
    required this.onPageChanged,
    required this.onRemove,
    required this.onAdd,
    this.onEdit,
  });

  @override
  State<_Carousel> createState() => _CarouselState();
}

class _CarouselState extends State<_Carousel> {
  static const _fallbackRatio = 1.0;

  final Map<String, double> _ratios = {};
  final List<VoidCallback> _cancelResolvers = [];

  @override
  void initState() {
    super.initState();
    _resolveFiles(widget.files);
  }

  @override
  void didUpdateWidget(_Carousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldPaths = oldWidget.files.map((f) => f.path).toList();
    final nextPaths = widget.files.map((f) => f.path).toList();
    if (!_samePaths(oldPaths, nextPaths)) {
      _resolveFiles(widget.files);
    }
  }

  @override
  void dispose() {
    for (final cancel in _cancelResolvers) {
      cancel();
    }
    super.dispose();
  }

  bool _samePaths(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _resolveFiles(List<XFile> files) {
    for (final file in files) {
      if (_ratios.containsKey(file.path)) continue;
      _listenForRatio(file.path);
    }
  }

  void _listenForRatio(String path) {
    final stream = FileImage(File(path)).resolve(const ImageConfiguration());
    var cancelled = false;
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        stream.removeListener(listener);
        final width = info.image.width;
        final height = info.image.height;
        if (width <= 0 || height <= 0) return;
        if (cancelled || !mounted) return;
        setState(() => _ratios[path] = width / height);
      },
      onError: (_, __) {
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
    _cancelResolvers.add(() {
      cancelled = true;
      stream.removeListener(listener);
    });
  }

  double _carouselHeight(double width) {
    var maxHeight = 0.0;
    var anyKnown = false;
    for (final file in widget.files) {
      final ratio = _ratios[file.path];
      if (ratio == null) continue;
      anyKnown = true;
      final height = width / ratio;
      if (height > maxHeight) maxHeight = height;
    }
    return anyKnown ? maxHeight : width / _fallbackRatio;
  }

  @override
  Widget build(BuildContext context) {
    final files = widget.files;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final naturalHeight = _carouselHeight(width);
        final height = constraints.maxHeight.isFinite
            ? naturalHeight.clamp(0.0, constraints.maxHeight)
            : naturalHeight;

        return Align(
          alignment: Alignment.center,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: width,
              height: height,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: Colors.black,
                    child: PageView.builder(
                      controller: widget.pageController,
                      itemCount: files.length,
                      onPageChanged: widget.onPageChanged,
                      itemBuilder: (context, index) {
                        return Image.file(
                          File(files[index].path),
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          errorBuilder: (_, _, _) => const Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: Colors.white54,
                              size: 48,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _CountChip(
                      label: '${widget.pageIndex + 1}/${files.length}',
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      children: [
                        if (widget.onEdit != null) ...[
                          _RoundIconButton(
                            icon: Icons.edit_outlined,
                            onTap: widget.onEdit!,
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (widget.canAddMore) ...[
                          _RoundIconButton(
                            icon: Icons.add,
                            onTap: widget.onAdd,
                          ),
                          const SizedBox(width: 8),
                        ],
                        _RoundIconButton(
                          icon: Icons.close,
                          onTap: widget.onRemove,
                        ),
                      ],
                    ),
                  ),
                  if (files.length > 1)
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: IgnorePointer(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(files.length, (index) {
                            final active = index == widget.pageIndex;
                            return Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: active
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.5),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CountChip extends StatelessWidget {
  final String label;

  const _CountChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}
