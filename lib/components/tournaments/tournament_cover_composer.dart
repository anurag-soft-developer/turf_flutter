import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../shared/app_network_image.dart';
import '../../core/config/constants.dart';
import '../../core/media/local_image_pipeline.dart';
import '../../core/utils/exception_handler.dart';
import '../../team/utils/team_media_url.dart';
import '../../tournament/create/create_tournament_controller.dart';

/// Optional cover carousel for tournament create (same flow as team covers).
class TournamentCoverComposer extends StatefulWidget {
  const TournamentCoverComposer({super.key, required this.controller});

  final CreateTournamentController controller;

  @override
  State<TournamentCoverComposer> createState() => _TournamentCoverComposerState();
}

class _TournamentCoverComposerState extends State<TournamentCoverComposer> {
  static const double _coverHeight = 200;

  final ImagePicker _picker = ImagePicker();
  final PageController _pageCtrl = PageController();
  var _pageIndex = 0;

  CreateTournamentController get _c => widget.controller;

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
        'You can add up to ${CreateTournamentController.maxCoverImages} cover photos',
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
      if (covers.isNotEmpty && _pageIndex >= covers.length) {
        _pageIndex = covers.length - 1;
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: _coverHeight,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildCoverArea(covers),
              const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0x66000000)],
                      stops: [0.5, 1.0],
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
              if (covers.length > 1)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 10,
                  child: IgnorePointer(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(covers.length, (i) {
                        final active = i == _pageIndex;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: active ? 18 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: active
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildCoverArea(List<LocalImageDraft> covers) {
    if (covers.isEmpty) {
      return GestureDetector(
        onTap: _showCoverSourceSheet,
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
                  size: 36,
                ),
                SizedBox(height: 8),
                Text(
                  'Add cover photos (optional)',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return PageView.builder(
      controller: _pageCtrl,
      itemCount: covers.length,
      onPageChanged: (i) => setState(() => _pageIndex = i),
      itemBuilder: (_, i) => _CoverSlide(draft: covers[i]),
    );
  }
}

class _CoverSlide extends StatelessWidget {
  const _CoverSlide({required this.draft});

  final LocalImageDraft draft;

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
    final url = resolveTeamMediaUrl(draft.remoteUrl ?? '');
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
        Icons.image_not_supported_outlined,
        color: Colors.white38,
        size: 40,
      ),
    ),
  );
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label});

  final String label;

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
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

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
