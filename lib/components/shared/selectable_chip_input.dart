import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/config/constants.dart';
import '../create_turf/section_container.dart';

/// Section with a titled [SectionContainer] and [FilterChip]s for multi-select.
///
/// Pass [options], reactive [selected] ([RxList]), and [onToggle].
/// With [freeSolo], users can type custom values; they appear as chips while
/// selected and are stored in [selected] like preset options.
class SelectableChipInput extends StatefulWidget {
  const SelectableChipInput({
    super.key,
    required this.title,
    required this.icon,
    required this.options,
    required this.selected,
    required this.onToggle,
    this.emptySelectionWarning,
    this.freeSolo = false,
    this.freeSoloHint,
  });

  final String title;
  final IconData icon;
  final List<String> options;
  final RxList<String> selected;
  final void Function(String value) onToggle;
  final String? emptySelectionWarning;

  /// When true, shows a field to add custom labels; they can be toggled like presets.
  final bool freeSolo;

  /// Hint for the custom-value field ([freeSolo] only).
  final String? freeSoloHint;

  static const Color _primary = Color(AppColors.primaryColor);

  @override
  State<SelectableChipInput> createState() => _SelectableChipSectionState();
}

class _SelectableChipSectionState extends State<SelectableChipInput> {
  TextEditingController? _customController;

  @override
  void initState() {
    super.initState();
    if (widget.freeSolo) {
      _customController = TextEditingController();
    }
  }

  @override
  void didUpdateWidget(SelectableChipInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.freeSolo && _customController == null) {
      _customController = TextEditingController();
    } else if (!widget.freeSolo && _customController != null) {
      _customController!.dispose();
      _customController = null;
    }
  }

  @override
  void dispose() {
    _customController?.dispose();
    super.dispose();
  }

  /// Preset options in order, then custom selections not in [options].
  static List<String> _chipLabels(List<String> options, List<String> selected) {
    final preset = options.toSet();
    final extras = <String>[];
    for (final s in selected) {
      if (!preset.contains(s) && !extras.contains(s)) extras.add(s);
    }
    return [...options, ...extras];
  }

  void _submitCustom() {
    final controller = _customController;
    if (controller == null) return;

    final value = controller.text.trim();
    if (value.isEmpty) return;

    if (widget.selected.contains(value)) {
      controller.clear();
      return;
    }
    widget.onToggle(value);
    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      title: widget.title,
      icon: widget.icon,
      children: [
        Obx(() {
          final labels = widget.freeSolo
              ? _chipLabels(widget.options, widget.selected.toList())
              : widget.options;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: labels.map((option) {
              final isSelected = widget.selected.contains(option);
              return FilterChip(
                label: Text(option),
                selected: isSelected,
                onSelected: (_) => widget.onToggle(option),
                selectedColor: const Color.fromARGB(255, 134, 207, 230),
                backgroundColor: Colors.grey[100],
                checkmarkColor: SelectableChipInput._primary,
                labelStyle: TextStyle(
                  color: isSelected
                      ? SelectableChipInput._primary
                      : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }).toList(),
          );
        }),
        if (widget.freeSolo && _customController != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    style: TextStyle(color: Color(AppColors.textColor)),
                    controller: _customController,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      fillColor: Color(AppColors.surfaceColor),
                      filled: true,
                      isDense: true,
                      hintText: widget.freeSoloHint ?? 'Add your own',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _submitCustom(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _submitCustom,
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    backgroundColor: SelectableChipInput._primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        if (widget.emptySelectionWarning != null)
          Obx(
            () => widget.selected.isEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      widget.emptySelectionWarning!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
      ],
    );
  }
}
