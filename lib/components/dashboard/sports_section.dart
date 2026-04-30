import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/config/constants.dart';

class SportsSection extends StatelessWidget {
  const SportsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final sports = [
      {
        'sport': 'Football',
        'icon': Icons.sports_soccer,
        'color': Colors.green,
        'gradient': [Colors.green.shade400, Colors.green.shade600],
        'subtitle': 'Most Popular',
      },
      {
        'sport': 'Cricket',
        'icon': Icons.sports_cricket,
        'color': Colors.orange,
        'gradient': [Colors.orange.shade400, Colors.orange.shade600],
        'subtitle': 'Team Sport',
      },
      {
        'sport': 'Basketball',
        'icon': Icons.sports_basketball,
        'color': Colors.deepOrange,
        'gradient': [Colors.deepOrange.shade400, Colors.deepOrange.shade600],
        'subtitle': 'Indoor/Outdoor',
      },
      {
        'sport': 'Badminton',
        'icon': Icons.sports_tennis,
        'color': Colors.blue,
        'gradient': [Colors.blue.shade400, Colors.blue.shade600],
        'subtitle': 'Singles/Doubles',
      },
      {
        'sport': 'All',
        'icon': Icons.sports,
        'color': const Color(AppColors.primaryColor),
        'gradient': [
          const Color(AppColors.primaryColor),
          const Color(AppColors.secondaryColor),
        ],
        'subtitle': 'View All',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),

        // Popular Sports with enhanced cards
        const Text(
          'Popular Sports',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(AppColors.textColor),
          ),
        ),
        const SizedBox(height: 16),

        // Sports cards in a single horizontal scroll row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: sports.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final card = _buildEnhancedSportCard(
                sport: item['sport'] as String,
                icon: item['icon'] as IconData,
                color: item['color'] as Color,
                gradient: item['gradient'] as List<Color>,
                subtitle: item['subtitle'] as String,
              );

              if (index == sports.length - 1) {
                return card;
              }

              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: card,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedSportCard({
    required String sport,
    required IconData icon,
    required Color color,
    required List<Color> gradient,
    required String subtitle,
  }) {
    return InkWell(
      onTap: () => _navigateToTurfList(sport),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 100,
        height: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned(
              right: -8,
              top: -8,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 24, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    sport,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToTurfList(String sport) {
    Get.toNamed(AppConstants.routes.turfList, arguments: {'sportType': sport});
  }
}
