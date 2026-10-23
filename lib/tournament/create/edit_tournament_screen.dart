import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../components/shared/numeric_stepper_field.dart';
import '../../core/components/app_bar/app_bar_background.dart';
import '../../core/config/constants.dart';
import '../../core/routes/route_query.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/date_util.dart';
import '../../team/model/team_model.dart';
import '../model/tournament_models.dart';
import '../tournament_service.dart';

class EditTournamentScreen extends StatefulWidget {
  const EditTournamentScreen({super.key});

  @override
  State<EditTournamentScreen> createState() => _EditTournamentScreenState();
}

class _EditTournamentScreenState extends State<EditTournamentScreen> {
  static const _formats = [
    _FormatOption(id: 'knockout', label: 'Knockout'),
    _FormatOption(id: 'league', label: 'League'),
    _FormatOption(id: 'hybrid', label: 'Hybrid'),
  ];

  static const _minOvers = 1;
  static const _maxOvers = 120;

  final _service = TournamentService();
  final _name = TextEditingController();
  final _location = TextEditingController();
  final _description = TextEditingController();
  final _overs = TextEditingController(text: '20');

  String? _tournamentId;
  String _format = 'knockout';
  String _sport = TeamSportType.cricket.name;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _registrationDeadline;
  bool _isPublic = true;
  bool _loading = true;
  bool _saving = false;
  bool _rosterLocked = false;
  String _status = '';

  bool get _isFootball => _sport == TeamSportType.football.name;

  @override
  void initState() {
    super.initState();
    _tournamentId = routeParam('id') ??
        (Get.arguments is Map
            ? (Get.arguments as Map)['tournamentId']?.toString()
            : null);
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _description.dispose();
    _overs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final id = _tournamentId;
    if (id == null || id.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    final tournament = await _service.getOne(id);
    if (!mounted) return;
    if (tournament == null) {
      setState(() => _loading = false);
      return;
    }
    _apply(tournament);
    setState(() => _loading = false);
  }

  void _apply(TournamentModel t) {
    _name.text = t.name;
    _location.text = t.venueName ?? '';
    _description.text = t.description ?? '';
    _overs.text = '${t.maxOvers}';
    _format = t.format;
    _sport = t.sportType;
    _startDate = t.startDate?.toLocal();
    _endDate = t.endDate?.toLocal();
    _registrationDeadline = t.registrationDeadline?.toLocal();
    _isPublic = t.isPublic;
    _rosterLocked = t.rosterLockedAt != null;
    _status = t.status;
  }

  Future<void> _pickDate(void Function(DateTime?) setter, DateTime? current) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (date == null || !mounted) return;
    setter(DateTime(date.year, date.month, date.day));
    setState(() {});
  }

  Future<void> _save() async {
    final id = _tournamentId;
    if (id == null || id.isEmpty) return;
    final name = _name.text.trim();
    final overs = int.tryParse(_overs.text.trim());
    if (name.isEmpty) {
      AppSnackbar.error(title: 'Name', message: 'Enter a tournament name.');
      return;
    }
    if (!_isFootball &&
        (overs == null || overs < _minOvers || overs > _maxOvers)) {
      AppSnackbar.error(
        title: 'Overs',
        message: 'Use between $_minOvers and $_maxOvers overs.',
      );
      return;
    }
    setState(() => _saving = true);
    final updated = await _service.updateDraft(
      id,
      name: name,
      format: _rosterLocked ? null : _format,
      sportType: _rosterLocked ? null : _sport,
      maxOvers: _isFootball ? null : overs,
      description: _description.text.trim(),
      venueName: _location.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      registrationDeadline: _registrationDeadline,
      isPublic: _isPublic,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (updated == null) return;
    Get.back(result: true);
  }

  @override
  Widget build(BuildContext context) {
    final primary = const Color(AppColors.primaryColor);
    if (_loading) {
      return Scaffold(
        appBar: const AppAppBar(title: Text('Edit tournament')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_tournamentId == null ||
        _status == 'completed' ||
        _status == 'cancelled') {
      return Scaffold(
        appBar: const AppAppBar(title: Text('Edit tournament')),
        body: const Center(child: Text('This tournament cannot be edited.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: const AppAppBar(title: Text('Edit tournament')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          if (_rosterLocked)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Roster is locked — format, sport, and capacity cannot change.',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              ),
            ),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: _decoration('Tournament name', primary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _location,
            textCapitalization: TextCapitalization.words,
            decoration: _decoration('Location', primary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            maxLines: 3,
            decoration: _decoration('Description', primary),
          ),
          const SizedBox(height: 16),
          if (!_rosterLocked) ...[
            _SportChipRow(
              selected: _sport,
              onSelected: (id) => setState(() => _sport = id),
            ),
            const SizedBox(height: 16),
            _FormatRow(
              formats: _formats,
              selected: _format,
              onSelected: (id) => setState(() => _format = id),
            ),
            const SizedBox(height: 16),
          ],
          _DateRow(
            label: 'Start date',
            value: _startDate,
            onPick: () => _pickDate((d) => _startDate = d, _startDate),
            onClear: () => setState(() => _startDate = null),
            primary: primary,
          ),
          const SizedBox(height: 12),
          _DateRow(
            label: 'End date',
            value: _endDate,
            onPick: () => _pickDate((d) => _endDate = d, _endDate),
            onClear: () => setState(() => _endDate = null),
            primary: primary,
          ),
          const SizedBox(height: 12),
          _DateRow(
            label: 'Registration deadline',
            value: _registrationDeadline,
            onPick: () => _pickDate(
              (d) => _registrationDeadline = d,
              _registrationDeadline,
            ),
            onClear: () => setState(() => _registrationDeadline = null),
            primary: primary,
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Public tournament'),
            subtitle: const Text('Show in open tournaments list'),
            value: _isPublic,
            onChanged: (value) => setState(() => _isPublic = value),
          ),
          if (!_isFootball) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Overs per innings',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  NumericStepperField(
                    controller: _overs,
                    min: _minOvers,
                    max: _maxOvers,
                    onChanged: () => setState(() {}),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save changes'),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(String label, Color primary) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: primary, width: 1.5),
      ),
    );
  }
}

class _SportChipRow extends StatelessWidget {
  const _SportChipRow({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final primary = const Color(AppColors.primaryColor);
    const sports = [TeamSportType.cricket, TeamSportType.football];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sport',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final sport in sports)
              ChoiceChip(
                label: Text(sport.label),
                selected: selected == sport.name,
                onSelected: (_) => onSelected(sport.name),
                selectedColor: primary.withValues(alpha: 0.15),
              ),
          ],
        ),
      ],
    );
  }
}

class _FormatOption {
  const _FormatOption({required this.id, required this.label});
  final String id;
  final String label;
}

class _FormatRow extends StatelessWidget {
  const _FormatRow({
    required this.formats,
    required this.selected,
    required this.onSelected,
  });

  final List<_FormatOption> formats;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final primary = const Color(AppColors.primaryColor);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Format',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final f in formats)
              ChoiceChip(
                label: Text(f.label),
                selected: selected == f.id,
                onSelected: (_) => onSelected(f.id),
                selectedColor: primary.withValues(alpha: 0.15),
              ),
          ],
        ),
      ],
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.value,
    required this.onPick,
    required this.onClear,
    required this.primary,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onPick;
  final VoidCallback onClear;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final text = value == null
        ? 'Not set'
        : formatDateOnly(value!.toLocal(), locale);
    return ListTile(
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(label),
      subtitle: Text(text),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null)
            IconButton(onPressed: onClear, icon: const Icon(Icons.close)),
          IconButton(
            onPressed: onPick,
            icon: Icon(Icons.calendar_today_outlined, color: primary),
          ),
        ],
      ),
      onTap: onPick,
    );
  }
}
