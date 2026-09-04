import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../../../core/config/constants.dart';
import '../../../core/utils/exception_handler.dart';
import '../../../core/utils/image_compress_util.dart';

const _kEditorToolbarHeight = 44.0;
const _kFilmstripHeight = 58.0;
const _kFilmstripBg = Color(0xFF1A1A1A);

const _kExportConfigs = ExportEditorConfigs(
  historySpan: ExportHistorySpan.current,
);

const _kImportConfigs = ImportEditorConfigs(
  mergeMode: ImportEditorMergeMode.replace,
  recalculateSizeAndPosition: true,
  enableInitialEmptyState: true,
);

/// One photo handed to [CreatePostImageEditorPage].
class CreatePostEditorImage {
  final XFile original;
  final XFile? preview;
  final String? stateJson;

  const CreatePostEditorImage({
    required this.original,
    this.preview,
    this.stateJson,
  });
}

/// Flattened preview plus optional editor history for one photo.
class CreatePostEditorOutput {
  final XFile file;
  final XFile original;
  final String? stateJson;

  const CreatePostEditorOutput({
    required this.file,
    required this.original,
    this.stateJson,
  });
}

/// Full-screen editor for one or more photos.
///
/// Always edits [CreatePostEditorImage.original] and restores layers from
/// [CreatePostEditorImage.stateJson] when present. Swiping saves a flattened
/// JPEG preview only; WebP compression runs once when leaving for caption.
/// Returns compressed files plus state JSON so a later session can keep
/// filters/text/crop editable.
class CreatePostImageEditorPage extends StatefulWidget {
  final List<CreatePostEditorImage> images;
  final int initialIndex;

  const CreatePostImageEditorPage({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  @override
  State<CreatePostImageEditorPage> createState() =>
      _CreatePostImageEditorPageState();
}

class _CreatePostImageEditorPageState extends State<CreatePostImageEditorPage> {
  late final List<CreatePostEditorImage> _images;
  late int _index;
  var _popped = false;
  var _finishing = false;
  var _busy = false;
  int? _pendingIndex;
  String? _pendingStateJson;

  final Map<int, XFile> _previews = {};
  final Map<int, String> _states = {};
  final List<String> _sessionTemps = [];
  final Set<int> _uploadReady = {};

  bool get _isMulti => _images.length > 1;

  XFile get _currentOriginal => _images[_index].original;

  List<XFile> get _originals =>
      _images.map((image) => image.original).toList();

  @override
  void initState() {
    super.initState();
    _images = List<CreatePostEditorImage>.from(widget.images);
    _index = widget.initialIndex.clamp(0, _images.length - 1);
    for (var i = 0; i < _images.length; i++) {
      final image = _images[i];
      if (image.preview != null) _previews[i] = image.preview!;
      final json = image.stateJson;
      if (json != null && json.isNotEmpty) _states[i] = json;
    }
  }

  @override
  void dispose() {
    if (!_popped) {
      for (final path in _sessionTemps) {
        _tryDelete(path);
      }
    }
    super.dispose();
  }

  void _popWith(List<CreatePostEditorOutput>? result) {
    if (_popped || !mounted) return;
    _popped = true;
    Navigator.of(context).pop(result);
  }

  void _tryDelete(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    } catch (_) {}
  }

  void _setPreview(int i, XFile file) {
    final prev = _previews[i];
    if (prev != null &&
        prev.path != file.path &&
        _sessionTemps.remove(prev.path)) {
      _tryDelete(prev.path);
    }
    _previews[i] = file;
    if (!_sessionTemps.contains(file.path)) {
      _sessionTemps.add(file.path);
    }
  }

  ImportStateHistory? _historyFor(int i) {
    final json = _states[i];
    if (json == null || json.isEmpty) return null;
    try {
      return ImportStateHistory.fromJson(json, configs: _kImportConfigs);
    } catch (e) {
      debugPrint('Failed to restore editor state: $e');
      return null;
    }
  }

  Future<XFile> _writePreviewJpeg(Uint8List bytes) async {
    final path =
        '${Directory.systemTemp.path}/post_preview_${DateTime.now().microsecondsSinceEpoch}.jpg';
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    return XFile(file.path, mimeType: 'image/jpeg');
  }

  void _applyPendingState() {
    final json = _pendingStateJson;
    _pendingStateJson = null;
    if (json == null || json.isEmpty) {
      _states.remove(_index);
    } else {
      _states[_index] = json;
    }
  }

  Future<void> _onEditingComplete(Uint8List bytes) async {
    _busy = true;
    try {
      _applyPendingState();

      if (_pendingIndex != null) {
        _setPreview(_index, await _writePreviewJpeg(bytes));
        final next = _pendingIndex!;
        _pendingIndex = null;
        _busy = false;
        if (mounted) setState(() => _index = next);
        return;
      }

      if (_finishing) {
        await _setCompressed(_index, bytes);
        await _compressPendingOutputs();
        _popWith(_outputs());
      }
    } catch (e) {
      debugPrint('Create post compress error: $e');
      ExceptionHandler.showErrorToast('Could not process photo');
      _pendingIndex = null;
      _pendingStateJson = null;
      _finishing = false;
    } finally {
      _busy = false;
    }
  }

  Future<void> _setCompressed(int i, Uint8List bytes) async {
    _setPreview(i, await compressEditorBytesToWebp(bytes));
    _uploadReady.add(i);
  }

  Future<void> _compressPendingOutputs() async {
    for (var i = 0; i < _images.length; i++) {
      if (_uploadReady.contains(i)) continue;
      final preview = _previews[i];
      if (preview != null && !_sessionTemps.contains(preview.path)) continue;
      final source = preview ?? _images[i].original;
      final bytes = await File(source.path).readAsBytes();
      await _setCompressed(i, bytes);
    }
  }

  List<CreatePostEditorOutput> _outputs() {
    return List<CreatePostEditorOutput>.generate(
      _images.length,
      (i) => CreatePostEditorOutput(
        file: _previews[i]!,
        original: _images[i].original,
        stateJson: _states[i],
      ),
    );
  }

  void _reorder(int from, int to) {
    if (_busy || _finishing || from == to) return;
    var dest = to;
    if (dest > from) dest -= 1;
    if (from == dest) return;

    List<T?> asList<T>(Map<int, T> map) =>
        List<T?>.generate(_images.length, (i) => map[i]);

    void writeMap<T>(Map<int, T> map, List<T?> items) {
      map.clear();
      for (var i = 0; i < items.length; i++) {
        final value = items[i];
        if (value != null) map[i] = value;
      }
    }

    void move<T>(List<T> list) {
      final item = list.removeAt(from);
      list.insert(dest, item);
    }

    final current = _images[_index];
    final previews = asList(_previews);
    final states = asList(_states);
    final ready = List<bool>.generate(
      _images.length,
      (i) => _uploadReady.contains(i),
    );

    move(_images);
    move(previews);
    move(states);
    move(ready);

    writeMap(_previews, previews);
    writeMap(_states, states);
    _uploadReady
      ..clear()
      ..addAll([
        for (var i = 0; i < ready.length; i++)
          if (ready[i]) i,
      ]);

    setState(() => _index = _images.indexOf(current).clamp(0, _images.length - 1));
  }

  Future<void> _commitCurrent(
    ProImageEditorState editor, {
    int? next,
  }) async {
    if (_busy || _finishing) return;
    if (next != null) {
      if (next == _index || next < 0 || next >= _images.length) return;
    }

    final hasLiveEdits = editor.canUndo;
    final reverted = !hasLiveEdits && editor.canRedo;

    if (!hasLiveEdits && !reverted) {
      if (next != null) {
        setState(() => _index = next);
        return;
      }
      _finishing = true;
      try {
        await _compressPendingOutputs();
        _popWith(_outputs());
      } catch (e) {
        debugPrint('Create post compress error: $e');
        ExceptionHandler.showErrorToast('Could not process photo');
        _finishing = false;
      }
      return;
    }

    _busy = true;
    _pendingIndex = next;
    _finishing = next == null;
    _pendingStateJson = null;

    try {
      if (hasLiveEdits) {
        final history = await editor.exportStateHistory(configs: _kExportConfigs);
        if (!mounted) {
          _busy = false;
          _finishing = false;
          _pendingIndex = null;
          return;
        }
        _pendingStateJson = await history.toJson();
      }
      if (!mounted) {
        _busy = false;
        _finishing = false;
        _pendingIndex = null;
        _pendingStateJson = null;
        return;
      }
      editor.doneEditing();
    } catch (e) {
      debugPrint('Create post save edits error: $e');
      ExceptionHandler.showErrorToast('Could not save edits');
      _busy = false;
      _pendingIndex = null;
      _pendingStateJson = null;
      _finishing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(AppColors.primaryColor);
    final history = _historyFor(_index);

    return ProImageEditor.file(
      File(_currentOriginal.path),
      key: ValueKey('create-post-editor-${_currentOriginal.path}'),
      callbacks: ProImageEditorCallbacks(
        onImageEditingComplete: _onEditingComplete,
      ),
      configs: ProImageEditorConfigs(
        heroTag: 'create-post-editor-${_currentOriginal.path}',
        theme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: primary,
            brightness: Brightness.dark,
          ),
        ),
        i18n: const I18n(
          doneLoadingMsg: 'Saving…',
          various: I18nVarious(
            closeEditorWarningTitle: 'Discard edits?',
            closeEditorWarningMessage:
                'Changes to this photo will not be saved.',
            closeEditorWarningConfirmBtn: 'Discard',
            closeEditorWarningCancelBtn: 'Keep editing',
          ),
        ),
        imageGeneration: const ImageGenerationConfigs(
          maxOutputSize: Size(1440, 1440),
          jpegQuality: 90,
          allowEmptyEditingCompletion: true,
          enableUseOriginalBytes: false,
        ),
        stateHistory: StateHistoryConfigs(initStateHistory: history),
        mainEditor: MainEditorConfigs(
          style: const MainEditorStyle(
            appBarBackground: primary,
            appBarColor: Colors.white,
          ),
          widgets: MainEditorWidgets(
            wrapBody: _isMulti
                ? (editor, rebuildStream, content) {
                    return Column(
                      children: [
                        _Filmstrip(
                          files: _originals,
                          saved: _previews,
                          index: _index,
                          enabled: !_busy && !_finishing,
                          onSelect: (i) => _commitCurrent(editor, next: i),
                          onReorder: _reorder,
                        ),
                        Expanded(
                          child: _SwipeToSwitch(
                            isEnabled: () =>
                                !_busy &&
                                !_finishing &&
                                !editor.isSubEditorOpen &&
                                !editor.isLayerBeingTransformed,
                            onSwipeLeft: () =>
                                _commitCurrent(editor, next: _index + 1),
                            onSwipeRight: () =>
                                _commitCurrent(editor, next: _index - 1),
                            child: content,
                          ),
                        ),
                      ],
                    );
                  }
                : null,
            appBar: (editor, rebuildStream) => ReactiveAppbar(
              stream: rebuildStream,
              appbarSize: const Size.fromHeight(_kEditorToolbarHeight),
              builder: (_) => _EditorAppBar(
                editor: editor,
                index: _index,
                total: _images.length,
                isMulti: _isMulti,
                onClose: editor.closeEditor,
                onDone: () => _commitCurrent(editor),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EditorAppBar extends StatelessWidget implements PreferredSizeWidget {
  final ProImageEditorState editor;
  final int index;
  final int total;
  final bool isMulti;
  final VoidCallback onClose;
  final VoidCallback onDone;

  const _EditorAppBar({
    required this.editor,
    required this.index,
    required this.total,
    required this.isMulti,
    required this.onClose,
    required this.onDone,
  });

  @override
  Size get preferredSize => const Size.fromHeight(_kEditorToolbarHeight);

  @override
  Widget build(BuildContext context) {
    const primary = Color(AppColors.primaryColor);
    const compact = VisualDensity.compact;

    return AppBar(
      toolbarHeight: _kEditorToolbarHeight,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleSpacing: 0,
      backgroundColor: primary,
      foregroundColor: Colors.white,
      title: Text(
        isMulti ? '${index + 1}/$total' : 'Edit',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      leading: IconButton(
        icon: const Icon(Icons.close, size: 20),
        visualDensity: compact,
        tooltip: 'Close',
        onPressed: onClose,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.undo, size: 20),
          visualDensity: compact,
          onPressed: editor.canUndo ? editor.undoAction : null,
        ),
        IconButton(
          icon: const Icon(Icons.redo, size: 20),
          visualDensity: compact,
          onPressed: editor.canRedo ? editor.redoAction : null,
        ),
        IconButton(
          icon: const Icon(Icons.check, size: 20),
          visualDensity: compact,
          tooltip: 'Done',
          onPressed: onDone,
        ),
      ],
    );
  }
}

class _SwipeToSwitch extends StatefulWidget {
  final bool Function() isEnabled;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;
  final Widget child;

  const _SwipeToSwitch({
    required this.isEnabled,
    required this.onSwipeLeft,
    required this.onSwipeRight,
    required this.child,
  });

  @override
  State<_SwipeToSwitch> createState() => _SwipeToSwitchState();
}

class _SwipeToSwitchState extends State<_SwipeToSwitch> {
  Offset? _start;
  var _pointers = 0;
  var _consumed = false;

  void _onDown(PointerDownEvent event) {
    _pointers++;
    if (_pointers == 1 && widget.isEnabled()) {
      _start = event.position;
      _consumed = false;
    } else {
      _start = null;
    }
  }

  void _onUp(PointerEvent event) {
    _pointers = (_pointers - 1).clamp(0, 32);
    final start = _start;
    _start = _pointers == 0 ? null : start;

    if (start == null || _consumed || !widget.isEnabled() || _pointers > 0) {
      return;
    }

    final delta = event.position - start;
    if (delta.dx.abs() < 80) return;
    if (delta.dx.abs() <= delta.dy.abs() * 2) return;

    _consumed = true;
    if (delta.dx < 0) {
      widget.onSwipeLeft();
    } else {
      widget.onSwipeRight();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onDown,
      onPointerUp: _onUp,
      onPointerCancel: _onUp,
      child: widget.child,
    );
  }
}

class _Filmstrip extends StatelessWidget {
  final List<XFile> files;
  final Map<int, XFile> saved;
  final int index;
  final bool enabled;
  final ValueChanged<int> onSelect;
  final void Function(int from, int to) onReorder;

  const _Filmstrip({
    required this.files,
    required this.saved,
    required this.index,
    required this.enabled,
    required this.onSelect,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _kFilmstripBg,
      child: SizedBox(
        height: _kFilmstripHeight,
        child: ReorderableListView.builder(
          scrollDirection: Axis.horizontal,
          buildDefaultDragHandles: false,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          itemCount: files.length,
          onReorder: enabled ? onReorder : (_, _) {},
          proxyDecorator: (child, _, animation) {
            return AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                final t = Curves.easeInOut.transform(animation.value);
                return Transform.scale(
                  scale: 1 + (0.08 * t),
                  child: child,
                );
              },
              child: child,
            );
          },
          itemBuilder: (context, i) {
            final selected = i == index;
            final thumb = saved[i] ?? files[i];
            return ReorderableDelayedDragStartListener(
              key: ValueKey(files[i].path),
              index: i,
              enabled: enabled,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: enabled ? () => onSelect(i) : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: selected ? Colors.white : Colors.white24,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(
                            File(thumb.path),
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const ColoredBox(
                              color: Colors.black26,
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: Colors.white54,
                                size: 16,
                              ),
                            ),
                          ),
                          if (saved[i] != null)
                            const Positioned(
                              right: 2,
                              bottom: 2,
                              child: Icon(
                                Icons.check_circle,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
