import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../components/shared/numeric_stepper_field.dart';
import '../../components/tournaments/tournament_cover_composer.dart';
import '../../core/components/app_bar/app_bar_background.dart';
import '../../core/config/constants.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/date_util.dart';
import '../tournament_service.dart';
import '../tournament_team_count.dart';
import 'create_tournament_controller.dart';

class CreateTournamentScreen extends StatefulWidget {
  const CreateTournamentScreen({super.key});

  @override
  State<CreateTournamentScreen> createState() => _CreateTournamentScreenState();
}

class _CreateTournamentScreenState extends State<CreateTournamentScreen> {
  static const _formats = [
    _FormatOption(id: 'knockout', label: 'Knockout'),
    _FormatOption(id: 'league', label: 'League'),
    _FormatOption(id: 'hybrid', label: 'Hybrid'),
  ];

  static const _minOvers = 1;
  static const _maxOvers = 120;

  final _name = TextEditingController();
  final _location = TextEditingController();
  final _overs = TextEditingController(text: '20');
  final _service = TournamentService();
  String _format = 'knockout';
  DateTime? _startDate;
  bool _saving = false;

  CreateTournamentController get _media => Get.find<CreateTournamentController>();

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _overs.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final initial = _startDate ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (date == null || !mounted) return;
    setState(() {
      _startDate = DateTime(date.year, date.month, date.day);
    });
  }

  void _clearStartDate() {
    setState(() => _startDate = null);
  }

  void _selectFormat(String id) {
    if (_format == id) return;
    setState(() => _format = id);
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final overs = int.tryParse(_overs.text.trim());
    if (name.isEmpty) {
      AppSnackbar.error(title: 'Name', message: 'Enter a tournament name.');
      return;
    }
    if (overs == null || overs < _minOvers || overs > _maxOvers) {
      AppSnackbar.error(
        title: 'Overs',
        message: 'Use between $_minOvers and $_maxOvers overs.',
      );
      return;
    }
    setState(() => _saving = true);

    final coverUrls = await _media.coverUrlsForCreate();
    if (!mounted) return;
    if (coverUrls == null) {
      setState(() => _saving = false);
      return;
    }

    final created = await _service.create(
      name: name,
      format: _format,
      maxOvers: overs,
      coverImages: coverUrls.isEmpty ? null : coverUrls,
      venueName: _location.text.trim(),
      startDate: _startDate,
    );
    if (!mounted) return;
    if (created == null || created.id.isEmpty) {
      setState(() => _saving = false);
      return;
    }
    Get.offNamed(AppConstants.routes.tournamentDetail(created.id));
  }

  @override
  Widget build(BuildContext context) {
    final primary = const Color(AppColors.primaryColor);

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: const AppAppBar(title: Text('Create tournament')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              children: [
                TournamentCoverComposer(controller: _media),
                const SizedBox(height: 16),
                _FormatTabRow(
                  formats: _formats,
                  selected: _format,
                  onSelected: _selectFormat,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: _filledFieldDecoration(
                    labelText: 'Tournament name',
                    primary: primary,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _location,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: _filledFieldDecoration(
                    labelText: 'Location (optional)',
                    primary: primary,
                  ),
                ),
                const SizedBox(height: 16),
                _OptionalDateField(
                  label: 'Start date (optional)',
                  value: _startDate,
                  onPick: _pickStartDate,
                  onClear: _clearStartDate,
                  formatLabel: (date) =>
                      formatDateOnly(date, Localizations.localeOf(context).toString()),
                  primary: primary,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: _StepperSection(
                    title: 'Overs per innings',
                    subtitle: '$_minOvers–$_maxOvers',
                    child: NumericStepperField(
                      controller: _overs,
                      min: _minOvers,
                      max: _maxOvers,
                      onChanged: () {},
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    formatHelpTextForCreate(_format),
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
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
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    elevation: 0,
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
                      : const Text(
                          'Create tournament',
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
      ),
    );
  }
}

class _FormatOption {
  const _FormatOption({required this.id, required this.label});

  final String id;
  final String label;
}

class _FormatTabRow extends StatelessWidget {
  const _FormatTabRow({
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
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              for (final format in formats)
                Expanded(
                  child: _FormatTab(
                    label: format.label,
                    selected: selected == format.id,
                    onTap: () => onSelected(format.id),
                    primary: primary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FormatTab extends StatelessWidget {
  const _FormatTab({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.primary,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? primary : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected
                  ? Colors.white
                  : const Color(AppColors.textSecondaryColor),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepperSection extends StatelessWidget {
  const _StepperSection({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(AppColors.textColor),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 12),
        Center(child: child),
      ],
    );
  }
}

InputDecoration _filledFieldDecoration({
  required String labelText,
  required Color primary,
}) {
  return InputDecoration(
    labelText: labelText,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: primary, width: 1.5),
    ),
  );
}

class _OptionalDateField extends StatelessWidget {
  const _OptionalDateField({
    required this.label,
    required this.value,
    required this.onPick,
    required this.onClear,
    required this.formatLabel,
    required this.primary,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onPick;
  final VoidCallback onClear;
  final String Function(DateTime date) formatLabel;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    final display = hasValue ? formatLabel(value!) : 'Not set';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(14),
        child: InputDecorator(
          decoration: _filledFieldDecoration(labelText: label, primary: primary),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  display,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: hasValue
                        ? const Color(AppColors.textColor)
                        : Colors.grey.shade500,
                  ),
                ),
              ),
              if (hasValue)
                IconButton(
                  tooltip: 'Clear date',
                  onPressed: onClear,
                  icon: Icon(Icons.close, size: 20, color: Colors.grey.shade600),
                ),
              Icon(Icons.calendar_today_outlined, color: primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
