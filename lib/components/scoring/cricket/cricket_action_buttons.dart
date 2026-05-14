import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/config/constants.dart';
import '../../../scoring/scoring_controller.dart';

/// Bottom action panel with the per-delivery outcome buttons
/// (Dot / Run / Wide / No-ball / Wicket).
///
/// Self-observes [ScoringController.isSendingUpdate] to disable the buttons
/// while a request is in flight.
class CricketActionButtons extends StatefulWidget {
  const CricketActionButtons({
    super.key,
    required this.controller,
    required this.onDot,
    required this.onRun,
    required this.onWide,
    required this.onNoBall,
    required this.onWicket,
    required this.onUndo,
    required this.onRedo,
  });

  final ScoringController controller;
  final VoidCallback onDot;
  final VoidCallback onRun;
  final VoidCallback onWide;
  final VoidCallback onNoBall;
  final VoidCallback onWicket;
  final VoidCallback onUndo;
  final VoidCallback onRedo;

  @override
  State<CricketActionButtons> createState() => _CricketActionButtonsState();
}

class _CricketActionButtonsState extends State<CricketActionButtons> {
  static const double _gap = 8;
  static const int _columns = 3;
  static const double _tileHeight = 44;
  static const Duration _panelAnimation = Duration(milliseconds: 220);

  bool _expanded = true;

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final disabled = widget.controller.isSendingUpdate.value;
      final canUndo = widget.controller.cricketOvers.any(
        (over) => over.ballEvents.isNotEmpty,
      );
      final canRedo = widget.controller.canRedoCricketBall.value;

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(AppColors.dividerColor).withValues(alpha: 0.85),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 3,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(AppColors.primaryColor),
                    Color(AppColors.secondaryColor),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(14, 12, 14, _expanded ? 14 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _toggleExpanded,
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Icon(
                              Icons.sports_cricket_rounded,
                              size: 18,
                              color: const Color(
                                AppColors.primaryColor,
                              ).withValues(alpha: 0.9),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Record delivery',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Color(AppColors.textColor),
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  if (!_expanded)
                                    Text(
                                      'Tap to show scoring controls',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(
                                          AppColors.textSecondaryColor,
                                        ).withValues(alpha: 0.95),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            _IconToggleButton(
                              icon: _expanded
                                  ? Icons.keyboard_arrow_down_rounded
                                  : Icons.keyboard_arrow_up_rounded,
                              tooltip: _expanded ? 'Minimize' : 'Maximize',
                              onTap: _toggleExpanded,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  AnimatedSize(
                    duration: _panelAnimation,
                    curve: Curves.easeInOutCubic,
                    alignment: Alignment.topCenter,
                    clipBehavior: Clip.hardEdge,
                    child: _expanded
                        ? Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final cellWidth =
                                        (constraints.maxWidth -
                                            _gap * (_columns - 1)) /
                                        _columns;

                                    Widget tile({
                                      required String label,
                                      required IconData icon,
                                      required VoidCallback? onTap,
                                      required Color accent,
                                    }) {
                                      return SizedBox(
                                        width: cellWidth,
                                        height: _tileHeight,
                                        child: _ActionTile(
                                          label: label,
                                          icon: icon,
                                          onTap: onTap,
                                          accent: accent,
                                        ),
                                      );
                                    }

                                    return Column(
                                      children: [
                                        Row(
                                          children: [
                                            tile(
                                              label: 'Dot',
                                              icon: Icons
                                                  .fiber_manual_record_rounded,
                                              onTap: disabled
                                                  ? null
                                                  : widget.onDot,
                                              accent: const Color(
                                                AppColors.textSecondaryColor,
                                              ),
                                            ),
                                            const SizedBox(width: _gap),
                                            tile(
                                              label: 'Run',
                                              icon: Icons
                                                  .add_circle_outline_rounded,
                                              onTap: disabled
                                                  ? null
                                                  : widget.onRun,
                                              accent: const Color(
                                                AppColors.primaryColor,
                                              ),
                                            ),
                                            const SizedBox(width: _gap),
                                            tile(
                                              label: 'Wide',
                                              icon: Icons.swap_horiz_rounded,
                                              onTap: disabled
                                                  ? null
                                                  : widget.onWide,
                                              accent: const Color(
                                                AppColors.accentColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: _gap),
                                        Row(
                                          children: [
                                            tile(
                                              label: 'No ball',
                                              icon: Icons.warning_amber_rounded,
                                              onTap: disabled
                                                  ? null
                                                  : widget.onNoBall,
                                              accent: const Color(0xFFEA580C),
                                            ),
                                            const SizedBox(width: _gap),
                                            tile(
                                              label: 'Wicket',
                                              icon:
                                                  Icons.sports_cricket_rounded,
                                              onTap: disabled
                                                  ? null
                                                  : widget.onWicket,
                                              accent: const Color(
                                                AppColors.errorColor,
                                              ),
                                            ),
                                            const SizedBox(width: _gap),
                                            SizedBox(width: cellWidth),
                                          ],
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: _gap),
                                Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: const Color(
                                    AppColors.dividerColor,
                                  ).withValues(alpha: 0.85),
                                ),
                                const SizedBox(height: _gap),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _ToolbarButton(
                                      label: 'Undo',
                                      icon: Icons.undo_rounded,
                                      onTap: disabled || !canUndo
                                          ? null
                                          : widget.onUndo,
                                    ),
                                    _ToolbarButton(
                                      label: 'Redo',
                                      icon: Icons.redo_rounded,
                                      onTap: disabled || !canRedo
                                          ? null
                                          : widget.onRedo,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        : const SizedBox(width: double.infinity),
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

class _IconToggleButton extends StatelessWidget {
  const _IconToggleButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: const Color(AppColors.backgroundColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: const Color(AppColors.dividerColor).withValues(alpha: 0.85),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(
              icon,
              size: 20,
              color: const Color(AppColors.textColor),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Tooltip(
      message: label,
      child: Material(
        color: enabled
            ? const Color(AppColors.backgroundColor)
            : const Color(AppColors.backgroundColor).withValues(alpha: 0.65),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: const Color(
              AppColors.dividerColor,
            ).withValues(alpha: enabled ? 0.85 : 0.45),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: enabled
                      ? const Color(AppColors.textColor)
                      : const Color(AppColors.textSecondaryColor),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                    color: enabled
                        ? const Color(AppColors.textColor)
                        : const Color(AppColors.textSecondaryColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.accent,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Material(
      color: enabled
          ? accent.withValues(alpha: 0.07)
          : const Color(AppColors.backgroundColor).withValues(alpha: 0.7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: enabled
              ? accent.withValues(alpha: 0.18)
              : const Color(AppColors.dividerColor).withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: enabled
                    ? accent
                    : const Color(AppColors.textSecondaryColor),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                    color: enabled
                        ? const Color(AppColors.textColor)
                        : const Color(AppColors.textSecondaryColor),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
