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
  });

  final VoidCallback onReject;
  final VoidCallback onAccept;
  final bool isRejecting;
  final bool isAccepting;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final busy = isRejecting || isAccepting;
    final canInteract = enabled && !busy;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: canInteract ? onReject : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(AppColors.textColor),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isRejecting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Reject',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: canInteract ? onAccept : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(AppColors.primaryColor),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: isAccepting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Accept',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }
}
