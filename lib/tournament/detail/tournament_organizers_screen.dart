import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../components/tournaments/tournament_organizers_section.dart';
import '../../core/components/app_bar/app_bar_background.dart';
import '../../core/config/constants.dart';
import '../../core/utils/app_snackbar.dart';
import '../model/tournament_models.dart';
import 'tournament_detail_controller.dart';

class TournamentOrganizersScreen extends StatelessWidget {
  const TournamentOrganizersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TournamentDetailController>();

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppAppBar(
        title: const Text('Organizers'),
        actions: [
          Obx(() {
            final tournament = controller.tournament.value;
            if (tournament == null || !controller.isOrganizer) {
              return const SizedBox.shrink();
            }
            return IconButton(
              tooltip: 'Add organizer',
              onPressed: () => showTournamentAddOrganizerSheet(
                context: context,
                controller: controller,
                existingIds: tournament.organizerList
                    .map((person) => person.id)
                    .toSet(),
              ),
              icon: const Icon(Icons.person_add_alt_1_outlined),
            );
          }),
        ],
      ),
      body: Obx(() {
        if (controller.loading.value && controller.tournament.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final tournament = controller.tournament.value;
        if (tournament == null) {
          return const Center(child: Text('Tournament not found.'));
        }
        if (!controller.isOrganizer) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Only organizers can manage this list.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        final people = tournament.organizerList;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            for (final person in people)
              TournamentOrganizerTile(
                person: person,
                isCreator: tournament.isCreator(person.id),
                onRemove: () => _confirmRemove(context, controller, person),
              ),
          ],
        );
      }),
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    TournamentDetailController controller,
    TournamentOrganizerRef person,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove organizer?'),
        content: Text(
          '${person.displayName} will no longer manage this tournament.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final removed = await controller.removeOrganizer(person.id);
    if (!removed) return;
    AppSnackbar.success(
      title: 'Organizer removed',
      message: '${person.displayName} is no longer an organizer.',
    );
  }
}
