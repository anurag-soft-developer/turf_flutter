import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../components/player/profile/player_hero_section.dart';
import '../../components/player/profile/player_quick_stats.dart';
import '../../components/player/profile/sport_stats_view.dart';
import '../../core/config/constants.dart';
import '../../core/models/user_field_instance.dart';
import '../../core/models/user/player_stats_models.dart';

/// Arguments: `{'user': dynamic}` — populated [UserModel] or user id string.
class PlayerProfileScreen extends StatefulWidget {
  const PlayerProfileScreen({super.key});

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  UserFieldInstance? helper;

  @override
  void initState() {
    super.initState();

    final raw = Get.arguments;
    dynamic userField;
    if (raw is Map<String, dynamic>) {
      userField = raw['user'];
    }
    helper = UserFieldInstance(userField);

    // Get available sports from player stats
    final availableSports = _getAvailableSports();
    _tabController = TabController(length: availableSports.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<SportType> _getAvailableSports() {
    final model = helper?.getModel();
    if (model?.playerSportStats.isEmpty ?? true) {
      return [SportType.football, SportType.cricket]; // Default sports
    }

    return model!.playerSportStats
            .map((entry) => entry.sportType)
            .toSet()
            .toList()
        as List<SportType>;
  }

  PlayerSportEntry? _getStatsForSport(SportType sport) {
    final model = helper?.getModel();
    if (model?.playerSportStats.isEmpty ?? true) return null;

    try {
      return model!.playerSportStats.firstWhere(
        (entry) => entry.sportType == sport,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (helper == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Player Profile')),
        body: const Center(child: Text('Player not found')),
      );
    }

    final availableSports = _getAvailableSports();

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('Player Profile'),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(child: PlayerHeroSection(helper: helper!)),
          ];
        },
        body: Column(
          children: [
            // Quick Stats Bar
            PlayerQuickStats(helper: helper!),

            const SizedBox(height: 24),

            // Sport Stats Tabs
            if (availableSports.isNotEmpty) ...[
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: const Color(AppColors.primaryColor),
                  unselectedLabelColor: const Color(
                    AppColors.textSecondaryColor,
                  ),
                  indicatorColor: const Color(AppColors.primaryColor),
                  tabs: availableSports.map((sport) {
                    if (sport == SportType.football) {
                      return const Tab(
                        icon: Icon(Icons.sports_soccer, size: 20),
                        text: 'Football',
                      );
                    } else {
                      return const Tab(
                        icon: Icon(Icons.sports_cricket, size: 20),
                        text: 'Cricket',
                      );
                    }
                  }).toList(),
                ),
              ),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: availableSports.map((sport) {
                    final stats = _getStatsForSport(sport);
                    return SportStatsView(sport: sport, stats: stats);
                  }).toList(),
                ),
              ),
            ] else
              const Expanded(
                child: Center(
                  child: Text(
                    'No sport stats available',
                    style: TextStyle(
                      color: Color(AppColors.textSecondaryColor),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
