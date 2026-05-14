import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/config/constants.dart';

/// Pre-session UI: pick batting team, overs, then start scoring.
class CricketStartSessionPanel extends StatelessWidget {
  const CricketStartSessionPanel({
    super.key,
    required this.metaPending,
    required this.fromTeamName,
    required this.toTeamName,
    required this.fromTeamId,
    required this.toTeamId,
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

  final bool metaPending;
  final String fromTeamName;
  final String toTeamName;
  final String fromTeamId;
  final String toTeamId;
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

  static const Color borderMuted = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    if (metaPending) {
      return const Center(child: CircularProgressIndicator());
    }

    final primary = const Color(AppColors.primaryColor);
    final footerHint = canStart
        ? 'You can start scoring once everything above looks correct.'
        : 'Select who bats first and enter overs ($minOvers–$maxOversLimit).';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SessionHeader(primary: primary),
                const SizedBox(height: 22),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderMuted),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SectionLabel(
                          icon: Icons.groups_2_rounded,
                          title: 'Who bats first?',
                          subtitle:
                              'Bowling is assigned to the other side automatically.',
                          primary: primary,
                        ),
                        const SizedBox(height: 14),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final narrow = constraints.maxWidth < 340;
                            final team1 = _TeamPickTile(
                              label: fromTeamName.isNotEmpty
                                  ? fromTeamName
                                  : 'Team 1',
                              selected: battingTeamId.isNotEmpty &&
                                  battingTeamId == fromTeamId,
                              enabled: fromTeamId.isNotEmpty,
                              onTap: () =>
                                  onBattingTeamIdChanged(fromTeamId),
                            );
                            final team2 = _TeamPickTile(
                              label: toTeamName.isNotEmpty
                                  ? toTeamName
                                  : 'Team 2',
                              selected: battingTeamId.isNotEmpty &&
                                  battingTeamId == toTeamId,
                              enabled: toTeamId.isNotEmpty,
                              onTap: () => onBattingTeamIdChanged(toTeamId),
                            );
                            if (narrow) {
                              return Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  team1,
                                  const SizedBox(height: 10),
                                  team2,
                                ],
                              );
                            }
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: team1),
                                const SizedBox(width: 12),
                                Expanded(child: team2),
                              ],
                            );
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: Divider(height: 1, color: Colors.grey.shade200),
                        ),
                        _SectionLabel(
                          icon: Icons.timer_outlined,
                          title: 'Overs per innings',
                          subtitle:
                              'Each innings is limited to this many overs.',
                          primary: primary,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: maxOversController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (_) => onMaxOversChanged(),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Color(AppColors.textColor),
                          ),
                          decoration: InputDecoration(
                            hintText: 'e.g. 20',
                            filled: true,
                            fillColor: const Color(AppColors.backgroundColor),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: borderMuted),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: borderMuted),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: primary,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Allowed range: $minOvers–$maxOversLimit overs.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  footerHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (errorText != null && errorText!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(AppColors.errorColor)
                          .withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(AppColors.errorColor)
                            .withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 20,
                          color: Color(AppColors.errorColor),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            errorText!,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              color: Color(AppColors.errorColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed:
                        (isStarting || !canStart) ? null : onStart,
                    icon: isStarting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.play_arrow_rounded, size: 26),
                    label: Text(
                      isStarting ? 'Starting…' : 'Start scoring',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(AppColors.primaryColor),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade600,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SessionHeader extends StatelessWidget {
  const _SessionHeader({required this.primary});

  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.sports_cricket_rounded,
            size: 40,
            color: primary.withValues(alpha: 0.95),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Cricket scoring',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            letterSpacing: -0.3,
            color: Color(AppColors.textColor),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Set up this match, then record balls and track the scorecard.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.45,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.primary,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: primary.withValues(alpha: 0.9)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Color(AppColors.textColor),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TeamPickTile extends StatelessWidget {
  const _TeamPickTile({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = const Color(AppColors.primaryColor);

    return Material(
      color: selected
          ? primary.withValues(alpha: 0.1)
          : Colors.white,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: !enabled
                  ? Colors.grey.shade300
                  : selected
                      ? primary
                      : CricketStartSessionPanel.borderMuted,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.groups_rounded,
                size: 22,
                color: !enabled
                    ? Colors.grey.shade400
                    : selected
                        ? primary
                        : Colors.grey.shade600,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 14,
                    height: 1.25,
                    color: !enabled
                        ? Colors.grey.shade500
                        : const Color(AppColors.textColor),
                  ),
                ),
              ),
              if (selected && enabled)
                Icon(
                  Icons.check_circle_rounded,
                  size: 22,
                  color: primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
