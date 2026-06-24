import 'package:flutter/material.dart';
import 'package:flutter_application_1/components/shared/user_avatar_app_bar_action.dart';
import 'package:get/get.dart';

import '../components/player/profile/player_badges_section.dart';
import '../components/player/profile/player_hero_section.dart';
import '../components/player/profile/player_quick_stats.dart';
import '../components/player/profile/sport_stats_view.dart';
import '../core/auth/auth_state_controller.dart';
import '../core/config/constants.dart';
import '../core/models/user/player_stats_models.dart';
import '../core/models/user_field_instance.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final AuthStateController authController;
  TabController? _tabController;
  int _tabsKey = 0;

  @override
  void initState() {
    super.initState();
    authController = Get.find<AuthStateController>();
    _initTabs();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _initTabs() {
    final sports = _getAvailableSports();
    _tabController?.dispose();
    _tabController = TabController(length: sports.length, vsync: this);
    _tabsKey++;
  }

  Future<void> _onRefreshProfile() async {
    await authController.refreshUserProfile();
    if (!mounted) return;

    final sports = _getAvailableSports();
    if (_tabController?.length != sports.length) {
      _tabController?.dispose();
      _tabController = TabController(length: sports.length, vsync: this);
      _tabsKey++;
      setState(() {});
    }
  }

  List<SportType> _getAvailableSports() {
    final user = authController.user;
    if (user == null || user.playerSportStats.isEmpty) {
      return [SportType.football, SportType.cricket];
    }
    return user.playerSportStats
        .map((entry) {
          return entry.sportType == 'cricket'
              ? SportType.cricket
              : SportType.football;
        })
        .toSet()
        .toList();
  }

  PlayerSportEntry? _getStatsForSport(SportType sport) {
    final user = authController.user;
    if (user == null || user.playerSportStats.isEmpty) return null;
    final sportStr = sport == SportType.cricket ? 'cricket' : 'football';
    try {
      return user.playerSportStats.firstWhere(
        (entry) => entry.sportType == sportStr,
      );
    } catch (_) {
      return null;
    }
  }

  List<Widget> _buildProfileHeaderSlivers(UserFieldInstance helper) {
    return [
      SliverToBoxAdapter(child: PlayerHeroSection(helper: helper)),
      SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            PlayerBadgesSection(badges: helper.getModel()?.badges ?? []),
          ],
        ),
      ),
    ];
  }

  Widget _buildPlayerSportStatsBody(List<SportType> availableSports) {
    return Column(
      key: ValueKey(_tabsKey),
      children: [
        const SizedBox(height: 24),
        if (availableSports.isNotEmpty && _tabController != null) ...[
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(AppColors.primaryColor),
              unselectedLabelColor: const Color(AppColors.textSecondaryColor),
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
                style: TextStyle(color: Color(AppColors.textSecondaryColor)),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = authController.user;
      final isRefreshing = authController.isRefreshingUserProfile;
      final helper = UserFieldInstance(user);
      final availableSports = _getAvailableSports();

      return Scaffold(
        backgroundColor: const Color(AppColors.backgroundColor),
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: const UserAvatarAppBarAction(),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          title: const Text('My Profile'),
          actions: [
            IconButton(
              onPressed: isRefreshing ? null : _onRefreshProfile,
              icon: isRefreshing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.refresh),
            ),
            IconButton(
              onPressed: () => Get.toNamed(AppConstants.routes.editProfile),
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return _buildProfileHeaderSlivers(helper);
          },
          body: _buildPlayerSportStatsBody(availableSports),
        ),
      );
    });
  }
}
