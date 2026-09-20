import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/config/constants.dart';

/// Pre-session UI: set match length, then start football scoring.
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
    this.minMinutes = 2,
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

  @override
  Widget build(BuildContext context) {
    if (metaPending) {
      return const Center(child: CircularProgressIndicator());
    }

    final primary = const Color(AppColors.primaryColor);

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
                    'Match length',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(AppColors.textColor),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _MinutesStepper(
                    controller: matchMinuteController,
                    minMinutes: minMinutes,
                    maxMinutes: maxMinutes,
                    step: 5,
                    primary: primary,
                    onChanged: onMinuteChanged,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$minMinutes–$maxMinutes min',
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

class _MinutesStepper extends StatelessWidget {
  const _MinutesStepper({
    required this.controller,
    required this.minMinutes,
    required this.maxMinutes,
    required this.step,
    required this.primary,
    required this.onChanged,
  });

  final TextEditingController controller;
  final int minMinutes;
  final int maxMinutes;
  final int step;
  final Color primary;
  final VoidCallback onChanged;

  int get _current {
    final n = int.tryParse(controller.text.trim());
    return n ?? minMinutes;
  }

  void _set(int value) {
    final clamped = value.clamp(minMinutes, maxMinutes);
    controller.text = '$clamped';
    controller.selection = TextSelection.collapsed(
      offset: controller.text.length,
    );
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final value = _current;
    final canDec = value > minMinutes;
    final canInc = value < maxMinutes;

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
            onTap: () => _set(value - step),
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
            onTap: () => _set(value + step),
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
