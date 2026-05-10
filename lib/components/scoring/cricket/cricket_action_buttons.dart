import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../scoring/scoring_controller.dart';

/// Bottom action panel with the per-delivery outcome buttons
/// (Dot / Run / Wide / No-ball / Wicket).
///
/// Self-observes [ScoringController.isSendingUpdate] to disable the buttons
/// while a request is in flight.
class CricketActionButtons extends StatelessWidget {
  const CricketActionButtons({
    super.key,
    required this.controller,
    required this.onDot,
    required this.onRun,
    required this.onWide,
    required this.onNoBall,
    required this.onWicket,
  });

  final ScoringController controller;
  final VoidCallback onDot;
  final VoidCallback onRun;
  final VoidCallback onWide;
  final VoidCallback onNoBall;
  final VoidCallback onWicket;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final disabled = controller.isSendingUpdate.value;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: _chip('Dot', disabled ? null : onDot)),
              const SizedBox(width: 8),
              Expanded(child: _chip('Run', disabled ? null : onRun)),
              const SizedBox(width: 8),
              Expanded(child: _chip('Wide', disabled ? null : onWide)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _chip('No ball', disabled ? null : onNoBall)),
              const SizedBox(width: 8),
              Expanded(child: _chip('Wicket', disabled ? null : onWicket)),
            ],
          ),
        ],
      );
    });
  }

  Widget _chip(String label, VoidCallback? onTap) {
    return SizedBox(
      height: 42,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          textStyle: const TextStyle(fontSize: 13),
        ),
        child: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
      ),
    );
  }
}
