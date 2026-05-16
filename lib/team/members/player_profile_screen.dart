import 'package:flutter/material.dart';
import 'package:flutter_application_1/components/player/profile/player_badges_section.dart';
import 'package:get/get.dart';

import '../../components/player/profile/player_hero_section.dart';
import '../../components/player/profile/player_quick_stats.dart';
import '../../components/player/profile/sport_stats_view.dart';
import '../../core/config/constants.dart';
import '../../core/models/user_field_instance.dart';
import '../../core/models/user/player_stats_models.dart';
import '../../core/services/user_service.dart';

/// Route arguments: `{'userId': String}` — public profile user id.
class PlayerProfileScreen extends StatefulWidget {
  const PlayerProfileScreen({super.key});

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  UserFieldInstance? helper;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final userId = _parseUserId(Get.arguments);
    if (userId == null || userId.isEmpty) {
      _isLoading = false;
      _error = 'Player not found';
    } else {
      _loadProfile(userId);
    }
  }

  String? _parseUserId(dynamic raw) {
    if (raw is String && raw.isNotEmpty) return raw;
    if (raw is Map) {
      final id = raw['userId'];
      if (id is String && id.isNotEmpty) return id;
    }
    return null;
  }

  Future<void> _loadProfile(String userId) async {
    try {
      final user = await UserService().getPublicProfile(userId);
      if (!mounted) return;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _error = 'Player not found';
        });
        return;
      }

      if (!mounted) return;

      helper = UserFieldInstance(user);
      final availableSports = _getAvailableSports();
      _tabController?.dispose();
      _tabController = TabController(
        length: availableSports.length,
        vsync: this,
      );
      setState(() {
        _isLoading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Failed to load profile';
      });
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  List<SportType> _getAvailableSports() {
    final model = helper?.getModel();
    if (model?.playerSportStats.isEmpty ?? true) {
      return [SportType.football, SportType.cricket];
    }

    return model!.playerSportStats
        .map((entry) {
          return entry.sportType == 'cricket'
              ? SportType.cricket
              : SportType.football;
        })
        .toSet()
        .toList();
  }

  PlayerSportEntry? _getStatsForSport(SportType sport) {
    final model = helper?.getModel();
    if (model?.playerSportStats.isEmpty ?? true) return null;

    final sportStr = sport == SportType.cricket ? 'cricket' : 'football';
    try {
      return model!.playerSportStats.firstWhere(
        (entry) => entry.sportType == sportStr,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Player Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || helper == null || _tabController == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Player Profile')),
        body: Center(child: Text(_error ?? 'Player not found')),
      );
    }

    final availableSports = _getAvailableSports();
    final tabController = _tabController!;

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
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  PlayerQuickStats(helper: helper!),
                  const SizedBox(height: 24),
                  PlayerBadgesSection(badges: helper?.getModel()?.badges ?? []),
                ],
              ),
            ),
          ];
        },
        body: Column(
          children: [
            const SizedBox(height: 24),
            if (availableSports.isNotEmpty) ...[
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: tabController,
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
                  controller: tabController,
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
