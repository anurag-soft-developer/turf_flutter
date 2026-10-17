import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../components/match_up/team_logo.dart';
import '../../components/shared/app_network_image.dart';
import '../../core/auth/auth_state_controller.dart';
import '../../core/config/constants.dart';
import '../../core/models/team/team_member_field_instance.dart';
import '../../core/models/user/user_model.dart';
import '../../core/models/user_field_instance.dart';
import '../../core/utils/app_snackbar.dart';
import '../../team/model/team_model.dart';
import '../../team/utils/team_ui.dart';
import '../model/enrollment_model.dart';
import '../model/opening_model.dart';
import '../openings_controller.dart';

class OpeningCard extends StatelessWidget {
  const OpeningCard({super.key, required this.opening});

  final OpeningModel opening;

  @override
  Widget build(BuildContext context) {
    final sport = sportOfOpening(opening.sportType);
    final place = opening.hostPlace?.trim();
    final meta = [
      if (opening.type == OpeningType.tournament) 'Tournament',
      if (sport != null) teamSportLabel(sport),
      if (place != null && place.isNotEmpty) place,
    ].join(' · ');

    return Obx(() {
      final controller = Get.find<OpeningsController>();
      controller.enrollingIds.length;
      final showEnroll = canEnrollInOpening(opening);
      final card = Card(
        elevation: 0,
        color: const Color(AppColors.surfaceColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openOpeningHost(opening),
          child: opening.type == OpeningType.tournament
              ? _tournamentBody(sport, meta, showEnroll, controller)
              : _teamBody(meta, showEnroll, controller),
        ),
      );
      final poster = opening.poster;
      if (poster == null) return card;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OpeningPosterRow(user: poster),
          const SizedBox(height: 12),
          card,
        ],
      );
    });
  }

  Widget _teamBody(
    String meta,
    bool showEnroll,
    OpeningsController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TeamLogo(
                url: opening.hostImage ?? '',
                size: 48,
                teamId: opening.hostId,
              ),
              const SizedBox(width: 12),
              Expanded(child: _copy(meta)),
            ],
          ),
          if (showEnroll) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OpeningEnrollButton(
                opening: opening,
                controller: controller,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tournamentBody(
    TeamSportType? sport,
    String meta,
    bool showEnroll,
    OpeningsController controller,
  ) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 120),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 112),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _copy(meta),
                  if (showEnroll) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OpeningEnrollButton(
                        opening: opening,
                        controller: controller,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 112,
            child: OpeningCover(imageUrl: opening.hostImage, sport: sport),
          ),
        ],
      ),
    );
  }

  Widget _copy(String meta) {
    return Column(
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
          opening.hostName,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(AppColors.textSecondaryColor),
          ),
        ),
        if (meta.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            meta,
            style: const TextStyle(
              fontSize: 13,
              height: 1.35,
              color: Color(AppColors.textSecondaryColor),
            ),
          ),
        ],
      ],
    );
  }
}

class _OpeningPosterRow extends StatelessWidget {
  const _OpeningPosterRow({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final author = UserFieldInstance(user);
    final authorId = author.getId();
    final canOpen = authorId != null && authorId.isNotEmpty;
    final name = author.getDisplayName();
    final avatar = author.getAvatar() ?? '';

    void openProfile() {
      if (!canOpen) return;
      Get.toNamed(
        AppConstants.routes.teamMemberProfile,
        arguments: {'userId': authorId},
      );
    }

    return Row(
      children: [
        GestureDetector(
          onTap: canOpen ? openProfile : null,
          behavior: HitTestBehavior.opaque,
          child: CircleAvatar(
            radius: 20,
            backgroundImage: avatar.isNotEmpty
                ? AppNetworkImage.provider(avatar)
                : null,
            child: avatar.isEmpty
                ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?')
                : null,
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: canOpen ? openProfile : null,
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Color(AppColors.textColor),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

void openOpeningHost(OpeningModel opening) {
  switch (opening.type) {
    case OpeningType.team:
      if (opening.hostId.isEmpty) return;
      Get.toNamed(
        AppConstants.routes.teamProfile,
        arguments: {'teamId': opening.hostId},
      );
    case OpeningType.tournament:
      if (opening.hostId.isEmpty) return;
      Get.toNamed(AppConstants.routes.tournamentDetail(opening.hostId));
  }
}

bool canEnrollInOpening(OpeningModel opening) {
  final me = Get.isRegistered<AuthStateController>()
      ? Get.find<AuthStateController>().user?.id
      : null;
  if (me == null || me.isEmpty || me == opening.postedBy) return false;
  final mine = opening.myStatus;
  if (mine == EnrollmentStatus.pending || mine == EnrollmentStatus.accepted) {
    return false;
  }
  final openingId = opening.id;
  return openingId != null && openingId.isNotEmpty;
}

TeamSportType? sportOfOpening(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  for (final sport in TeamSportType.values) {
    if (sport.name == raw) return sport;
  }
  return null;
}

class OpeningCover extends StatelessWidget {
  const OpeningCover({super.key, required this.imageUrl, this.sport});

  final String? imageUrl;
  final TeamSportType? sport;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';
    final primary = const Color(AppColors.primaryColor);
    return Stack(
      fit: StackFit.expand,
      children: [
        if (url.isEmpty)
          _placeholder(primary)
        else
          AppNetworkImage(
            url,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) => _placeholder(primary),
          ),
      ],
    );
  }

  Widget _placeholder(Color primary) {
    return ColoredBox(
      color: primary.withValues(alpha: 0.06),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primary.withValues(alpha: 0.18),
              primary.withValues(alpha: 0.06),
            ],
          ),
        ),
        child: Center(
          child: Icon(
            sport?.icon ?? Icons.emoji_events_outlined,
            size: 36,
            color: primary.withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }
}

class OpeningEnrollButton extends StatelessWidget {
  const OpeningEnrollButton({
    super.key,
    required this.opening,
    required this.controller,
  });

  final OpeningModel opening;
  final OpeningsController controller;

  @override
  Widget build(BuildContext context) {
    if (!canEnrollInOpening(opening)) return const SizedBox.shrink();
    final openingId = opening.id!;
    final enrolling = controller.enrollingIds.contains(openingId);
    return _ActionButton(
      label: 'Enroll',
      isLoading: enrolling,
      onPressed: () => _enroll(context),
    );
  }

  Future<void> _enroll(BuildContext context) async {
    if (opening.type == OpeningType.team) {
      await controller.enroll(opening);
      return;
    }
    final teams = await controller.enterableTeams(opening.sportType);
    if (!context.mounted) return;
    if (teams.isEmpty) {
      AppSnackbar.warning(
        title: 'No team to enter',
        message:
            'You need to be an owner, captain, or vice captain of a team in this sport.',
      );
      return;
    }
    if (teams.length == 1) {
      await controller.enroll(opening, teamId: teams.first.id);
      return;
    }
    final picked = await showModalBottomSheet<TeamMemberFieldInstance>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _TeamPickSheet(teams: teams),
    );
    if (picked?.id == null) return;
    await controller.enroll(opening, teamId: picked!.id);
  }
}

class _TeamPickSheet extends StatelessWidget {
  const _TeamPickSheet({required this.teams});

  final List<TeamMemberFieldInstance> teams;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'Enter with',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(AppColors.textColor),
              ),
            ),
          ),
          for (final team in teams)
            ListTile(
              title: Text(team.name),
              onTap: () => Navigator.of(context).pop(team),
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final buttonColor = const Color(AppColors.primaryColor);
    return FilledButton(
      onPressed: onPressed == null || isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
        disabledBackgroundColor: buttonColor.withValues(alpha: 0.45),
        disabledForegroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      child: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              label,
              softWrap: false,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
    );
  }
}
