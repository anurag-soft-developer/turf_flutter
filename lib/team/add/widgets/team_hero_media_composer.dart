import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../components/shared/app_network_image.dart';
import '../../../core/config/constants.dart';
import '../../../core/media/local_image_pipeline.dart';
import '../../../core/utils/exception_handler.dart';
import '../../utils/team_media_url.dart';
import '../add_team_controller.dart';

String? _draftNetworkPreview(LocalImageDraft draft) {
  if (draft.hasLocal) return null;
  return resolveTeamMediaUrl(draft.remoteUrl ?? '');
}

/// Editable cover carousel with the logo overlaid at bottom-left, matching
/// the team profile hero. Picks stay local until Save.
class TeamHeroMediaComposer extends StatefulWidget {
  final AddTeamController controller;

  const TeamHeroMediaComposer({super.key, required this.controller});

  @override
  State<TeamHeroMediaComposer> createState() => _TeamHeroMediaComposerState();
}

class _TeamHeroMediaComposerState extends State<TeamHeroMediaComposer> {
  static const double _coverHeight = 280;

  final ImagePicker _picker = ImagePicker();
  final PageController _pageCtrl = PageController();
  var _pageIndex = 0;

  AddTeamController get _c => widget.controller;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _jumpTo(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageCtrl.hasClients) return;
      final max = _c.coverDrafts.length - 1;
      if (max < 0) return;
      final clamped = index.clamp(0, max);
      _pageCtrl.jumpToPage(clamped);
      setState(() => _pageIndex = clamped);
    });
  }

  void _showCoverSourceSheet() {
    if (!_c.canAddMoreCovers) {
      ExceptionHandler.showInfoToast(
        'You can add up to ${AddTeamController.maxCoverImages} cover photos',
      );
      return;
    }
    ImageSourcePicker.showSourceSheet(
      title: 'Cover photos',
      onCamera: _pickCoverFromCamera,
      onGallery: _pickCoverFromGallery,
      isMounted: () => mounted,
    );
  }

  void _showLogoSourceSheet() {
    ImageSourcePicker.showSourceSheet(
      title: 'Team logo',
      onCamera: () => _pickLogo(ImageSource.camera),
      onGallery: () => _pickLogo(ImageSource.gallery),
      isMounted: () => mounted,
    );
  }

  Future<void> _emitCovers(List<XFile> picked) async {
    final after = _c.coverDrafts.isEmpty
        ? -1
        : _pageIndex.clamp(0, _c.coverDrafts.length - 1);
    final before = _c.coverDrafts.length;
    await _c.addCovers(picked, after);
    if (!mounted || _c.coverDrafts.length <= before) return;
    _jumpTo(after < 0 ? 0 : after + 1);
  }

  Future<void> _pickCoverFromGallery() async {
    if (!_c.canAddMoreCovers) return;
    final picked = await ImageSourcePicker.pickFromGallery(
      picker: _picker,
      limit: _c.remainingCoverSlots,
    );
    if (!mounted || picked.isEmpty) return;
    await _emitCovers(picked);
  }

  Future<void> _pickCoverFromCamera() async {
    if (!_c.canAddMoreCovers) return;
    final image = await ImageSourcePicker.pickFromCamera(picker: _picker);
    if (!mounted || image == null) return;
    await _emitCovers([image]);
  }

  Future<void> _pickLogo(ImageSource source) async {
    final image = await ImageSourcePicker.pickSingle(
      picker: _picker,
      source: source,
    );
    if (!mounted || image == null) return;
    await _c.setLogoFromPick(image);
  }

  void _removeCurrentCover() {
    if (_c.coverDrafts.isEmpty) return;
    final index = _pageIndex.clamp(0, _c.coverDrafts.length - 1);
    _c.removeCoverAt(index);
    if (_c.coverDrafts.isEmpty) {
      setState(() => _pageIndex = 0);
      return;
    }
    _jumpTo(index.clamp(0, _c.coverDrafts.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final covers = _c.coverDrafts.toList();
      final logo = _c.logoDraft.value;
      if (covers.isNotEmpty && _pageIndex >= covers.length) {
        _pageIndex = covers.length - 1;
      }

      return SizedBox(
        height: _coverHeight,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _CoverArea(
              covers: covers,
              pageController: _pageCtrl,
              onPageChanged: (i) => setState(() => _pageIndex = i),
              onEmptyTap: _showCoverSourceSheet,
            ),
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0x8C000000)],
                    stops: [0.35, 1.0],
                  ),
                ),
              ),
            ),
            if (covers.isNotEmpty) ...[
              Positioned(
                top: 10,
                left: 10,
                child: _CountChip(
                  label: '${_pageIndex + 1}/${covers.length}',
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Row(
                  children: [
                    _RoundIconButton(
                      icon: Icons.edit_outlined,
                      onTap: () => _c.reEditCoverAt(
                        _pageIndex.clamp(0, covers.length - 1),
                      ),
                    ),
                    if (_c.canAddMoreCovers) ...[
                      const SizedBox(width: 8),
                      _RoundIconButton(
                        icon: Icons.add,
                        onTap: _showCoverSourceSheet,
                      ),
                    ],
                    const SizedBox(width: 8),
                    _RoundIconButton(
                      icon: Icons.close,
                      onTap: _removeCurrentCover,
                    ),
                  ],
                ),
              ),
            ] else
              Positioned(
                top: 8,
                right: 8,
                child: _RoundIconButton(
                  icon: Icons.add,
                  onTap: _showCoverSourceSheet,
                ),
              ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (covers.length > 1) ...[
                    IgnorePointer(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(covers.length, (i) {
                          final active = i == _pageIndex;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: active ? 22 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: active
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _LogoBadge(
                      draft: logo,
                      onTap: logo == null
                          ? _showLogoSourceSheet
                          : _c.reEditLogo,
                      onCameraTap: _showLogoSourceSheet,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _CoverArea extends StatelessWidget {
  final List<LocalImageDraft> covers;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onEmptyTap;

  const _CoverArea({
    required this.covers,
    required this.pageController,
    required this.onPageChanged,
    required this.onEmptyTap,
  });

  @override
  Widget build(BuildContext context) {
    if (covers.isEmpty) {
      return GestureDetector(
        onTap: onEmptyTap,
        child: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(AppColors.primaryColor),
                Color(AppColors.secondaryColor),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  color: Colors.white70,
                  size: 40,
                ),
                SizedBox(height: 8),
                Text(
                  'Add cover photos',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return PageView.builder(
      controller: pageController,
      itemCount: covers.length,
      onPageChanged: onPageChanged,
      itemBuilder: (_, i) => _CoverSlide(draft: covers[i]),
    );
  }
}

class _CoverSlide extends StatelessWidget {
  final LocalImageDraft draft;

  const _CoverSlide({required this.draft});

  @override
  Widget build(BuildContext context) {
    final file = draft.localFile;
    if (file != null) {
      return Image.file(
        File(file.path),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => _broken,
      );
    }
    final url = _draftNetworkPreview(draft);
    if (url == null) return _broken;
    return AppNetworkImage(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, _, _) => _broken,
    );
  }

  static const _broken = ColoredBox(
    color: Color(AppColors.primaryColor),
    child: Center(
      child: Icon(
        AppIcons.teamPlaceholder,
        color: Colors.white38,
        size: 48,
      ),
    ),
  );
}

class _LogoBadge extends StatelessWidget {
  final LocalImageDraft? draft;
  final VoidCallback onTap;
  final VoidCallback onCameraTap;

  const _LogoBadge({
    required this.draft,
    required this.onTap,
    required this.onCameraTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              key: ValueKey(
                draft?.localFile?.path ??
                    (draft != null ? _draftNetworkPreview(draft!) : null) ??
                    'empty',
              ),
              radius: 36,
              backgroundColor: Colors.white,
              backgroundImage: _logoImage(),
              child: _logoImage() == null
                  ? const Icon(
                      AppIcons.teamPlaceholder,
                      size: 32,
                      color: Color(AppColors.primaryColor),
                    )
                  : null,
            ),
          ),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Material(
            color: Colors.white,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onCameraTap,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(AppColors.primaryColor),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 14,
                  color: Color(AppColors.primaryColor),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  ImageProvider? _logoImage() {
    final file = draft?.localFile;
    if (file != null) return FileImage(File(file.path));
    final current = draft;
    if (current == null) return null;
    final url = _draftNetworkPreview(current);
    if (url == null) return null;
    return AppNetworkImage.provider(url);
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
