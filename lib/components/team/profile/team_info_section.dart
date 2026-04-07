import 'package:flutter/material.dart';

import '../../../core/config/constants.dart';
import '../../../team/model/team_model.dart';
import '../../../team/utils/team_ui.dart';

class TeamInfoSection extends StatelessWidget {
  const TeamInfoSection({super.key, required this.team});

  final TeamModel team;

  @override
  Widget build(BuildContext context) {
    final hasTagline = team.tagline != null && team.tagline!.isNotEmpty;
    final hasDescription =
        team.description != null && team.description!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tagline + Description card
        if (hasTagline || hasDescription)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasTagline) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.format_quote_rounded,
                        size: 20,
                        color: const Color(
                          AppColors.primaryColor,
                        ).withValues(alpha: 0.4),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          team.tagline!,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                            color: const Color(
                              AppColors.primaryColor,
                            ).withValues(alpha: 0.8),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (hasDescription) const SizedBox(height: 14),
                ],
                if (hasDescription)
                  Text(
                    team.description!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(AppColors.textSecondaryColor),
                      height: 1.6,
                    ),
                  ),
              ],
            ),
          ),

        if (hasTagline || hasDescription) const SizedBox(height: 16),

        // Info grid card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _buildInfoGrid(),
        ),
      ],
    );
  }

  Widget _buildInfoGrid() {
    final shortItems = <_InfoItem>[];
    final wideItems = <_InfoItem>[];

    shortItems.add(
      _InfoItem(
        icon: Icons.sports,
        label: 'Sport',
        value: teamSportLabel(team.sportType),
      ),
    );

    if (team.genderCategory != null) {
      shortItems.add(
        _InfoItem(
          icon: Icons.wc_outlined,
          label: 'Category',
          value: _genderLabel(team.genderCategory!),
        ),
      );
    }

    if (team.foundedYear != null) {
      shortItems.add(
        _InfoItem(
          icon: Icons.calendar_today_outlined,
          label: 'Founded',
          value: team.foundedYear.toString(),
        ),
      );
    }

    if (team.preferredTimeSlot != null) {
      shortItems.add(
        _InfoItem(
          icon: Icons.schedule_outlined,
          label: 'Time Slot',
          value: _timeSlotLabel(team.preferredTimeSlot!),
        ),
      );
    }

    if (team.location != null) {
      wideItems.add(
        _InfoItem(
          icon: Icons.location_on_outlined,
          label: 'Location',
          value: team.location!.address,
        ),
      );
    }

    if (team.preferredPlayDays.isNotEmpty) {
      wideItems.add(
        _InfoItem(
          icon: Icons.date_range_outlined,
          label: 'Play Days',
          value: team.preferredPlayDays
              .map((d) => d.substring(0, 3)._cap())
              .join(', '),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final halfWidth = (constraints.maxWidth - gap) / 2;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in shortItems)
              SizedBox(
                width: halfWidth,
                child: _CompactInfoTile(item: item),
              ),
            for (final item in wideItems)
              SizedBox(
                width: constraints.maxWidth,
                child: _CompactInfoTile(item: item),
              ),
          ],
        );
      },
    );
  }

  static String _genderLabel(TeamGenderCategory g) {
    return switch (g) {
      TeamGenderCategory.male => 'Male',
      TeamGenderCategory.female => 'Female',
      TeamGenderCategory.mixed => 'Mixed',
    };
  }

  static String _timeSlotLabel(TeamPreferredTimeSlot t) {
    return switch (t) {
      TeamPreferredTimeSlot.morning => 'Morning',
      TeamPreferredTimeSlot.afternoon => 'Afternoon',
      TeamPreferredTimeSlot.evening => 'Evening',
    };
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _CompactInfoTile extends StatelessWidget {
  const _CompactInfoTile({required this.item});

  final _InfoItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(AppColors.backgroundColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(item.icon, size: 18, color: const Color(AppColors.primaryColor)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(AppColors.textSecondaryColor),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  item.value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(AppColors.textColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension _StringCap on String {
  String _cap() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
