import 'package:flutter/material.dart';
import 'package:flutter_application_1/components/player/profile/player_badges_section.dart';
import 'package:get/get.dart';

import '../../components/player/profile/player_hero_section.dart';
import '../../components/player/profile/sport_stats_view.dart';
import '../../core/auth/auth_state_controller.dart';
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
  late final AuthStateController _authController;
  TabController? _tabController;
  int _tabsKey = 0;
  UserFieldInstance? helper;
  bool _isLoading = true;
  String? _error;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _authController = Get.find<AuthStateController>();
    _userId = _parseUserId(Get.arguments);
    if (_userId == null || _userId!.isEmpty) {
      _isLoading = false;
      _error = 'Player not found';
    } else {
      _loadProfile(_userId!);
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

  Future<void> _loadProfile(String userId, {bool isRefresh = false}) async {
    if (!isRefresh) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final user = isRefresh
          ? await _authController.refreshPublicProfile(userId)
          : await UserService().getPublicProfile(userId);
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
      _syncTabController(_getAvailableSports());
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

  Future<void> _refreshProfile() async {
    final userId = _userId;
    if (userId == null ||
        userId.isEmpty ||
        _authController.isRefreshingPublicProfile) {
      return;
    }
    await _loadProfile(userId, isRefresh: true);
  }

  Widget _buildRefreshAction({Color? iconColor}) {
    return Obx(() {
      final isRefreshing = _authController.isRefreshingPublicProfile;

      return IconButton(
        onPressed: isRefreshing ? null : _refreshProfile,
        icon: isRefreshing
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: iconColor ?? Theme.of(context).iconTheme.color,
                ),
              )
            : const Icon(Icons.refresh),
      );
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _syncTabController(List<SportType> sports) {
    if (_tabController != null && _tabController!.length == sports.length) {
      return;
    }
    _tabController?.dispose();
    _tabController = TabController(length: sports.length, vsync: this);
    _tabsKey++;
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
        appBar: AppBar(
          title: const Text('Player Profile'),
          actions: [_buildRefreshAction()],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || helper == null || _tabController == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Player Profile'),
          actions: [_buildRefreshAction()],
        ),
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
        actions: [_buildRefreshAction(iconColor: Colors.white)],
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
                  PlayerBadgesSection(badges: helper?.getModel()?.badges ?? []),
                ],
              ),
            ),
          ];
        },
        body: Column(
          key: ValueKey(_tabsKey),
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
