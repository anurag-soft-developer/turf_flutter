import 'package:flutter/material.dart';

import '../../../core/config/constants.dart';
import '../../../team/model/team_model.dart';
import '../../../team/utils/team_media_url.dart';
import '../../../team/utils/team_ui.dart';

class TeamHeroHeader extends StatefulWidget {
  const TeamHeroHeader({super.key, required this.team});

  final TeamModel team;

  @override
  State<TeamHeroHeader> createState() => _TeamHeroHeaderState();
}

class _TeamHeroHeaderState extends State<TeamHeroHeader> {
  final PageController _pageCtrl = PageController();
  int _current = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final covers = widget.team.coverImages
        .map(resolveTeamMediaUrl)
        .whereType<String>()
        .toList();
    final logoUrl = resolveTeamMediaUrl(widget.team.logo);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Cover image / carousel
        _buildCoverArea(covers),

        // Gradient overlay — IgnorePointer so swipes reach the PageView
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.55),
                  ],
                  stops: const [0.3, 1.0],
                ),
              ),
            ),
          ),
        ),

        // Content over the cover — IgnorePointer so swipes pass through
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page dots
                  if (covers.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          covers.length,
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
                      ),
                    ),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildLogo(logoUrl),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.team.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                                letterSpacing: -0.3,
                              ),
                            ),
                            if (widget.team.shortName != null &&
                                widget.team.shortName!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  widget.team.shortName!,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                _ChipBadge(
                                  icon: Icons.sports,
                                  label: teamSportLabel(widget.team.sportType),
                                ),
                                if (widget.team.lookingForMembers)
                                  const _ChipBadge(
                                    icon: Icons.person_add_alt_1,
                                    label: 'Recruiting',
                                    color: Color(AppColors.successColor),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCoverArea(List<String> covers) {
    if (covers.isEmpty) {
      return Container(
        height: 260,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(AppColors.primaryColor),
              const Color(AppColors.secondaryColor),
            ],
          ),
        ),
        child: const Center(
          child: Icon(Icons.shield_outlined, size: 72, color: Colors.white24),
        ),
      );
    }

    return SizedBox(
      height: 260,
      width: double.infinity,
      child: PageView.builder(
        controller: _pageCtrl,
        itemCount: covers.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (_, i) => Image.network(
          covers[i],
          fit: BoxFit.cover,
          width: double.infinity,
          height: 260,
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
        radius: 38,
        backgroundColor: Colors.white,
        backgroundImage: logoUrl != null ? NetworkImage(logoUrl) : null,
        child: logoUrl == null
            ? const Icon(
                Icons.shield_outlined,
                size: 36,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
