import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/config/constants.dart';
import '../football_scoring_controller.dart';
import '../util/football_scoring_helpers.dart';

class FootballMatchTimer extends StatefulWidget {
  const FootballMatchTimer({
    super.key,
    required this.controller,
    this.enabled = true,
  });

  final FootballScoringController controller;
  final bool enabled;

  @override
  State<FootballMatchTimer> createState() => _FootballMatchTimerState();
}

class _FootballMatchTimerState extends State<FootballMatchTimer> {
  Timer? _tick;
  int _trackedInnings = 0;
  bool _autoPauseInFlight = false;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  void _onTick() {
    if (!mounted) return;
    final fs = widget.controller.footballMatch.value?.footballState;
    if (fs == null) return;

    if (fs.currentInnings != _trackedInnings) {
      _trackedInnings = fs.currentInnings;
      _autoPauseInFlight = false;
    }

    if (widget.enabled &&
        !_autoPauseInFlight &&
        shouldAutoPauseFootballTimer(fs)) {
      _autoPauseInFlight = true;
      unawaited(
        widget.controller.pauseFootballTimer().whenComplete(() {
          if (mounted) _autoPauseInFlight = false;
        }),
      );
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final fs = widget.controller.footballMatch.value?.footballState;
      if (fs == null) {
        return const SizedBox.shrink();
      }

      _trackedInnings = fs.currentInnings;

      final inningElapsed = footballTimerElapsedMs(fs);
      final totalElapsed = footballTotalTimerElapsedMs(fs);
      final inningLabel = formatFootballTimer(inningElapsed);
      final totalLabel = formatFootballTimer(totalElapsed);
      final paused = fs.isTimerPaused;
      final busy = widget.controller.isUpdatingTimer.value;
      final showTotal = fs.totalTimerElapsedMs > 0 || fs.currentInnings > 1;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(AppColors.dividerColor)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.timer_outlined,
              size: 22,
              color: Color(AppColors.primaryColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    footballInningsTimerLabel(fs),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(AppColors.textSecondaryColor),
                    ),
                  ),
                  Text(
                    inningLabel,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (showTotal) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Total $totalLabel',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(AppColors.textSecondaryColor),
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (widget.enabled) ...[
              IconButton.filledTonal(
                onPressed: busy
                    ? null
                    : () async {
                        if (paused) {
                          await widget.controller.resumeFootballTimer();
                        } else {
                          await widget.controller.pauseFootballTimer();
                        }
                      },
                icon: Icon(paused ? Icons.play_arrow : Icons.pause),
                tooltip: paused ? 'Resume' : 'Pause',
              ),
            ] else
              Text(
                paused ? 'Paused' : 'Running',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(AppColors.textSecondaryColor),
                ),
              ),
          ],
        ),
      );
    });
  }
}
