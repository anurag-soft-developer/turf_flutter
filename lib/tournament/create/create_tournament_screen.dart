import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../components/shared/numeric_stepper_field.dart';
import '../../components/tournaments/tournament_cover_composer.dart';
import '../../core/components/app_bar/app_bar_background.dart';
import '../../core/config/constants.dart';
import '../../core/routes/route_query.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/date_util.dart';
import '../../team/model/team_model.dart';
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
  static const _categories = [
    'Open',
    'Corporate',
    'School',
    'College',
    'Other',
  ];
  static const _cricketBallTypes = ['Tennis', 'Leather', 'Other'];
  static const _cricketPitchTypes = ['Rough', 'Cement', 'Turf', 'Other'];
  static const _footballPitchTypes = [
    'Natural grass',
    'Artificial turf',
    'Futsal court',
    'Other',
  ];
  static const _footballMatchTypes = [
    '5-a-side',
    '7-a-side',
    '9-a-side',
    '11-a-side',
    'Other',
  ];

  final _name = TextEditingController();
  final _location = TextEditingController();
  final _overs = TextEditingController(text: '20');
  final _durationMinutes = TextEditingController();
  final _service = TournamentService();
  String _format = 'knockout';
  String? _sport;
  String? _category;
  String? _ballType;
  String? _pitchType;
  String? _matchType;
  int _step = 0;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _saving = false;

  bool get _isFootball => _sport == TeamSportType.football.name;

  CreateTournamentController get _media =>
      Get.find<CreateTournamentController>();

  @override
  void initState() {
    super.initState();
    final sport = optionalTeamSportFromRoute();
    if (sport == TeamSportType.cricket || sport == TeamSportType.football) {
      _sport = sport!.name;
      _step = 1;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _overs.dispose();
    _durationMinutes.dispose();
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

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final firstDate = _startDate ?? now.subtract(const Duration(days: 1));
    final candidate = _endDate ?? _startDate ?? now;
    final initial = candidate.isBefore(firstDate) ? firstDate : candidate;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (date == null || !mounted) return;
    setState(() {
      _endDate = DateTime(date.year, date.month, date.day);
    });
  }

  void _clearStartDate() {
    setState(() => _startDate = null);
  }

  void _selectFormat(String id) {
    if (_format == id) return;
    setState(() => _format = id);
  }

  void _selectSport(TeamSportType sport) {
    setState(() {
      if (_sport != sport.name) {
        _ballType = null;
        _pitchType = null;
        _matchType = null;
        _durationMinutes.clear();
      }
      _sport = sport.name;
    });
  }

  void _nextStep() {
    if (_sport == null) {
      AppSnackbar.error(title: 'Sport', message: 'Choose a sport to continue.');
      return;
    }
    setState(() => _step = 1);
  }

  void _changeSport() {
    setState(() => _step = 0);
  }

  Future<void> _save() async {
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
    final durationText = _durationMinutes.text.trim();
    final durationMinutes = durationText.isEmpty
        ? null
        : int.tryParse(durationText);
    if (_isFootball &&
        durationText.isNotEmpty &&
        (durationMinutes == null || durationMinutes < 1)) {
      AppSnackbar.error(
        title: 'Duration',
        message: 'Enter a duration in whole minutes.',
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
      sportType: _sport!,
      maxOvers: _isFootball ? null : overs,
      coverImages: coverUrls.isEmpty ? null : coverUrls,
      venueName: _location.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      category: _category,
      ballType: _isFootball ? null : _ballType,
      pitchType: _pitchType,
      matchType: _isFootball ? _matchType : null,
      durationMinutes: _isFootball ? durationMinutes : null,
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
      appBar: AppAppBar(
        title: Text(_step == 0 ? 'Choose sport' : 'Create tournament'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _step == 0
                ? _SportSelectionStep(
                    selected: _sport,
                    onSelected: _selectSport,
                  )
                : ListView(
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
                        formatLabel: (date) => formatDateOnly(
                          date,
                          Localizations.localeOf(context).toString(),
                        ),
                        primary: primary,
                      ),
                      const SizedBox(height: 16),
                      _OptionalDateField(
                        label: 'End date (optional)',
                        value: _endDate,
                        onPick: _pickEndDate,
                        onClear: () => setState(() => _endDate = null),
                        formatLabel: (date) => formatDateOnly(
                          date,
                          Localizations.localeOf(context).toString(),
                        ),
                        primary: primary,
                      ),
                      const SizedBox(height: 20),
                      _OptionalDropdownField(
                        label: 'Category (optional)',
                        value: _category,
                        options: _categories,
                        primary: primary,
                        onChanged: (value) => setState(() => _category = value),
                      ),
                      const SizedBox(height: 16),
                      if (_isFootball) ...[
                        _OptionalDropdownField(
                          label: 'Pitch type (optional)',
                          value: _pitchType,
                          options: _footballPitchTypes,
                          primary: primary,
                          onChanged: (value) =>
                              setState(() => _pitchType = value),
                        ),
                        const SizedBox(height: 16),
                        _OptionalDropdownField(
                          label: 'Match type (optional)',
                          value: _matchType,
                          options: _footballMatchTypes,
                          primary: primary,
                          onChanged: (value) =>
                              setState(() => _matchType = value),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _durationMinutes,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: _filledFieldDecoration(
                            labelText: 'Duration in minutes (optional)',
                            primary: primary,
                          ),
                        ),
                      ] else ...[
                        _OptionalDropdownField(
                          label: 'Ball type (optional)',
                          value: _ballType,
                          options: _cricketBallTypes,
                          primary: primary,
                          onChanged: (value) =>
                              setState(() => _ballType = value),
                        ),
                        const SizedBox(height: 16),
                        _OptionalDropdownField(
                          label: 'Pitch type (optional)',
                          value: _pitchType,
                          options: _cricketPitchTypes,
                          primary: primary,
                          onChanged: (value) =>
                              setState(() => _pitchType = value),
                        ),
                      ],
                      if (!_isFootball) ...[
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
                      ],
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _isFootball
                              ? '${formatHelpTextForCreate(_format)} Matches are two halves. A league win is worth 3 points and a draw is worth 1.'
                              : formatHelpTextForCreate(_format),
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
                child: _step == 0
                    ? SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _nextStep,
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Next'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _saving ? null : _changeSport,
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Back'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primary,
                              minimumSize: const Size(0, 52),
                              side: BorderSide(color: primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _saving ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.shade300,
                              minimumSize: const Size(0, 52),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_saving ? 'Posting...' : 'Post'),
                                const SizedBox(width: 8),
                                if (_saving)
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                else
                                  const Icon(Icons.send_rounded),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SportSelectionStep extends StatelessWidget {
  const _SportSelectionStep({required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<TeamSportType> onSelected;

  @override
  Widget build(BuildContext context) {
    const sports = [TeamSportType.cricket, TeamSportType.football];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Text(
            'Choose a sport for your tournament',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(AppColors.textColor),
            ),
          ),
        ),
        for (final sport in sports)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: _SportSelectionCard(
              sport: sport,
              selected: selected == sport.name,
              onTap: () => onSelected(sport),
            ),
          ),
      ],
    );
  }
}

class _SportSelectionCard extends StatelessWidget {
  const _SportSelectionCard({
    required this.sport,
    required this.selected,
    required this.onTap,
  });

  final TeamSportType sport;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = sport.config.color;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 104,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.06) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? color : const Color(0xFFE5E7EB),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(sport.icon, size: 30, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  sport.label,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Color(AppColors.textColor),
                  ),
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.chevron_right,
                color: selected ? color : const Color(0xFF9CA3AF),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormatOption {
  const _FormatOption({required this.id, required this.label});

  final String id;
  final String label;
}

class _OptionalDropdownField extends StatelessWidget {
  const _OptionalDropdownField({
    required this.label,
    required this.value,
    required this.options,
    required this.primary,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> options;
  final Color primary;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey('$label:${value ?? ''}'),
      initialValue: value,
      isExpanded: true,
      decoration: _filledFieldDecoration(labelText: label, primary: primary),
      items: [
        for (final option in options)
          DropdownMenuItem(value: option, child: Text(option)),
      ],
      onChanged: onChanged,
    );
  }
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
          decoration: _filledFieldDecoration(
            labelText: label,
            primary: primary,
          ),
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
                  icon: Icon(
                    Icons.close,
                    size: 20,
                    color: Colors.grey.shade600,
                  ),
                ),
              Icon(Icons.calendar_today_outlined, color: primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
