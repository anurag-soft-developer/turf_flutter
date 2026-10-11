import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/config/constants.dart';

/// Centered − / value / + control (cricket/football start session, tournaments).
class NumericStepperField extends StatefulWidget {
  const NumericStepperField({
    super.key,
    required this.controller,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 1,
    this.primaryColor,
  });

  final TextEditingController controller;
  final int min;
  final int max;
  final int step;
  final VoidCallback onChanged;
  final Color? primaryColor;

  @override
  State<NumericStepperField> createState() => _NumericStepperFieldState();
}

class _NumericStepperFieldState extends State<NumericStepperField> {
  int get _current {
    final n = int.tryParse(widget.controller.text.trim());
    return n ?? widget.min;
  }

  void _set(int value) {
    final clamped = value.clamp(widget.min, widget.max);
    widget.controller.text = '$clamped';
    widget.controller.selection = TextSelection.collapsed(
      offset: widget.controller.text.length,
    );
    widget.onChanged();
    setState(() {});
  }

  void _onTextChanged(String _) {
    widget.onChanged();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final primary =
        widget.primaryColor ?? const Color(AppColors.primaryColor);
    final value = _current;
    final canDec = value > widget.min;
    final canInc = value < widget.max;

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
            onTap: () => _set(_current - widget.step),
          ),
          SizedBox(
            width: 56,
            child: TextField(
              controller: widget.controller,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: _onTextChanged,
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
            onTap: () => _set(_current + widget.step),
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
