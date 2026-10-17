import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/config/constants.dart';
import '../core/utils/app_snackbar.dart';
import '../rankings/widgets/rank_sport_filter.dart';
import '../team/model/team_model.dart';
import '../team/utils/team_ui.dart';
import 'model/opening_model.dart';
import 'openings_controller.dart';

Future<void> openPostOpening(BuildContext context) async {
  ensureOpeningsController();
  final controller = Get.find<OpeningsController>();
  await controller.loadOwnedOpenings();
  if (!context.mounted) return;
  if (controller.postableHosts.isEmpty) {
    AppSnackbar.warning(
      title: 'No host yet',
      message: 'Own a team or organize a tournament to post an opening.',
    );
    return;
  }
  await showPostOpeningSheet(context, controller);
}

Future<void> showPostOpeningSheet(
  BuildContext context,
  OpeningsController controller,
) {
  final hosts = controller.postableHosts;
  if (hosts.isEmpty) return Future.value();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _PostOpeningSheet(controller: controller, hosts: hosts),
  );
}

class _PostOpeningSheet extends StatefulWidget {
  const _PostOpeningSheet({required this.controller, required this.hosts});

  final OpeningsController controller;
  final List<OwnedOpening> hosts;

  @override
  State<_PostOpeningSheet> createState() => _PostOpeningSheetState();
}

class _PostOpeningSheetState extends State<_PostOpeningSheet> {
  late final TextEditingController _title;
  OpeningType? _type;
  String _targetId = '';
  int _maxPending = 50;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController();
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  List<OwnedOpening> get _hostsOfType {
    final type = _type;
    if (type == null) return const [];
    return [
      for (final host in widget.hosts)
        if (host.type == type) host,
    ];
  }

  OwnedOpening? get _selected {
    for (final host in _hostsOfType) {
      if (host.id == _targetId) return host;
    }
    final hosts = _hostsOfType;
    return hosts.isEmpty ? null : hosts.first;
  }

  void _choose(OpeningType type) {
    final matches = [
      for (final host in widget.hosts)
        if (host.type == type) host,
    ];
    setState(() {
      _type = type;
      _targetId = matches.isEmpty ? '' : matches.first.id;
      _title.clear();
      _maxPending = 50;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Post an opening',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(AppColors.textColor),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _type == null
                  ? 'What do you need?'
                  : 'Describe what you need.',
              style: const TextStyle(
                fontSize: 13,
                color: Color(AppColors.textSecondaryColor),
              ),
            ),
            const SizedBox(height: 14),
            if (_type == null) ...[
              _KindCard(
                title: 'Need players for a team',
                subtitle: 'Post an opening for one of your teams.',
                icon: Icons.groups_outlined,
                onTap: () => _choose(OpeningType.team),
              ),
              const SizedBox(height: 10),
              _KindCard(
                title: 'Need teams for a tournament',
                subtitle: 'Post an opening for a tournament you organize.',
                icon: Icons.emoji_events_outlined,
                onTap: () => _choose(OpeningType.tournament),
              ),
            ] else
              _form(),
          ],
        ),
      ),
    );
  }

  Widget _form() {
    final hosts = _hostsOfType;
    final selected = _selected;
    if (hosts.isEmpty || selected == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selected == null && _type == OpeningType.team
                ? 'You do not own a team to post for.'
                : 'You do not organize a tournament to post for.',
            style: const TextStyle(
              fontSize: 14,
              color: Color(AppColors.textSecondaryColor),
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _type = null),
            child: const Text('Back'),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton(
          onPressed: () => setState(() => _type = null),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('Back'),
        ),
        const SizedBox(height: 8),
        if (hosts.length == 1)
          Text(
            selected.name,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(AppColors.textColor),
            ),
          )
        else
          DropdownButtonFormField<String>(
            initialValue: selected.id,
            isExpanded: true,
            decoration: _fieldDecoration(),
            items: [
              for (final host in hosts)
                DropdownMenuItem<String>(
                  value: host.id,
                  child: Text(host.name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _targetId = value);
            },
          ),
        const SizedBox(height: 14),
        TextField(
          controller: _title,
          maxLength: 160,
          minLines: 3,
          maxLines: 6,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          decoration: _fieldDecoration(
            hint: selected.isTeam ? 'Need a wicketkeeper' : 'Teams wanted',
          ),
        ),
        if (selected.isTeam)
          _PendingLimitField(
            maxPending: _maxPending,
            enabled: true,
            onMaxPending: (value) => setState(() => _maxPending = value),
          ),
        const SizedBox(height: 8),
        Obx(() {
          final busy = widget.controller.updatingTargetId.value != null;
          return FilledButton(
            onPressed: busy
                ? null
                : () async {
                    final ok = await widget.controller.postOpening(
                      targetId: selected.id,
                      type: selected.type,
                      title: _title.text,
                      maxPendingJoinRequests: _maxPending,
                    );
                    if (ok && mounted) Navigator.of(context).pop();
                  },
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: const Color(AppColors.primaryColor),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(busy ? 'Posting…' : 'Post'),
          );
        }),
      ],
    );
  }
}

class _KindCard extends StatelessWidget {
  const _KindCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(AppColors.backgroundColor),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: const Color(AppColors.primaryColor)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(AppColors.textColor),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(AppColors.textSecondaryColor),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

enum _CardMenu { edit, enrolments, hold, reopen, close }

class ManageOpeningCard extends StatelessWidget {
  const ManageOpeningCard({
    super.key,
    required this.controller,
    required this.host,
    required this.opening,
  });

  final OpeningsController controller;
  final OwnedOpening host;
  final OpeningModel opening;

  @override
  Widget build(BuildContext context) {
    final openingId = opening.id;
    if (openingId == null) return const SizedBox.shrink();

    return Obx(() {
      final busy = controller.updatingTargetId.value == openingId;
      final sport = _sportOf(host.sportType);
      final hidden = host.isTeam
          ? 'Hidden until the team is public and active.'
          : 'Hidden until the tournament is public.';
      final statusLine = !host.discoverable
          ? hidden
          : opening.status == OpeningStatus.onHold
          ? 'On hold. Hidden from Openings until you reopen it.'
          : 'Live in Openings.';

      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: busy ? null : () => _openEnrolments(openingId, host.name),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 4, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                opening.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.35,
                                  fontWeight: FontWeight.w700,
                                  color: Color(AppColors.textColor),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                host.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(AppColors.textSecondaryColor),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                [
                                  _hostKind(host),
                                  if (sport != null) teamSportLabel(sport),
                                  statusLine,
                                ].join(' · '),
                                style: const TextStyle(
                                  fontSize: 12,
                                  height: 1.35,
                                  color: Color(AppColors.textSecondaryColor),
                                ),
                              ),
                              if (host.isTeam) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Max pending requests · ${opening.maxPendingJoinRequests}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(AppColors.textColor),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      PopupMenuButton<_CardMenu>(
                        tooltip: 'Opening actions',
                        enabled: !busy,
                        onSelected: (action) => _onMenu(context, action, openingId),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: _CardMenu.edit,
                            child: Text('Edit'),
                          ),
                          const PopupMenuItem(
                            value: _CardMenu.enrolments,
                            child: Text('Enrolments'),
                          ),
                          const PopupMenuDivider(),
                          if (opening.status == OpeningStatus.open)
                            const PopupMenuItem(
                              value: _CardMenu.hold,
                              child: Text('On hold'),
                            ),
                          if (opening.status == OpeningStatus.onHold)
                            const PopupMenuItem(
                              value: _CardMenu.reopen,
                              child: Text('Reopen'),
                            ),
                          const PopupMenuItem(
                            value: _CardMenu.close,
                            child: Text('Close'),
                          ),
                        ],
                        icon: const Icon(Icons.more_vert),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  void _onMenu(BuildContext context, _CardMenu action, String openingId) {
    switch (action) {
      case _CardMenu.edit:
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => _EditOpeningSheet(
            controller: controller,
            host: host,
            opening: opening,
          ),
        );
      case _CardMenu.enrolments:
        _openEnrolments(openingId, host.name);
      case _CardMenu.hold:
        controller.setOpeningStatus(host.id, openingId, OpeningStatus.onHold);
      case _CardMenu.reopen:
        controller.setOpeningStatus(host.id, openingId, OpeningStatus.open);
      case _CardMenu.close:
        controller.setOpeningStatus(host.id, openingId, OpeningStatus.closed);
    }
  }

  void _openEnrolments(String openingId, String title) {
    Get.toNamed(
      AppConstants.routes.teamJoinRequests,
      arguments: {'openingId': openingId, 'title': title},
    );
  }
}

class _EditOpeningSheet extends StatefulWidget {
  const _EditOpeningSheet({
    required this.controller,
    required this.host,
    required this.opening,
  });

  final OpeningsController controller;
  final OwnedOpening host;
  final OpeningModel opening;

  @override
  State<_EditOpeningSheet> createState() => _EditOpeningSheetState();
}

class _EditOpeningSheetState extends State<_EditOpeningSheet> {
  late final TextEditingController _title;
  late int _maxPending;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.opening.title);
    _maxPending = widget.opening.maxPendingJoinRequests;
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final openingId = widget.opening.id;
    if (openingId == null) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Edit opening',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(AppColors.textColor),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.host.name,
              style: const TextStyle(
                fontSize: 13,
                color: Color(AppColors.textSecondaryColor),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _title,
              maxLength: 160,
              minLines: 3,
              maxLines: 6,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              decoration: _fieldDecoration(
                hint: widget.host.isTeam ? 'Need a wicketkeeper' : 'Teams wanted',
              ),
            ),
            if (widget.host.isTeam)
              _PendingLimitField(
                maxPending: _maxPending,
                enabled: true,
                onMaxPending: (value) => setState(() => _maxPending = value),
              ),
            const SizedBox(height: 8),
            Obx(() {
              final busy = widget.controller.updatingTargetId.value != null;
              return FilledButton(
                onPressed: busy
                    ? null
                    : () async {
                        final ok = await widget.controller.saveOpeningEdits(
                          widget.host.id,
                          openingId,
                          title: _title.text,
                          maxPendingJoinRequests: widget.host.isTeam
                              ? _maxPending
                              : null,
                        );
                        if (ok && context.mounted) Navigator.of(context).pop();
                      },
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: const Color(AppColors.primaryColor),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(busy ? 'Saving…' : 'Save'),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Compact type and sport chips, matching the Matches sub filters.
class OpeningFiltersBar extends StatelessWidget {
  const OpeningFiltersBar({
    super.key,
    required this.sport,
    required this.type,
    required this.onSportChanged,
    required this.onTypeChanged,
  });

  final TeamSportType? sport;
  final OpeningType? type;
  final ValueChanged<TeamSportType?> onSportChanged;
  final ValueChanged<OpeningType?> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Builder(
              builder: (fieldContext) => _OpeningFilterChip(
                fieldLabel: 'Type',
                icon: Icons.category_outlined,
                label: switch (type) {
                  OpeningType.team => 'Team',
                  OpeningType.tournament => 'Tournament',
                  null => 'All',
                },
                hasSelection: type != null,
                onTap: () => _openTypeMenu(fieldContext),
                onClear: type == null ? null : () => onTypeChanged(null),
              ),
            ),
            const SizedBox(width: 6),
            _OpeningFilterChip(
              fieldLabel: 'Sport',
              icon: Icons.sports_outlined,
              label: sport?.label ?? 'All',
              hasSelection: sport != null,
              onTap: () => SportFilterPicker.showSheet(
                context: context,
                value: sport,
                sports: TeamSportType.values,
                sheetTitle: 'Filter by sport',
                searchable: true,
                includeAll: true,
                onChanged: onSportChanged,
              ),
              onClear: sport == null ? null : () => onSportChanged(null),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openTypeMenu(BuildContext context) async {
    final box = context.findRenderObject()! as RenderBox;
    final offset = box.localToGlobal(Offset.zero);
    final selected = await showMenu<_OpeningTypeChoice>(
      context: context,
      initialValue: switch (type) {
        OpeningType.team => _OpeningTypeChoice.team,
        OpeningType.tournament => _OpeningTypeChoice.tournament,
        null => _OpeningTypeChoice.all,
      },
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + box.size.height,
        offset.dx + box.size.width,
        offset.dy,
      ),
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 4,
      items: [
        for (final choice in _OpeningTypeChoice.values)
          PopupMenuItem(
            value: choice,
            child: Text(
              choice.label,
              style: const TextStyle(
                color: Color(AppColors.textColor),
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
    if (selected == null || !context.mounted) return;
    onTypeChanged(selected.type);
  }
}

enum _OpeningTypeChoice {
  all,
  team,
  tournament;

  String get label => switch (this) {
    _OpeningTypeChoice.all => 'All',
    _OpeningTypeChoice.team => 'Team',
    _OpeningTypeChoice.tournament => 'Tournament',
  };

  OpeningType? get type => switch (this) {
    _OpeningTypeChoice.all => null,
    _OpeningTypeChoice.team => OpeningType.team,
    _OpeningTypeChoice.tournament => OpeningType.tournament,
  };
}

class _OpeningFilterChip extends StatelessWidget {
  const _OpeningFilterChip({
    required this.fieldLabel,
    required this.icon,
    required this.label,
    required this.hasSelection,
    this.onTap,
    this.onClear,
  });

  final String fieldLabel;
  final IconData icon;
  final String label;
  final bool hasSelection;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  static const _height = 28.0;
  static const _selectedBg = Color(0xFFE0E7FF);

  @override
  Widget build(BuildContext context) {
    final primary = const Color(AppColors.primaryColor);
    final muted = const Color(AppColors.textSecondaryColor);
    final display = hasSelection ? label : fieldLabel;

    return Material(
      color: hasSelection ? _selectedBg : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: _height,
          padding: const EdgeInsets.only(left: 8, right: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasSelection
                  ? primary
                  : const Color(AppColors.dividerColor),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: hasSelection ? primary : muted),
              const SizedBox(width: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: Text(
                  display,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.1,
                    fontWeight: hasSelection ? FontWeight.w600 : FontWeight.w500,
                    color: hasSelection ? primary : muted,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              if (hasSelection && onClear != null)
                InkWell(
                  onTap: onClear,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(Icons.close, size: 12, color: muted),
                  ),
                )
              else
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 14,
                  color: muted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingLimitField extends StatelessWidget {
  const _PendingLimitField({
    required this.maxPending,
    required this.enabled,
    required this.onMaxPending,
  });

  final int maxPending;
  final bool enabled;
  final ValueChanged<int> onMaxPending;

  static const _pendingOptions = [10, 50, 100, 500];

  @override
  Widget build(BuildContext context) {
    final pendingChoices = <int>{..._pendingOptions, maxPending}.toList()
      ..sort();
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Max pending requests',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Color(AppColors.textColor),
            ),
          ),
        ),
        SizedBox(
          width: 104,
          child: DropdownButtonFormField<int>(
            key: ValueKey(maxPending),
            initialValue: maxPending,
            isExpanded: true,
            decoration: _fieldDecoration(compact: true),
            items: [
              for (final value in pendingChoices)
                DropdownMenuItem<int>(value: value, child: Text('$value')),
            ],
            onChanged: enabled
                ? (value) {
                    if (value == null || value == maxPending) return;
                    onMaxPending(value);
                  }
                : null,
          ),
        ),
      ],
    );
  }
}

String _hostKind(OwnedOpening host) => host.isTeam ? 'Team' : 'Tournament';

TeamSportType? _sportOf(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  for (final sport in TeamSportType.values) {
    if (sport.name == raw) return sport;
  }
  return null;
}

InputDecoration _fieldDecoration({String? hint, bool compact = false}) {
  return InputDecoration(
    hintText: hint,
    counterText: '',
    filled: true,
    fillColor: const Color(AppColors.backgroundColor),
    contentPadding: EdgeInsets.symmetric(
      horizontal: compact ? 10 : 12,
      vertical: compact ? 8 : 12,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
  );
}
