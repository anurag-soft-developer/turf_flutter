import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/config/constants.dart';
import '../football_scoring_controller.dart';
import '../model/football_match_event_model.dart';
import '../util/football_scoring_helpers.dart';

typedef FootballEventTap = void Function(FootballEventKind kind);

class FootballActionButtons extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Obx(() {
      final busy = controller.isSendingUpdate.value;
      final canUndo = controller.canUndoFootballEvent;
      final canRedo = controller.canRedoFootballEvent.value;
      final completing = controller.isCompletingFootballMatch.value;
      final changingInning = controller.isChangingInning.value;
      final canChangeInning = controller.canChangeFootballInning;

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
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: busy || !canUndo ? null : onUndo,
                  icon: const Icon(Icons.undo, size: 18),
                  label: const Text('Undo'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: busy || !canRedo ? null : onRedo,
                  icon: const Icon(Icons.redo, size: 18),
                  label: const Text('Redo'),
                ),
              ),
            ],
          ),
          if (onChangeInning != null && canChangeInning) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: busy || changingInning ? null : onChangeInning,
              icon: changingInning
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.swap_horiz),
              label: Text(
                changingInning ? 'Starting innings…' : 'Start next innings',
              ),
            ),
          ],
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: busy || completing ? null : onComplete,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              backgroundColor: const Color(AppColors.primaryColor),
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
      );
    });
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(AppColors.dividerColor)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: enabled
                    ? const Color(AppColors.primaryColor)
                    : Colors.grey,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: enabled
                      ? const Color(AppColors.textColor)
                      : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
