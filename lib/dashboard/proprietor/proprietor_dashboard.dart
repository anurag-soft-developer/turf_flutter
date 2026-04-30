import 'package:flutter/material.dart';
import '../../components/dashboard/booking_analytics_section.dart';
import '../../components/dashboard/turf_management_section.dart';
import '../../turf_booking/turf_booking_service.dart';

class ProprietorDashboard extends StatelessWidget {
  const ProprietorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final statsFuture = TurfBookingService().getTurfOwnerBookingStats();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Spacing from top
          const SizedBox(height: 24),

          // Booking Analytics Section
          BookingAnalyticsSection(statsFuture: statsFuture),
          const SizedBox(height: 32),

          // Turf Management Section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: TurfManagementSection(),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
