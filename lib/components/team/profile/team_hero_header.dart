import 'package:flutter/material.dart';
import 'package:flutter_application_1/components/shared/app_network_image.dart';
import 'package:get/get.dart';

import '../../../core/config/constants.dart';
import '../../../core/services/followings_service.dart';
import '../../../team/model/team_model.dart';
import '../../../team/utils/team_media_url.dart';
import '../../player/follow/follow_button.dart';
import '../../player/follow/follow_stat_button.dart';

class TeamHeroHeader extends StatefulWidget {
  const TeamHeroHeader({super.key, required this.team});

  final TeamModel team;

  @override
  State<TeamHeroHeader> createState() => _TeamHeroHeaderState();
}

class _TeamHeroHeaderState extends State<TeamHeroHeader> {
  final PageController _pageCtrl = PageController();
  int _current = 0;

  static const double _coverHeight = 280;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _openFollowers() {
    final teamId = widget.team.id;
    if (teamId == null || teamId.isEmpty) return;
    Get.toNamed(
      Uri(
        path: AppConstants.routes.teamFollowers(teamId),
        queryParameters: {'name': widget.team.name},
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final covers = widget.team.coverImages
        .map(resolveTeamMediaUrl)
        .whereType<String>()
        .toList();
    final logoUrl = resolveTeamMediaUrl(widget.team.logo);
    final canOpenFollowers =
        widget.team.id != null && widget.team.id!.isNotEmpty;
    final hasShortName =
        widget.team.shortName != null && widget.team.shortName!.isNotEmpty;

    return SizedBox(
      height: _coverHeight,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildCoverArea(covers),

          // Gradient — non-interactive so cover swipes work.
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0x8C000000),
                  ],
                  stops: [0.35, 1.0],
                ),
              ),
            ),
          ),

          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (covers.length > 1) ...[
                  IgnorePointer(child: _buildPageDots(covers.length)),
                  const SizedBox(height: 14),
                ],

                // Identity row: logo + name / chips
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IgnorePointer(child: _buildLogo(logoUrl)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: IgnorePointer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.team.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                                letterSpacing: -0.3,
                              ),
                            ),
                            if (hasShortName)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  widget.team.shortName!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            if (widget.team.lookingForMembers) ...[
                              const SizedBox(height: 8),
                              const Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _ChipBadge(
                                    icon: Icons.person_add_alt_1,
                                    label: 'Looking for players',
                                    color: Color(AppColors.successColor),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Actions row: followers (left) + follow (right)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    FollowStatButton(
                      count: widget.team.followerCount,
                      label: 'Followers',
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      onTap: canOpenFollowers ? _openFollowers : null,
                    ),
                    const Spacer(),
                    FollowButton(
                      targetId: widget.team.id,
                      recipientType: FollowRecipientType.team,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageDots(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: _current == i ? 22 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: _current == i
                ? Colors.white
                : Colors.white.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildCoverArea(List<String> covers) {
    if (covers.isEmpty) {
      return const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(AppColors.primaryColor),
              Color(AppColors.secondaryColor),
            ],
          ),
        ),
      );
    }

    return PageView.builder(
      controller: _pageCtrl,
      itemCount: covers.length,
      onPageChanged: (i) => setState(() => _current = i),
      itemBuilder: (_, i) => AppNetworkImage(
        covers[i],
        fit: BoxFit.cover,
        width: double.infinity,
        height: _coverHeight,
        errorBuilder: (_, __, ___) => Container(
          color: const Color(AppColors.primaryColor),
          child: const Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: Colors.white38,
              size: 48,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(String? logoUrl) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 36,
        backgroundColor: Colors.white,
        backgroundImage: logoUrl != null ? AppNetworkImage.provider(logoUrl) : null,
        child: logoUrl == null
            ? const Icon(
                Icons.shield_outlined,
                size: 32,
                color: Color(AppColors.primaryColor),
              )
            : null,
      ),
    );
  }
}

class _ChipBadge extends StatelessWidget {
  const _ChipBadge({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final bgColor = color ?? Colors.white.withValues(alpha: 0.2);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
