import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/config/constants.dart';
import '../../turf_booking/turf_booking_service.dart';
// import '../../core/utils/app_snackbar.dart';

class BookingAnalyticsSection extends StatelessWidget {
  const BookingAnalyticsSection({super.key, required this.statsFuture});

  final Future<TurfOwnerBookingStats?> statsFuture;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Booking Analytics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(AppColors.textColor),
            ),
          ),
          const SizedBox(height: 16),

          FutureBuilder<TurfOwnerBookingStats?>(
            future: statsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return _buildInfoMessage(
                  'Unable to load booking analytics right now.',
                );
              }

              final stats = snapshot.data;
              if (stats == null) {
                return _buildInfoMessage('No booking analytics available yet.');
              }

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Today\'s Bookings',
                          value: stats.todaysBookings.count.toInt().toString(),
                          icon: Icons.today,
                          color: Colors.blue,
                          trend: stats.todaysBookings.trend ?? '+0%',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          title: 'This Week',
                          value: stats.thisWeekBookings.count.toInt().toString(),
                          icon: Icons.calendar_view_week,
                          color: Colors.green,
                          trend: stats.thisWeekBookings.trend ?? '+0%',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Total Revenue',
                          value: _formatCurrency(stats.totalRevenue.count),
                          icon: Icons.currency_rupee,
                          color: Colors.orange,
                          trend: stats.totalRevenue.trend ?? '+0%',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Completion Rate',
                          value: '${stats.completionRate.count.toString()}%',
                          icon: Icons.check_circle,
                          color: Colors.purple,
                          trend: stats.completionRate.trend ?? '+0%',
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),

          // const SizedBox(height: 20),

          // Quick Action Button
          // SizedBox(
          //   width: double.infinity,
          //   child: ElevatedButton.icon(
          //     onPressed: () {
          //       AppSnackbar.comingSoon(feature: 'Detailed analytics');
          //     },
          //     icon: const Icon(Icons.analytics, size: 20),
          //     label: const Text('View Detailed Analytics'),
          //     style: ElevatedButton.styleFrom(
          //       backgroundColor: const Color(AppColors.primaryColor),
          //       foregroundColor: Colors.white,
          //       padding: const EdgeInsets.symmetric(vertical: 12),
          //       shape: RoundedRectangleBorder(
          //         borderRadius: BorderRadius.circular(8),
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String trend,
  }) {
    final isNegativeTrend = trend.trim().startsWith('-');
    final trendBackgroundColor = isNegativeTrend
        ? Colors.red.shade100
        : Colors.green.shade100;
    final trendTextColor = isNegativeTrend
        ? Colors.red.shade700
        : Colors.green.shade700;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: trendBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  trend,
                  style: TextStyle(
                    fontSize: 10,
                    color: trendTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoMessage(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        message,
        style: TextStyle(color: Colors.grey.shade700),
      ),
    );
  }

  String _formatCurrency(num value) {
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    return formatter.format(value);
  }
}
