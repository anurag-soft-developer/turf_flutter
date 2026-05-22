import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/config/constants.dart';
import '../../../core/models/user_field_instance.dart';
import '../football_scoring_controller.dart';
import '../model/football_match_event_model.dart';
import '../util/football_scoring_helpers.dart';

class FootballEventsTimeline extends StatelessWidget {
  const FootballEventsTimeline({super.key, required this.controller});

  final FootballScoringController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isFetchingEvents.value &&
          controller.footballEvents.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      final events = controller.footballEvents.toList();
      if (events.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(AppColors.dividerColor)),
          ),
          child: const Text(
            'No events yet. Record goals, cards, and substitutions below.',
            style: TextStyle(color: Color(AppColors.textSecondaryColor)),
          ),
        );
      }

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(AppColors.dividerColor)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Text(
                'Match events',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: events.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final e = events[index];
                final primary = UserFieldInstance(e.primaryUserId)
                    .getDisplayName();
                final secondary = UserFieldInstance(e.secondaryUserId)
                    .getDisplayName();
                final minute = e.matchMinute != null ? "${e.matchMinute}' · " : '';
                final subtitle = switch (e.kind) {
                  FootballEventKind.goal =>
                    secondary.isNotEmpty && secondary != 'Unknown'
                        ? '$primary (assist: $secondary)'
                        : primary,
                  FootballEventKind.substitution => '$primary → $secondary',
                  _ => primary.isNotEmpty && primary != 'Unknown'
                      ? primary
                      : null,
                };

                return ListTile(
                  leading: Icon(
                    eventKindIcon(e.kind),
                    color: const Color(AppColors.primaryColor),
                  ),
                  title: Text(
                    '$minute#${e.sequence} ${eventKindLabel(e.kind)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: subtitle != null ? Text(subtitle) : null,
                );
              },
            ),
          ],
        ),
      );
    });
  }
}
