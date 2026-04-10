import 'package:flutter/material.dart';

import '../../config/constants.dart';

/// Placeholder legal copy — replace with your final terms or load from CMS / WebView.
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  static const String _lastUpdated = 'April 2026';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        backgroundColor: const Color(AppColors.primaryColor),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last updated: $_lastUpdated',
              style: const TextStyle(
                fontSize: 13,
                color: Color(AppColors.textSecondaryColor),
              ),
            ),
            const SizedBox(height: 24),
            _section(
              title: '1. Agreement',
              body:
                  'By accessing or using this application, you agree to be bound by these Terms & Conditions. If you do not agree, please do not use the service.',
            ),
            _section(
              title: '2. Use of the service',
              body:
                  'You may use the app to browse turfs, make bookings, manage teams, and related features offered from time to time. You agree to provide accurate information and to keep your account credentials secure.',
            ),
            _section(
              title: '3. Bookings and payments',
              body:
                  'Bookings are subject to availability and venue-specific rules. Fees, refunds, and cancellations are governed by the policies shown at the time of booking and by agreements between you and the venue or operator.',
            ),
            _section(
              title: '4. Acceptable use',
              body:
                  'You must not misuse the service, attempt to gain unauthorized access, harass other users, or use the app for unlawful purposes. We may suspend or terminate access for violations.',
            ),
            _section(
              title: '5. Changes',
              body:
                  'We may update these terms periodically. Continued use after changes constitutes acceptance of the revised terms. Material changes may be communicated through the app or by email where appropriate.',
            ),
            _section(
              title: '6. Contact',
              body:
                  'Questions about these terms can be sent to support@example.com.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _section({required String title, required String body}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(AppColors.textColor),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 15,
              height: 1.55,
              color: Color(AppColors.textSecondaryColor),
            ),
          ),
        ],
      ),
    );
  }
}
