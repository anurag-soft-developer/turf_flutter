import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/config/constants.dart';
import '../football_scoring_controller.dart';
import '../model/football_match_event_model.dart';
import '../util/football_scoring_helpers.dart';

typedef FootballEventTap = void Function(FootballEventKind kind);

/// Bottom action panel for football events (Goal / Card / Sub / …).
///
/// Collapsible like [CricketActionButtons]. Self-observes busy flags on
/// [FootballScoringController].
class FootballActionButtons extends StatefulWidget {
  const FootballActionButtons({
    super.key,
    required this.controller,
    required this.onEventTap,
    required this.onUndo,
    required this.onRedo,
    required this.onComplete,
    this.onChangeInning,
  });

  final FootballScoringController controller;
  final FootballEventTap onEventTap;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onComplete;
  final VoidCallback? onChangeInning;

  static const List<FootballEventKind> _kinds = [
    FootballEventKind.goal,
    FootballEventKind.ownGoal,
    FootballEventKind.yellowCard,
    FootballEventKind.redCard,
    FootballEventKind.substitution,
    FootballEventKind.penaltyScored,
    FootballEventKind.penaltyMissed,
  ];

  @override
  State<FootballActionButtons> createState() => _FootballActionButtonsState();
}

class _FootballActionButtonsState extends State<FootballActionButtons> {
  static const Duration _panelAnimation = Duration(milliseconds: 220);

  Timer? _timerTick;
  bool _expanded = true;

  @override
  void initState() {
    super.initState();
    _timerTick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timerTick?.cancel();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final busy = widget.controller.isSendingUpdate.value;
      final canUndo = widget.controller.canUndoFootballEvent;
      final canRedo = widget.controller.canRedoFootballEvent.value;
      final completing = widget.controller.isCompletingFootballMatch.value;
      final changingInning = widget.controller.isChangingInning.value;
      final fs = widget.controller.footballMatch.value?.footballState;
      final showStartNextInning = fs != null &&
          widget.onChangeInning != null &&
          shouldShowFootballStartNextInning(fs);
      final showEndMatch = fs != null && canEndFootballMatch(fs);

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
                              Icons.sports_soccer_rounded,
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
                                    'Record event',
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
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final kind
                                        in FootballActionButtons._kinds)
                                      _EventChip(
                                        label: eventKindLabel(kind),
                                        icon: eventKindIcon(kind),
                                        enabled: !busy,
                                        onTap: () =>
                                            widget.onEventTap(kind),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: const Color(
                                    AppColors.dividerColor,
                                  ).withValues(alpha: 0.85),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _ToolbarButton(
                                        label: 'Undo',
                                        icon: Icons.undo_rounded,
                                        onTap: busy || !canUndo
                                            ? null
                                            : widget.onUndo,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _ToolbarButton(
                                        label: 'Redo',
                                        icon: Icons.redo_rounded,
                                        onTap: busy || !canRedo
                                            ? null
                                            : widget.onRedo,
                                      ),
                                    ),
                                  ],
                                ),
                                if (showStartNextInning) ...[
                                  const SizedBox(height: 8),
                                  OutlinedButton.icon(
                                    onPressed: busy || changingInning
                                        ? null
                                        : widget.onChangeInning,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(
                                        AppColors.textColor,
                                      ),
                                      disabledForegroundColor: const Color(
                                        AppColors.textSecondaryColor,
                                      ),
                                      side: BorderSide(
                                        color: const Color(
                                          AppColors.dividerColor,
                                        ).withValues(alpha: 0.85),
                                      ),
                                      minimumSize: const Size.fromHeight(44),
                                    ),
                                    icon: changingInning
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.swap_horiz),
                                    label: Text(
                                      changingInning
                                          ? 'Starting innings…'
                                          : 'Start next innings',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(AppColors.textColor),
                                      ),
                                    ),
                                  ),
                                ],
                                if (showEndMatch) ...[
                                  const SizedBox(height: 8),
                                  FilledButton.icon(
                                    onPressed: busy || completing
                                        ? null
                                        : widget.onComplete,
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size.fromHeight(44),
                                      backgroundColor: const Color(
                                        AppColors.primaryColor,
                                      ),
                                      foregroundColor: Colors.white,
                                      disabledForegroundColor:
                                          Colors.white70,
                                    ),
                                    icon: completing
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.flag_outlined),
                                    label: Text(
                                      completing ? 'Ending…' : 'End match',
                                    ),
                                  ),
                                ],
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
              mainAxisAlignment: MainAxisAlignment.center,
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

class _EventChip extends StatelessWidget {
  const _EventChip({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = const Color(AppColors.primaryColor);

    return Material(
      color: enabled
          ? accent.withValues(alpha: 0.07)
          : const Color(AppColors.backgroundColor).withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: enabled
                  ? accent.withValues(alpha: 0.18)
                  : const Color(AppColors.dividerColor).withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: enabled
                    ? accent
                    : const Color(AppColors.textSecondaryColor),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: enabled
                      ? const Color(AppColors.textColor)
                      : const Color(AppColors.textSecondaryColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
