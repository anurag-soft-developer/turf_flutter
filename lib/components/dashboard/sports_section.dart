import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/components/bottom_navigation_panel/navigation_controller.dart';
import '../../core/config/constants.dart';
import '../../core/config/sport_types.dart';

class SportsSection extends StatelessWidget {
  const SportsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final sports = SportTypes.catalog;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),

        const Text(
          'Find turf by sports',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(AppColors.textColor),
          ),
        ),
        const SizedBox(height: 16),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: sports.asMap().entries.map((entry) {
              final index = entry.key;
              final sport = entry.value;
              final card = _buildSportCard(sport: sport);

              if (index == sports.length - 1) {
                return card;
              }

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: card,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSportCard({required SportTypeConfig sport}) {
    return InkWell(
      onTap: () => _navigateToTurfList(sport.id),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 72,
        height: 88,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: sport.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: sport.color.withValues(alpha: 0.25),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(sport.icon, size: 22, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              sport.label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToTurfList(String sport) {
    if (Get.isRegistered<NavigationController>()) {
      Get.find<NavigationController>().goToTurfs(sportFilter: sport);
      return;
    }

    Get.toNamed(
      AppConstants.routes.turfList,
      arguments: {'sportType': sport},
    );
  }
}
