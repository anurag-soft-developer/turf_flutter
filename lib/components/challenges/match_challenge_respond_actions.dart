import 'package:flutter/material.dart';

import '../../core/config/constants.dart';

/// Reject + Accept row for a pending incoming team match (same pattern as
/// list cards and the challenge details screen).
class MatchChallengeRespondActions extends StatelessWidget {
  const MatchChallengeRespondActions({
    super.key,
    required this.onReject,
    required this.onAccept,
    this.isRejecting = false,
    this.isAccepting = false,
    this.enabled = true,
    this.compact = false,
  });

  final VoidCallback onReject;
  final VoidCallback onAccept;
  final bool isRejecting;
  final bool isAccepting;
  final bool enabled;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final busy = isRejecting || isAccepting;
    final canInteract = enabled && !busy;
    final verticalPad = compact ? 6.0 : 12.0;
    final gap = compact ? 8.0 : 10.0;
    final radius = compact ? 8.0 : 12.0;
    final fontSize = compact ? 13.0 : 14.0;
    final spinner = compact ? 16.0 : 20.0;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: canInteract ? onReject : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(AppColors.textColor),
              padding: EdgeInsets.symmetric(vertical: verticalPad),
              minimumSize: Size(0, compact ? 34 : 44),
              tapTargetSize: compact
                  ? MaterialTapTargetSize.shrinkWrap
                  : MaterialTapTargetSize.padded,
              visualDensity:
                  compact ? VisualDensity.compact : VisualDensity.standard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius),
              ),
            ),
            child: isRejecting
                ? SizedBox(
                    height: spinner,
                    width: spinner,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Reject',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: fontSize,
                    ),
                  ),
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          child: ElevatedButton(
            onPressed: canInteract ? onAccept : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(AppColors.primaryColor),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: verticalPad),
              minimumSize: Size(0, compact ? 34 : 44),
              tapTargetSize: compact
                  ? MaterialTapTargetSize.shrinkWrap
                  : MaterialTapTargetSize.padded,
              visualDensity:
                  compact ? VisualDensity.compact : VisualDensity.standard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius),
              ),
              elevation: 0,
            ),
            child: isAccepting
                ? SizedBox(
                    height: spinner,
                    width: spinner,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Accept',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: fontSize,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
