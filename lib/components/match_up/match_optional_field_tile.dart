import 'package:flutter/material.dart';

import '../../core/config/constants.dart';
import '../../match_up/model/team_match_model.dart';
import '../../turf/model/turf_model.dart';
import '../challenges/praposals/propose_time_slot_sheet.dart';
import '../challenges/praposals/propose_turf_sheet.dart';
import '../challenges/praposals/simple_location_sheet.dart';

/// Formats a propose / create slot for optional field tiles.
String formatMatchProposeSlot(ProposeScheduleTimeSlot slot) {
  final local = slot.startTime.toLocal();
  final dd = local.day.toString().padLeft(2, '0');
  final mm = local.month.toString().padLeft(2, '0');
  final yyyy = local.year.toString();
  final hh = local.hour.toString().padLeft(2, '0');
  final min = local.minute.toString().padLeft(2, '0');
  final end = slot.endTime.toLocal();
  final eh = end.hour.toString().padLeft(2, '0');
  final emin = end.minute.toString().padLeft(2, '0');
  return '$dd/$mm/$yyyy $hh:$min – $eh:$emin';
}

/// Shared optional venue fields for ranked/unranked match create.
class MatchCreateVenueFields extends StatelessWidget {
  const MatchCreateVenueFields({
    super.key,
    required this.sportTypeNames,
    required this.slot,
    required this.turf,
    required this.location,
    required this.onSlotChanged,
    required this.onTurfChanged,
    required this.onLocationChanged,
    this.showNearbyPlayers = false,
    this.allowNearbyPlayers = false,
    this.onAllowNearbyPlayersChanged,
  });

  final List<String> sportTypeNames;
  final ProposeScheduleTimeSlot? slot;
  final TurfModel? turf;
  final LocationModel? location;
  final ValueChanged<ProposeScheduleTimeSlot?> onSlotChanged;
  final ValueChanged<TurfModel?> onTurfChanged;
  final ValueChanged<LocationModel?> onLocationChanged;
  final bool showNearbyPlayers;
  final bool allowNearbyPlayers;
  final ValueChanged<bool>? onAllowNearbyPlayersChanged;

  Future<void> _pickTimeSlot(BuildContext context) async {
    final selected = await showModalBottomSheet<ProposeScheduleTimeSlot>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const ProposeTimeSlotSheet(),
    );
    if (selected != null) onSlotChanged(selected);
  }

  Future<void> _pickTurf(BuildContext context) async {
    final picked = await showModalBottomSheet<TurfModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) => ProposeTurfSheet(sportTypes: sportTypeNames),
    );
    if (picked == null) return;
    onTurfChanged(picked);
    // UI-only auto-fill; user can still edit location.
    if (picked.location != null) {
      onLocationChanged(picked.location);
    }
  }

  Future<void> _pickLocation(BuildContext context) async {
    final picked = await showModalBottomSheet<LocationModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) => SimpleLocationSheet(initialAddress: location?.address),
    );
    if (picked != null) onLocationChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MatchOptionalFieldTile(
          icon: Icons.schedule,
          label: 'Date & time',
          value: slot == null ? null : formatMatchProposeSlot(slot!),
          onTap: () => _pickTimeSlot(context),
          onClear: slot == null ? null : () => onSlotChanged(null),
        ),
        const SizedBox(height: 10),
        MatchOptionalFieldTile(
          icon: Icons.grass,
          label: 'Turf',
          value: turf?.displayName,
          onTap: () => _pickTurf(context),
          onClear: turf == null ? null : () => onTurfChanged(null),
        ),
        const SizedBox(height: 10),
        MatchOptionalFieldTile(
          icon: Icons.location_on_outlined,
          label: 'Location',
          value: location?.address,
          onTap: () => _pickLocation(context),
          onClear: location == null ? null : () => onLocationChanged(null),
        ),
        if (showNearbyPlayers && onAllowNearbyPlayersChanged != null) ...[
          const SizedBox(height: 10),
          NearbyPlayersCheckbox(
            value: allowNearbyPlayers,
            onChanged: onAllowNearbyPlayersChanged!,
          ),
        ],
      ],
    );
  }
}

class MatchOptionalFieldTile extends StatelessWidget {
  const MatchOptionalFieldTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.trim().isNotEmpty;

    return Material(
      color: const Color(AppColors.backgroundColor),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: const Color(AppColors.textSecondaryColor)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(AppColors.textColor),
                          ),
                        ),
                        if (!hasValue) ...[
                          const SizedBox(width: 6),
                          const Text(
                            'optional',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Color(AppColors.textSecondaryColor),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (hasValue) ...[
                      const SizedBox(height: 4),
                      Text(
                        value!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(AppColors.textSecondaryColor),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onClear != null)
                IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.close, size: 18),
                  visualDensity: VisualDensity.compact,
                )
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(AppColors.textSecondaryColor),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class NearbyPlayersCheckbox extends StatelessWidget {
  const NearbyPlayersCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(AppColors.backgroundColor),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            children: [
              Checkbox(
                value: value,
                onChanged: (v) => onChanged(v ?? false),
                activeColor: const Color(AppColors.primaryColor),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Allow to participate nearby players',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(AppColors.textColor),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
