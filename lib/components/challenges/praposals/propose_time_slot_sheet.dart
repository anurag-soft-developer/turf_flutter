import 'package:flutter/material.dart';

import '../../../match_up/model/team_match_model.dart';

class ProposeTimeSlotSheet extends StatefulWidget {
  const ProposeTimeSlotSheet({super.key});

  @override
  State<ProposeTimeSlotSheet> createState() => _ProposeTimeSlotSheetState();
}

class _ProposeTimeSlotSheetState extends State<ProposeTimeSlotSheet> {
  DateTime? _startAt;
  int _durationHours = 1;

  Future<void> _pickStart() async {
    final now = DateTime.now();
    final initial = _startAt ?? now.add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;

    final picked = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (!mounted) return;
    setState(() {
      _startAt = picked;
    });
  }

  void _submit() {
    if (_startAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a start time.')),
      );
      return;
    }
    final endAt = _startAt!.add(Duration(hours: _durationHours));
    Navigator.of(context).pop(
      ProposeScheduleTimeSlot(startTime: _startAt!, endTime: endAt),
    );
  }

  String _fmt(DateTime? dt) {
    if (dt == null) return 'Not selected';
    final local = dt.toLocal();
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final yyyy = local.year.toString();
    final hh = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy $hh:$min';
  }

  @override
  Widget build(BuildContext context) {
    final computedEnd = _startAt?.add(Duration(hours: _durationHours));

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Propose Time Slot',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule),
              title: const Text('Start Time'),
              subtitle: Text(_fmt(_startAt)),
              trailing: TextButton(onPressed: _pickStart, child: const Text('Pick')),
            ),
            Row(
              children: [
                const Icon(Icons.timelapse),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Match Duration (hours)',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                DropdownButton<int>(
                  value: _durationHours,
                  items: List.generate(
                    8,
                    (index) => DropdownMenuItem<int>(
                      value: index + 1,
                      child: Text('${index + 1}h'),
                    ),
                  ),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _durationHours = value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'End Time (auto): ${_fmt(computedEnd)}',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text('Send Proposal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
