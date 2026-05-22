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

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final fs = widget.controller.footballMatch.value?.footballState;
      if (fs == null) {
        return const SizedBox.shrink();
      }

      final elapsed = footballTimerElapsedMs(fs);
      final label = formatFootballTimer(elapsed);
      final paused = fs.isTimerPaused;
      final busy = widget.controller.isUpdatingTimer.value;

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
                  const Text(
                    'Match timer',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(AppColors.textSecondaryColor),
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
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
