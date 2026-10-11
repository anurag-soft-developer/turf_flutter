import 'package:flutter/material.dart';

import '../../../shared/numeric_stepper_field.dart';
import '../../../match_up/team_logo.dart';
import '../../../../core/config/constants.dart';
import '../../../../match_up/model/team_match_model.dart';

/// Pre-session UI: pick batting team, overs, then start scoring.
class CricketStartSessionPanel extends StatelessWidget {
  const CricketStartSessionPanel({
    super.key,
    required this.match,
    required this.battingTeamId,
    required this.onBattingTeamIdChanged,
    required this.maxOversController,
    required this.onMaxOversChanged,
    required this.powerplayOversController,
    required this.onPowerplayOversChanged,
    required this.powerplayMax,
    required this.minOvers,
    required this.maxOversLimit,
    required this.isStarting,
    required this.canStart,
    required this.errorText,
    required this.onStart,
  });

  final TeamMatchModel match;
  final String battingTeamId;
  final ValueChanged<String> onBattingTeamIdChanged;
  final TextEditingController maxOversController;
  final VoidCallback onMaxOversChanged;
  final TextEditingController powerplayOversController;
  final VoidCallback onPowerplayOversChanged;
  final int powerplayMax;
  final int minOvers;
  final int maxOversLimit;
  final bool isStarting;
  final bool canStart;
  final String? errorText;
  final VoidCallback onStart;

  static const Color _borderMuted = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    final primary = const Color(AppColors.primaryColor);
    final fromId = match.fromTeamHelper.getId() ?? '';
    final toId = match.toTeamHelper.getId() ?? '';
    final fromName = match.fromTeamHelper.getDisplayName();
    final toName = match.toTeamHelper.getDisplayName();
    final fromLogo = match.fromTeamHelper.getSubsetModel()?.logo ?? '';
    final toLogo = match.toTeamHelper.getSubsetModel()?.logo ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Select the batting team',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(AppColors.textColor),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _TeamPickTile(
                          label: fromName.isNotEmpty ? fromName : 'Team 1',
                          logoUrl: fromLogo,
                          selected: battingTeamId.isNotEmpty &&
                              battingTeamId == fromId,
                          enabled: fromId.isNotEmpty,
                          onTap: () => onBattingTeamIdChanged(fromId),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TeamPickTile(
                          label: toName.isNotEmpty ? toName : 'Team 2',
                          logoUrl: toLogo,
                          selected: battingTeamId.isNotEmpty &&
                              battingTeamId == toId,
                          enabled: toId.isNotEmpty,
                          onTap: () => onBattingTeamIdChanged(toId),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Overs / innings',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(AppColors.textColor),
                    ),
                  ),
                  const SizedBox(height: 12),
                  NumericStepperField(
                    controller: maxOversController,
                    min: minOvers,
                    max: maxOversLimit,
                    primaryColor: primary,
                    onChanged: onMaxOversChanged,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$minOvers–$maxOversLimit',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Powerplay overs',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(AppColors.textColor),
                    ),
                  ),
                  const SizedBox(height: 12),
                  NumericStepperField(
                    controller: powerplayOversController,
                    min: 0,
                    max: powerplayMax,
                    primaryColor: primary,
                    onChanged: onPowerplayOversChanged,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    powerplayMax > 0
                        ? 'Opening overs with a restricted field. 0 turns it off.'
                        : 'Set innings overs first.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  if (errorText != null && errorText!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      errorText!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: Color(AppColors.errorColor),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: SizedBox(
              height: 52,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (isStarting || !canStart) ? null : onStart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(AppColors.primaryColor),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade600,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isStarting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Start',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TeamPickTile extends StatelessWidget {
  const _TeamPickTile({
    required this.label,
    required this.logoUrl,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final String logoUrl;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = const Color(AppColors.primaryColor);

    return Material(
      color: selected ? primary.withValues(alpha: 0.08) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: !enabled
                  ? Colors.grey.shade300
                  : selected
                      ? primary
                      : CricketStartSessionPanel._borderMuted,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Opacity(
                opacity: enabled ? 1 : 0.45,
                child: TeamLogo(url: logoUrl, size: 48),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                  height: 1.25,
                  color: !enabled
                      ? Colors.grey.shade500
                      : const Color(AppColors.textColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
