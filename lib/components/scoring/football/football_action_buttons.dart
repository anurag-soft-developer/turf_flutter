import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/config/constants.dart';
import '../../../scoring/football/football_scoring_controller.dart';
import '../../../scoring/football/model/football_match_event_model.dart';
import '../../../scoring/football/util/football_scoring_helpers.dart';

typedef FootballEventTap = void Function(FootballEventKind kind);

/// Scoring controls for football events (Goal / Card / Sub / …).
///
/// Self-observes busy flags on [FootballScoringController].
class FootballActionButtons extends StatelessWidget {
  const FootballActionButtons({
    super.key,
    required this.controller,
    required this.onEventTap,
    required this.onUndo,
    required this.onRedo,
    required this.onComplete,
    this.onChangeInning,
    this.showPeriodActions = true,
  });

  final FootballScoringController controller;
  final FootballEventTap onEventTap;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onComplete;
  final VoidCallback? onChangeInning;
  final bool showPeriodActions;

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
  Widget build(BuildContext context) {
    return Obx(() {
      final busy = controller.isSendingUpdate.value;
      final canUndo = controller.canUndoFootballEvent;
      final canRedo = controller.canRedoFootballEvent.value;
      final completing = controller.isCompletingFootballMatch.value;
      final changingInning = controller.isChangingInning.value;
      final fs = controller.footballMatch.value?.footballState;
      final showStartNextInning = showPeriodActions &&
          fs != null &&
          onChangeInning != null &&
          shouldShowFootballStartNextInning(fs);
      final showEndMatch =
          showPeriodActions && fs != null && canEndFootballMatch(fs);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final kind in _kinds)
                _EventChip(
                  label: eventKindLabel(kind),
                  icon: eventKindIcon(kind),
                  enabled: !busy,
                  onTap: () => onEventTap(kind),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            thickness: 1,
            color: const Color(AppColors.dividerColor).withValues(alpha: 0.85),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ToolbarButton(
                  label: 'Undo',
                  icon: Icons.undo_rounded,
                  onTap: busy || !canUndo ? null : onUndo,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ToolbarButton(
                  label: 'Redo',
                  icon: Icons.redo_rounded,
                  onTap: busy || !canRedo ? null : onRedo,
                ),
              ),
            ],
          ),
          if (showStartNextInning) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: busy || changingInning ? null : onChangeInning,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(AppColors.textColor),
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
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.swap_horiz),
              label: Text(
                changingInning ? 'Starting innings…' : 'Start next innings',
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
              onPressed: busy || completing ? null : onComplete,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                backgroundColor: const Color(AppColors.primaryColor),
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white70,
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
              label: Text(completing ? 'Ending…' : 'End match'),
            ),
          ],
        ],
      );
    });
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
