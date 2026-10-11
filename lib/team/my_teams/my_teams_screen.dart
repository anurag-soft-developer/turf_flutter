import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/components/scroll/floating_sliver_app_bar.dart';
import '../../core/config/constants.dart';
import '../../rankings/widgets/rank_sport_filter.dart';
import '../model/team_model.dart';
import 'my_teams_memberships_body.dart';

class MyTeamsScreen extends StatefulWidget {
  const MyTeamsScreen({super.key});

  @override
  State<MyTeamsScreen> createState() => _MyTeamsScreenState();
}

class _MyTeamsScreenState extends State<MyTeamsScreen> {
  TeamSportType? _sport;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppConstants.routes.addTeam),
        backgroundColor: const Color(AppColors.primaryColor),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Create team',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: MyTeamsMembershipsBody(
        sportType: _sport,
        leadingSlivers: [
          FloatingSliverAppBar(
            title: const Text('My Teams'),
            actions: [
              IconButton(
                tooltip: 'Search',
                icon: const Icon(Icons.search),
                onPressed: () =>
                    Get.toNamed(AppConstants.routes.myTeamsSearch),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _SportFilterChip(
                  sport: _sport,
                  onChanged: (sport) => setState(() => _sport = sport),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SportFilterChip extends StatelessWidget {
  const _SportFilterChip({required this.sport, required this.onChanged});

  final TeamSportType? sport;
  final ValueChanged<TeamSportType?> onChanged;

  static const _height = 28.0;
  static const _selectedBg = Color(0xFFE0E7FF);

  @override
  Widget build(BuildContext context) {
    final selected = sport != null;
    final primary = const Color(AppColors.primaryColor);
    final muted = const Color(AppColors.textSecondaryColor);

    return Material(
      color: selected ? _selectedBg : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => SportFilterPicker.showSheet(
          context: context,
          value: sport,
          sports: TeamSportType.values,
          sheetTitle: 'Filter by sport',
          searchable: true,
          includeAll: true,
          onChanged: onChanged,
        ),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: _height,
          padding: const EdgeInsets.only(left: 8, right: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? primary : const Color(AppColors.dividerColor),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sports_outlined,
                size: 13,
                color: selected ? primary : muted,
              ),
              const SizedBox(width: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: Text(
                  selected ? sport!.label : 'Sport',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.1,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? primary : muted,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              if (selected)
                InkWell(
                  onTap: () => onChanged(null),
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
