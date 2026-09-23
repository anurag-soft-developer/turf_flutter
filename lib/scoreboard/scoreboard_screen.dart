import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../components/shared/app_network_image.dart';
import '../components/shared/app_segmented_tabs/app_segmented_tabs.dart';
import '../components/shared/custom_button.dart';
import '../components/shared/user_avatar_app_bar_action.dart';
import '../core/components/scroll/floating_sliver_app_bar.dart';
import '../core/components/scroll/pinned_sliver_header.dart';
import '../core/config/constants.dart';
import '../team/model/team_model.dart';

class _ScoreboardSportOption {
  const _ScoreboardSportOption({
    required this.sport,
    required this.tagline,
    required this.imageUrl,
    required this.enabled,
  });

  final TeamSportType sport;
  final String tagline;
  final String imageUrl;
  final bool enabled;
}

/// Bottom-tab hub for starting ranked or unranked scoreboard sessions by sport.
class ScoreboardScreen extends StatefulWidget {
  const ScoreboardScreen({super.key});

  @override
  State<ScoreboardScreen> createState() => _ScoreboardScreenState();
}

class _ScoreboardScreenState extends State<ScoreboardScreen>
    with SingleTickerProviderStateMixin {
  static const _cardHeight = 200.0;
  static const _horizontalPadding = 20.0;
  static const _modeTabs = [
    AppTabItem(label: 'Unranked'),
    AppTabItem(label: 'Ranked'),
  ];

  late final TabController _tabController;

  static const _sports = [
    _ScoreboardSportOption(
      sport: TeamSportType.cricket,
      tagline: 'Live overs & wickets',
      imageUrl:
          'https://images.pexels.com/photos/3800517/pexels-photo-3800517.jpeg?auto=compress&cs=tinysrgb&w=1400',
      enabled: true,
    ),
    _ScoreboardSportOption(
      sport: TeamSportType.football,
      tagline: 'Live goals & time',
      imageUrl:
          'https://images.pexels.com/photos/399187/pexels-photo-399187.jpeg?auto=compress&cs=tinysrgb&w=1400',
      enabled: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _modeTabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openMatch(TeamSportType sport, {required bool ranked}) {
    Get.toNamed(
      AppConstants.routes.matchUpUnranked,
      parameters: {'sport': sport.name, 'mode': ranked ? 'ranked' : 'unranked'},
    );
  }

  Widget _modePage({required bool ranked}) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        _horizontalPadding,
        24,
        _horizontalPadding,
        24,
      ),
      itemCount: _sports.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final option = _sports[index];
        return SizedBox(
          height: _cardHeight,
          child: _SportPosterCard(
            option: option,
            ranked: ranked,
            onStart: () => _openMatch(option.sport, ranked: ranked),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      body: NestedScrollView(
        floatHeaderSlivers: true,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            FloatingSliverAppBar(
              leading: const UserAvatarAppBarAction(),
              title: const Text('Scoreboard'),
              actions: [
                IconButton(
                  tooltip: 'Rank',
                  icon: const Icon(Icons.emoji_events_rounded),
                  onPressed: () => Get.toNamed(AppConstants.routes.rank),
                ),
              ],
            ),
            PinnedSliverHeader(
              child: AppSegmentedTabs(
                controller: _tabController,
                items: _modeTabs,
                fillWidth: true,
                padding: const EdgeInsets.fromLTRB(
                  _horizontalPadding,
                  12,
                  _horizontalPadding,
                  4,
                ),
              ),
            ),
          ];
        },
        body: AppSegmentedTabView(
          controller: _tabController,
          children: [_modePage(ranked: false), _modePage(ranked: true)],
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.ranked});

  final bool ranked;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Text(
        ranked ? 'Ranked' : 'Unranked',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
    );
  }
}

class _SportPosterCard extends StatelessWidget {
  const _SportPosterCard({
    required this.option,
    required this.ranked,
    required this.onStart,
  });

  final _ScoreboardSportOption option;
  final bool ranked;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final sport = option.sport;
    final enabled = option.enabled;
    final radius = BorderRadius.circular(20);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = (MediaQuery.sizeOf(context).width * dpr).round().clamp(
      400,
      1400,
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Opacity(
          opacity: enabled ? 1 : 0.55,
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: sport.config.gradient,
                  ),
                ),
              ),
              AppNetworkImage(
                option.imageUrl,
                fit: BoxFit.cover,
                memCacheWidth: cacheWidth,
                placeholder: const SizedBox.shrink(),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x26000000), Color(0xC7000000)],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            sport.icon,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        _ModeChip(ranked: ranked),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      sport.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      option.tagline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.86),
                      ),
                    ),
                    const SizedBox(height: 12),
                    CustomButton(
                      text: 'Start scoring',
                      height: 44,
                      onPressed: enabled ? onStart : null,
                      icon: const Icon(Icons.play_arrow_rounded, size: 22),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
