import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/config/constants.dart';
import '../../../scoring/cricket/cricket_scoring_controller.dart';
import '../../../scoring/cricket/model/cricket_ball_event_model.dart';

/// Modern “this over” strip: label + over runs + ball sequence with empty slots.
class CricketThisOverStrip extends StatelessWidget {
  const CricketThisOverStrip({
    super.key,
    required this.controller,
    required this.innings,
    this.onTap,
    this.embedded = false,
  });

  final CricketScoringController controller;
  final int innings;

  /// Optional — e.g. open the overs history sheet.
  final VoidCallback? onTap;

  /// Skip card chrome so this can sit inside another card (bowler + this over).
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final overs = controller.cricketOvers
          .where((o) => o.innings == innings)
          .toList();
      final current = _latestOver(overs);
      final balls = current?.ballEvents ?? const <CricketBallEvent>[];
      final overNumber = current?.overAfter;
      final overRuns = _runsInOver(balls);
      final legalBowled = balls.where((b) => b.isLegalDelivery).length;
      final remainingSlots = (6 - legalBowled).clamp(0, 6);

      final body = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text(
                'This over',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(AppColors.textColor),
                ),
              ),
              if (overNumber != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(
                      AppColors.primaryColor,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '#$overNumber',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(AppColors.primaryColor),
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (!embedded) ...[
                Text(
                  '$overRuns',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: -0.5,
                    color: Color(AppColors.textColor),
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'runs',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(AppColors.textSecondaryColor),
                  ),
                ),
              ],
              if (onTap != null) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Colors.grey.shade400,
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < balls.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  _BallSlot(
                    label: _ballDeliveryLabel(balls[i]),
                    isWicket: balls[i].isWicket,
                    isExtra: !balls[i].isLegalDelivery,
                  ),
                ],
                for (var i = 0; i < remainingSlots; i++) ...[
                  if (balls.isNotEmpty || i > 0) const SizedBox(width: 6),
                  const _BallSlot.empty(),
                ],
              ],
            ),
          ),
        ],
      );

      if (embedded) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: body,
          ),
        );
      }

      return Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(
                  AppColors.dividerColor,
                ).withValues(alpha: 0.75),
              ),
            ),
            child: body,
          ),
        ),
      );
    });
  }
}

CricketOverEvent? _latestOver(List<CricketOverEvent> overs) {
  CricketOverEvent? latest;
  for (final over in overs) {
    if (latest == null ||
        over.overAfter > latest.overAfter ||
        (over.overAfter == latest.overAfter &&
            over.sequence > latest.sequence)) {
      latest = over;
    }
  }
  return latest;
}

int _runsInOver(List<CricketBallEvent> balls) {
  var sum = 0;
  for (final ball in balls) {
    sum += ball.totalRunsOnDelivery;
  }
  return sum;
}

String _ballDeliveryLabel(CricketBallEvent ball) {
  if (ball.isWicket) return 'W';
  if (ball.extrasNoBall) {
    return ball.runsOffBat > 0 ? '${ball.runsOffBat}Nb' : 'Nb';
  }
  if (ball.extrasWide > 0) {
    return ball.totalRunsOnDelivery > 1
        ? '${ball.totalRunsOnDelivery}Wd'
        : 'Wd';
  }
  if (ball.extrasBye > 0) {
    return '${ball.extrasBye}B';
  }
  if (ball.extrasLegBye > 0) {
    return '${ball.extrasLegBye}Lb';
  }
  if (ball.runsOffBat == 0 && ball.totalRunsOnDelivery == 0) {
    return '·';
  }
  return '${ball.runsOffBat}';
}

class _BallSlot extends StatelessWidget {
  const _BallSlot({
    required this.label,
    required this.isWicket,
    required this.isExtra,
  }) : empty = false;

  const _BallSlot.empty()
      : label = '',
        isWicket = false,
        isExtra = false,
        empty = true;

  final String label;
  final bool isWicket;
  final bool isExtra;
  final bool empty;

  @override
  Widget build(BuildContext context) {
    if (empty) {
      return Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(AppColors.dividerColor),
            width: 1.5,
          ),
        ),
      );
    }

    final Color background;
    final Color foreground;
    if (isWicket) {
      background = const Color(0xFFFFE8E8);
      foreground = const Color(0xFFB42318);
    } else if (isExtra) {
      background = const Color(0xFFFFF4E5);
      foreground = const Color(0xFFB54708);
    } else {
      background = const Color(AppColors.primaryColor).withValues(alpha: 0.1);
      foreground = const Color(AppColors.textColor);
    }

    return Container(
      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: Border.all(color: foreground.withValues(alpha: 0.2)),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}
