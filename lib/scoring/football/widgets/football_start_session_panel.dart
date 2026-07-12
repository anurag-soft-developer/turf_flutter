import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/config/constants.dart';

class FootballStartSessionPanel extends StatelessWidget {
  const FootballStartSessionPanel({
    super.key,
    required this.metaPending,
    required this.matchMinuteController,
    required this.isStarting,
    required this.canStart,
    required this.errorText,
    required this.onStart,
    required this.onMinuteChanged,
    this.minMinutes = 5,
    this.maxMinutes = 90,
  });

  final bool metaPending;
  final TextEditingController matchMinuteController;
  final bool isStarting;
  final bool canStart;
  final String? errorText;
  final VoidCallback onStart;
  final VoidCallback onMinuteChanged;
  final int minMinutes;
  final int maxMinutes;

  static const Color _borderMuted = Color(0xFFE5E7EB);

  int? get _parsedMinutes {
    final t = matchMinuteController.text.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t);
  }

  void _setMinutes(int value) {
    final clamped = value.clamp(minMinutes, maxMinutes);
    matchMinuteController.text = '$clamped';
    matchMinuteController.selection = TextSelection.collapsed(
      offset: matchMinuteController.text.length,
    );
    onMinuteChanged();
  }

  void _nudge(int delta) {
    final current = _parsedMinutes ?? (delta > 0 ? minMinutes : maxMinutes);
    _setMinutes(current + delta);
  }

  @override
  Widget build(BuildContext context) {
    if (metaPending) {
      return const Center(child: CircularProgressIndicator());
    }

    final primary = const Color(AppColors.primaryColor);
    final minutes = _parsedMinutes;
    final inRange =
        minutes != null && minutes >= minMinutes && minutes <= maxMinutes;
    final footerHint = canStart
        ? 'Halves pause automatically at half of this duration.'
        : 'Enter match length ($minMinutes–$maxMinutes min).';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.sports_soccer_rounded,
                        size: 40,
                        color: primary.withValues(alpha: 0.95),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Football scoring',
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
                      'Set the total match length, then start recording events.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _borderMuted),
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
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 22,
                              color: primary.withValues(alpha: 0.9),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Match length',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: Color(AppColors.textColor),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Total minutes for both halves ($minMinutes–$maxMinutes).',
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
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            _StepButton(
                              icon: Icons.remove_rounded,
                              enabled: !isStarting &&
                                  (minutes == null || minutes > minMinutes),
                              onTap: () => _nudge(-5),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: matchMinuteController,
                                enabled: !isStarting,
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(2),
                                ],
                                onChanged: (_) => onMinuteChanged(),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Color(AppColors.textColor),
                                  height: 1.1,
                                ),
                                decoration: InputDecoration(
                                  hintText: '$maxMinutes',
                                  hintStyle: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey.shade400,
                                  ),
                                  suffixText: 'min',
                                  suffixStyle: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(AppColors.textSecondaryColor),
                                  ),
                                  filled: true,
                                  fillColor:
                                      const Color(AppColors.backgroundColor),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        const BorderSide(color: _borderMuted),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: inRange
                                          ? _borderMuted
                                          : const Color(AppColors.errorColor)
                                              .withValues(alpha: 0.55),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: inRange
                                          ? primary
                                          : const Color(AppColors.errorColor),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            _StepButton(
                              icon: Icons.add_rounded,
                              enabled: !isStarting &&
                                  (minutes == null || minutes < maxMinutes),
                              onTap: () => _nudge(5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          inRange
                              ? 'Each half auto-pauses at ${minutes ~/ 2} min.'
                              : 'Enter a value between $minMinutes and $maxMinutes.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            color: inRange
                                ? Colors.grey.shade600
                                : const Color(AppColors.errorColor),
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
                    onPressed: (isStarting || !canStart) ? null : onStart,
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
                      disabledBackgroundColor: Colors.grey.shade300,
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

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = const Color(AppColors.primaryColor);
    return Material(
      color: enabled
          ? primary.withValues(alpha: 0.1)
          : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 48,
          height: 56,
          child: Icon(
            icon,
            color: enabled ? primary : Colors.grey.shade400,
          ),
        ),
      ),
    );
  }
}
