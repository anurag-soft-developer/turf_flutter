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

/// Bottom-tab hub for a friendly match or a hosted tournament, by sport.
class ScoreboardScreen extends StatefulWidget {
  const ScoreboardScreen({super.key});

  @override
  State<ScoreboardScreen> createState() => _ScoreboardScreenState();
}

class _ScoreboardScreenState extends State<ScoreboardScreen>
    with SingleTickerProviderStateMixin {
  static const _cardHeight = 200.0;
  static const _horizontalPadding = 20.0;
  static const _hubTabs = [
    AppTabItem(label: 'Friendly match'),
    AppTabItem(label: 'Tournaments'),
  ];

  late final TabController _tabController;
  bool _ranked = false;

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
    _tabController = TabController(length: _hubTabs.length, vsync: this);
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

  void _hostTournament(TeamSportType sport) {
    if (sport != TeamSportType.cricket) return;
    Get.toNamed(AppConstants.routes.createTournament);
  }

  void _openMatchesForSport(TeamSportType sport) {
    Get.toNamed(
      AppConstants.routes.myMatches,
      parameters: {'sport': sport.name},
    );
  }

  void _openTournamentsForSport(TeamSportType sport) {
    Get.toNamed(
      AppConstants.routes.tournaments,
      parameters: {'sport': sport.name},
    );
  }

  Widget _friendlyPage() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        _horizontalPadding,
        16,
        _horizontalPadding,
        24,
      ),
      children: [
        Align(
          alignment: Alignment.center,
          child: SegmentedButton<bool>(
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            segments: const [
              ButtonSegment(value: false, label: Text('Unranked')),
              ButtonSegment(value: true, label: Text('Ranked')),
            ],
            selected: {_ranked},
            onSelectionChanged: (value) {
              setState(() => _ranked = value.first);
            },
          ),
        ),
        const SizedBox(height: 16),
        for (var index = 0; index < _sports.length; index++) ...[
          if (index > 0) const SizedBox(height: 12),
          SizedBox(
            height: _cardHeight,
            child: _SportPosterCard(
              option: _sports[index],
              startIcon: Icons.play_arrow_rounded,
              onStart: _sports[index].enabled
                  ? () => _openMatch(_sports[index].sport, ranked: _ranked)
                  : null,
              onMine: () => _openMatchesForSport(_sports[index].sport),
            ),
          ),
        ],
      ],
    );
  }

  Widget _tournamentsPage() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        _horizontalPadding,
        16,
        _horizontalPadding,
        24,
      ),
      itemCount: _sports.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final option = _sports[index];
        final cricket = option.sport == TeamSportType.cricket;
        return SizedBox(
          height: _cardHeight,
          child: _SportPosterCard(
            option: option,
            subtitle: cricket ? option.tagline : 'Coming soon',
            startIcon: Icons.emoji_events_rounded,
            onStart: cricket ? () => _hostTournament(option.sport) : null,
            onMine: () => _openTournamentsForSport(option.sport),
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
                items: _hubTabs,
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
          children: [_friendlyPage(), _tournamentsPage()],
        ),
      ),
    );
  }
}

class _SportPosterCard extends StatelessWidget {
  const _SportPosterCard({
    required this.option,
    required this.startIcon,
    required this.onStart,
    required this.onMine,
    this.subtitle,
  });

  final _ScoreboardSportOption option;
  final String? subtitle;
  final IconData startIcon;
  final VoidCallback? onStart;
  final VoidCallback onMine;

  @override
  Widget build(BuildContext context) {
    final sport = option.sport;
    final radius = BorderRadius.circular(20);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = (MediaQuery.sizeOf(context).width * dpr).round().clamp(
      400,
      1400,
    );

    return DecoratedBox(
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
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(sport.icon, size: 20, color: Colors.white),
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
                    subtitle ?? option.tagline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.86),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Start',
                          height: 44,
                          onPressed: onStart,
                          icon: Icon(startIcon, size: 22),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onMine,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.12,
                            ),
                            side: const BorderSide(color: Colors.white),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: const Size(0, 44),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.view_list_rounded, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Mine',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
