import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/constants.dart';

class SportsSection extends StatelessWidget {
  const SportsSection({super.key});

  @override
  Widget build(BuildContext context) {
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

        // Sports cards with proper spacing
        LayoutBuilder(
          builder: (context, constraints) {
            // Calculate number of cards per row based on screen width
            const cardWidth = 140.0;
            const minSpacing = 16.0;
            final availableWidth = constraints.maxWidth;
            final cardsPerRow = (availableWidth / (cardWidth + minSpacing))
                .floor()
                .clamp(2, 3);

            // Group sports into rows
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
                'gradient': [
                  Colors.deepOrange.shade400,
                  Colors.deepOrange.shade600,
                ],
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
              children: [
                for (int i = 0; i < sports.length; i += cardsPerRow)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: i + cardsPerRow < sports.length ? 16 : 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (
                          int j = 0;
                          j < cardsPerRow && i + j < sports.length;
                          j++
                        )
                          _buildEnhancedSportCard(
                            sport: sports[i + j]['sport'] as String,
                            icon: sports[i + j]['icon'] as IconData,
                            color: sports[i + j]['color'] as Color,
                            gradient: sports[i + j]['gradient'] as List<Color>,
                            subtitle: sports[i + j]['subtitle'] as String,
                          ),
                        // Add spacers for incomplete rows
                        for (
                          int k = i + cardsPerRow;
                          k < i + cardsPerRow && k >= sports.length;
                          k++
                        )
                          const SizedBox(width: 140),
                      ],
                    ),
                  ),
              ],
            );
          },
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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 140,
        height: 160,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned(
              right: -10,
              top: -10,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, size: 36, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    sport,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
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
