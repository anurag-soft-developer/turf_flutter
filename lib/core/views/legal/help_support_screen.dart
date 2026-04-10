import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../components/shared/custom_button.dart';
import '../../../components/shared/custom_text_field.dart';
import '../../auth/auth_state_controller.dart';
import '../../config/constants.dart';
import '../../utils/app_snackbar.dart';
import '../../utils/validators.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _emailController = TextEditingController();

  bool _submitting = false;

  static const _faqs = <_FaqEntry>[
    _FaqEntry(
      question: 'How do I book a turf?',
      answer:
          'Open Browse Turfs, pick a venue, choose a date and time slot, then confirm your booking. You can view upcoming sessions under My Bookings.',
    ),
    _FaqEntry(
      question: 'Can I cancel or change a booking?',
      answer:
          'Cancellation and changes depend on the turf’s policy. Open the booking from My Bookings and use the options shown there, or contact the venue directly.',
    ),
    _FaqEntry(
      question: 'How do teams work?',
      answer:
          'Create or join a team from My Teams. Owners can invite members; you can see rankings and team activity from the Teams section.',
    ),
    _FaqEntry(
      question: 'Who do I contact for payment issues?',
      answer:
          'Email support@example.com with your booking reference and a short description. We usually reply within one business day.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    final email = Get.find<AuthStateController>().user?.email;
    if (email != null && email.isNotEmpty) {
      _emailController.text = email;
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _submitting = false);
    _subjectController.clear();
    _messageController.clear();
    AppSnackbar.success(
      title: 'Message sent',
      message:
          'Thanks for reaching out. We will get back to you at ${_emailController.text.trim()}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: const Text('Help & support'),
        backgroundColor: const Color(AppColors.primaryColor),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contact us',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(AppColors.textColor),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 1,
              color: const Color(AppColors.surfaceColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _contactRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: 'support@example.com',
                    ),
                    const SizedBox(height: 16),
                    _contactRow(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: '+1 (555) 010-2030',
                    ),
                    const SizedBox(height: 16),
                    _contactRow(
                      icon: Icons.schedule_outlined,
                      label: 'Hours',
                      value: 'Mon–Fri, 9:00–18:00 (local time)',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Send a message',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(AppColors.textColor),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Describe your issue and we will reply by email.',
              style: TextStyle(
                fontSize: 14,
                color: Color(AppColors.textSecondaryColor),
              ),
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomTextField(
                    controller: _emailController,
                    labelText: 'Your email',
                    hintText: 'name@example.com',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(
                      Icons.alternate_email,
                      color: Color(AppColors.textSecondaryColor),
                    ),
                    validator: Validators.validateEmail,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _subjectController,
                    labelText: 'Subject',
                    hintText: 'What is this about?',
                    validator: (v) => Validators.validateRequired(v, 'Subject'),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _messageController,
                    labelText: 'Message',
                    hintText: 'Tell us more…',
                    maxLines: 5,
                    validator: (v) => Validators.validateRequired(v, 'Message'),
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: 'Send message',
                    onPressed: _submitting ? null : () => _submit(),
                    isLoading: _submitting,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(height: 24),
            const Text(
              'Frequently asked questions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(AppColors.textColor),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 1,
              color: const Color(AppColors.surfaceColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < _faqs.length; i++) ...[
                    if (i > 0)
                      const Divider(
                        height: 1,
                        color: Color(AppColors.dividerColor),
                      ),
                    Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        childrenPadding: const EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          16,
                        ),
                        iconColor: const Color(AppColors.primaryColor),
                        collapsedIconColor: const Color(
                          AppColors.textSecondaryColor,
                        ),
                        title: Text(
                          _faqs[i].question,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Color(AppColors.textColor),
                          ),
                        ),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _faqs[i].answer,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.45,
                                color: Color(AppColors.textSecondaryColor),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _contactRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: const Color(AppColors.primaryColor)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(AppColors.textSecondaryColor),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(AppColors.textColor),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FaqEntry {
  const _FaqEntry({required this.question, required this.answer});

  final String question;
  final String answer;
}
