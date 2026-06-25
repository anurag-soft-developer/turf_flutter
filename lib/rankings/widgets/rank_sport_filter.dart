import 'package:flutter/material.dart';

import '../../core/config/constants.dart';
import '../../team/model/team_model.dart';
import '../../team/utils/team_ui.dart';

/// Sport filter banner + bottom sheet picker.
class SportFilterPicker extends StatelessWidget {
  const SportFilterPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.sports,
    this.sheetTitle = 'Select sport',
    this.searchable = false,
  });

  final TeamSportType value;
  final ValueChanged<TeamSportType> onChanged;
  final List<TeamSportType>? sports;
  final String sheetTitle;
  final bool searchable;

  List<TeamSportType> get _sports => sports ?? rankingTeamSportTypes;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSportPicker(context),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(AppColors.primaryColor).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(AppColors.dividerColor).withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            _SportIconBadge(sport: value, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                teamSportLabel(value),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(AppColors.primaryColor),
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.expand_more_rounded,
              size: 16,
              color: Color(AppColors.textSecondaryColor),
            ),
          ],
        ),
      ),
    );
  }

  void _showSportPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _SportPickerSheet(
          value: value,
          sports: _sports,
          sheetTitle: sheetTitle,
          searchable: searchable,
          onChanged: (sport) {
            onChanged(sport);
            Navigator.pop(sheetContext);
          },
        );
      },
    );
  }
}

/// Rank screen — cricket and football only.
typedef RankSportFilter = SportFilterPicker;

class _SportPickerSheet extends StatefulWidget {
  const _SportPickerSheet({
    required this.value,
    required this.sports,
    required this.sheetTitle,
    required this.searchable,
    required this.onChanged,
  });

  final TeamSportType value;
  final List<TeamSportType> sports;
  final String sheetTitle;
  final bool searchable;
  final ValueChanged<TeamSportType> onChanged;

  @override
  State<_SportPickerSheet> createState() => _SportPickerSheetState();
}

class _SportPickerSheetState extends State<_SportPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TeamSportType> get _filteredSports {
    if (_query.trim().isEmpty) return widget.sports;
    final q = _query.trim().toLowerCase();
    return widget.sports
        .where((sport) => teamSportLabel(sport).toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.75;

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.sheetTitle,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(AppColors.textColor),
              ),
            ),
            if (widget.searchable) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search sports',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ],
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredSports.length,
                itemBuilder: (context, index) {
                  final sport = _filteredSports[index];
                  final isSelected = sport == widget.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: isSelected
                          ? const Color(AppColors.primaryColor)
                              .withValues(alpha: 0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => widget.onChanged(sport),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(AppColors.primaryColor)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  sport.icon,
                                  color: const Color(AppColors.primaryColor),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  teamSportLabel(sport),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: const Color(AppColors.textColor),
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  size: 22,
                                  color: Color(AppColors.primaryColor),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SportIconBadge extends StatelessWidget {
  const _SportIconBadge({
    required this.sport,
    required this.size,
  });

  final TeamSportType sport;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(AppColors.primaryColor).withValues(alpha: 0.1),
      ),
      child: Icon(
        sport.icon,
        size: size * 0.64,
        color: const Color(AppColors.primaryColor),
      ),
    );
  }
}
