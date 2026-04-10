import 'package:flutter/material.dart';

import '../../config/constants.dart';

/// Placeholder policy copy — replace with your final policy or load from CMS / WebView.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const String _lastUpdated = 'April 2026';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: const Text('Privacy Policy'),
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
              title: '1. Information we collect',
              body:
                  'We collect information you provide (such as name, email, and phone), booking and team activity necessary to operate the service, and technical data such as device type and app diagnostics to improve reliability and security.',
            ),
            _section(
              title: '2. How we use information',
              body:
                  'We use your information to provide bookings, notifications you opt into, customer support, fraud prevention, and to improve the product. We do not sell your personal information.',
            ),
            _section(
              title: '3. Sharing',
              body:
                  'We may share limited data with venues you book with (so they can fulfil your reservation), with service providers who assist our operations under strict agreements, or when required by law.',
            ),
            _section(
              title: '4. Security',
              body:
                  'We implement reasonable technical and organizational measures to protect your data. No method of transmission over the internet is completely secure.',
            ),
            _section(
              title: '5. Your choices',
              body:
                  'You can update profile information in the app, adjust notification preferences in Settings, and contact us to exercise applicable rights such as access or deletion where the law requires.',
            ),
            _section(
              title: '6. Contact',
              body:
                  'Privacy questions: privacy@example.com (replace with your privacy contact).',
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
