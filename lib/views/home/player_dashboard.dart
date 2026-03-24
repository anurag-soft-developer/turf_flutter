import 'package:flutter/material.dart';
import '../../components/turf/featured_section.dart';
import '../../components/dashboard/sports_section.dart';
import '../../components/dashboard/quick_actions_section.dart';

class PlayerDashboard extends StatelessWidget {
  const PlayerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Featured Turfs Section
          FeaturedTurfsSection(),
          const SizedBox(height: 16),

          // Sports Section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: SportsSection(),
          ),
          const SizedBox(height: 32),

          // Quick Actions Section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: QuickActionsSection(),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
