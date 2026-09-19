import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
                  _OversStepper(
                    controller: maxOversController,
                    minOvers: minOvers,
                    maxOversLimit: maxOversLimit,
                    primary: primary,
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

class _OversStepper extends StatelessWidget {
  const _OversStepper({
    required this.controller,
    required this.minOvers,
    required this.maxOversLimit,
    required this.primary,
    required this.onChanged,
  });

  final TextEditingController controller;
  final int minOvers;
  final int maxOversLimit;
  final Color primary;
  final VoidCallback onChanged;

  int get _current {
    final n = int.tryParse(controller.text.trim());
    return n ?? minOvers;
  }

  void _set(int value) {
    final clamped = value.clamp(minOvers, maxOversLimit);
    controller.text = '$clamped';
    controller.selection = TextSelection.collapsed(
      offset: controller.text.length,
    );
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final value = _current;
    final canDec = value > minOvers;
    final canInc = value < maxOversLimit;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: Icons.remove_rounded,
            enabled: canDec,
            onTap: () => _set(value - 1),
          ),
          SizedBox(
            width: 56,
            child: TextField(
              controller: controller,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => onChanged(),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(AppColors.textColor),
              ),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            enabled: canInc,
            onTap: () => _set(value + 1),
            color: primary,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 40,
        height: 44,
        child: Icon(
          icon,
          size: 20,
          color: enabled
              ? (color ?? const Color(AppColors.textSecondaryColor))
              : Colors.grey.shade300,
        ),
      ),
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
