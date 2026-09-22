import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/config/constants.dart';
import '../../../scoring/cricket/cricket_scoring_controller.dart';

/// Thumb-first scoring keypad: 0–6 runs, Wide / No-ball / Wicket, Undo / Redo.
///
/// Self-observes [CricketScoringController.isSendingUpdate] to disable buttons
/// while a request is in flight.
class CricketActionButtons extends StatelessWidget {
  const CricketActionButtons({
    super.key,
    required this.controller,
    required this.onRuns,
    required this.onWide,
    required this.onNoBall,
    required this.onWicket,
    required this.onSubstitute,
    required this.onUndo,
    required this.onRedo,
  });

  final CricketScoringController controller;

  /// Called with runs off the bat (0 = dot).
  final ValueChanged<int> onRuns;
  final VoidCallback onWide;
  final VoidCallback onNoBall;
  final VoidCallback onWicket;
  final VoidCallback onSubstitute;
  final VoidCallback onUndo;
  final VoidCallback onRedo;

  static const double _gap = 8;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final disabled = controller.isSendingUpdate.value;
      final canUndo = controller.cricketOvers.any(
        (over) => over.events.isNotEmpty,
      );
      final canRedo = controller.canRedoCricketBall.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final cellW = (constraints.maxWidth - _gap * 3) / 4;
              final cellH = 48.0;

              Widget runKey(int runs) {
                return SizedBox(
                  width: cellW,
                  height: cellH,
                  child: _RunKey(
                    label: '$runs',
                    emphasize: runs == 4 || runs == 6,
                    onTap: disabled ? null : () => onRuns(runs),
                  ),
                );
              }

              return Column(
                children: [
                  Row(
                    children: [
                      runKey(0),
                      const SizedBox(width: _gap),
                      runKey(1),
                      const SizedBox(width: _gap),
                      runKey(2),
                      const SizedBox(width: _gap),
                      runKey(3),
                    ],
                  ),
                  const SizedBox(height: _gap),
                  Row(
                    children: [
                      runKey(4),
                      const SizedBox(width: _gap),
                      runKey(5),
                      const SizedBox(width: _gap),
                      runKey(6),
                      const SizedBox(width: _gap),
                      SizedBox(width: cellW),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: _gap),
          Row(
            children: [
              Expanded(
                child: _ActionKey(
                  label: 'Wd',
                  accent: const Color(AppColors.accentColor),
                  onTap: disabled ? null : onWide,
                ),
              ),
              const SizedBox(width: _gap),
              Expanded(
                child: _ActionKey(
                  label: 'Nb',
                  accent: const Color(0xFFEA580C),
                  onTap: disabled ? null : onNoBall,
                ),
              ),
              const SizedBox(width: _gap),
              Expanded(
                child: _ActionKey(
                  label: 'W',
                  accent: const Color(AppColors.errorColor),
                  onTap: disabled ? null : onWicket,
                ),
              ),
              const SizedBox(width: _gap),
              Expanded(
                child: _ActionKey(
                  label: 'Sub',
                  accent: const Color(AppColors.primaryColor),
                  onTap: disabled ? null : onSubstitute,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ToolbarKey(
                  label: 'Undo',
                  icon: Icons.undo_rounded,
                  onTap: disabled || !canUndo ? null : onUndo,
                ),
              ),
              const SizedBox(width: _gap),
              Expanded(
                child: _ToolbarKey(
                  label: 'Redo',
                  icon: Icons.redo_rounded,
                  onTap: disabled || !canRedo ? null : onRedo,
                ),
              ),
            ],
          ),
        ],
      );
    });
  }
}

class _RunKey extends StatelessWidget {
  const _RunKey({
    required this.label,
    required this.onTap,
    this.emphasize = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final accent = emphasize
        ? const Color(AppColors.primaryColor)
        : const Color(AppColors.textColor);

    return Material(
      color: enabled
          ? (emphasize
                ? const Color(AppColors.primaryColor).withValues(alpha: 0.1)
                : Colors.white)
          : const Color(AppColors.backgroundColor),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: enabled
              ? accent.withValues(alpha: emphasize ? 0.35 : 0.12)
              : const Color(AppColors.dividerColor).withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: enabled
                  ? accent
                  : const Color(AppColors.textSecondaryColor),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionKey extends StatelessWidget {
  const _ActionKey({
    required this.label,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Material(
      color: enabled
          ? accent.withValues(alpha: 0.1)
          : const Color(AppColors.backgroundColor),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: enabled
              ? accent.withValues(alpha: 0.28)
              : const Color(AppColors.dividerColor).withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 48,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: enabled
                    ? accent
                    : const Color(AppColors.textSecondaryColor),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolbarKey extends StatelessWidget {
  const _ToolbarKey({
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
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
