import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../../components/shared/confirm_phone_dialog.dart';
import '../../../components/shared/custom_button.dart';
import '../../../components/shared/custom_text_field.dart';
import '../../../components/support/support_query_list_tile.dart';
import '../../../support/model/support_query_model.dart';
import '../../../support/support_service.dart';
import '../../../support/util/support_display_helpers.dart';
import '../../auth/auth_state_controller.dart';
import '../../components/app_bar/app_bar_background.dart';
import '../../config/constants.dart';
import '../../query/query_keys.dart';
import '../../query/query_retry.dart';
import '../../utils/app_snackbar.dart';
import '../../utils/exception_handler.dart';
import '../../utils/validators.dart';

class HelpSupportScreen extends HookWidget {
  const HelpSupportScreen({super.key});

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
          'Send a message below with your booking reference and a short description. We usually reply within one business day.',
    ),
  ];

  static const _subjectSuggestions = <String>[
    'How to invite a player to a team',
    'Got an issue with turf booking',
    'Payment deducted but booking not completed',
    'How to cancel or change a booking',
    'Can’t join or create a team',
    'Match-up / challenge not working',
    'Scoring issue',
    'Ranking looks wrong',
    'Account / login problem',
  ];

  @override
  Widget build(BuildContext context) {
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final subjectController = useTextEditingController();
    final subjectFocusNode = useFocusNode();
    final messageController = useTextEditingController();
    final contactController = useTextEditingController();
    final submitting = useState(false);
    final service = useMemoized(SupportService.new);
    final queryClient = useQueryClient();

    useEffect(() {
      final user = Get.find<AuthStateController>().user;
      if (user?.email != null && user!.email!.isNotEmpty) {
        contactController.text = user.email!;
      } else if (user?.phone != null && user!.phone!.isNotEmpty) {
        contactController.text = user.phone!;
      }
      return null;
    }, const []);

    useEffect(() {
      void openOptionsOnFocus() {
        if (subjectFocusNode.hasFocus) {
          subjectController.value = subjectController.value;
        }
      }

      subjectFocusNode.addListener(openOptionsOnFocus);
      return () => subjectFocusNode.removeListener(openOptionsOnFocus);
    }, [subjectFocusNode, subjectController]);

    final previewQuery = useQuery<List<SupportQueryModel>, Object>(
      QueryKeys.supportQueriesPreview,
      (_) async {
        final page = await service.listMine(page: 1, limit: 50);
        final all = page?.data ?? const <SupportQueryModel>[];
        return all.where((q) => isActiveSupportStatus(q.status)).toList();
      },
      retry: noRetry,
    );

    final activeQueries = previewQuery.data ?? const <SupportQueryModel>[];
    final previewQueries = activeQueries.take(5).toList();
    final showMyQueries =
        !previewQuery.isLoading && previewQueries.isNotEmpty;

    Future<void> submit() async {
      if (!formKey.currentState!.validate()) return;

      final identifier = await resolveAuthIdentifier(
        context,
        contactController.text,
      );
      if (identifier == null) return;

      if (identifier.phone != null) {
        contactController.text = identifier.phone!;
      }

      submitting.value = true;
      try {
        final created = await service.createQuery(
          CreateSupportQueryPayload(
            email: identifier.email,
            phone: identifier.phone,
            subject: subjectController.text.trim(),
            message: messageController.text.trim(),
          ),
        );
        if (created == null) {
          ExceptionHandler.showErrorToast('Could not send message');
          return;
        }

        subjectController.clear();
        messageController.clear();

        await queryClient.invalidateQueries(
          queryKey: QueryKeys.supportQueriesPreview,
        );
        await queryClient.invalidateQueries(
          queryKey: QueryKeys.supportQueriesHistoryPrefix,
        );

        AppSnackbar.success(
          title: 'Message sent',
          message:
              'Thanks for reaching out. We will get back to you at ${identifier.email ?? identifier.phone}.',
        );

        Get.toNamed(AppConstants.routes.supportQueryDetail(created.id));
      } catch (e) {
        ExceptionHandler.handleException(e);
      } finally {
        submitting.value = false;
      }
    }

    void openDetail(String id) {
      Get.toNamed(AppConstants.routes.supportQueryDetail(id));
    }

    void openHistory() {
      Get.toNamed(AppConstants.routes.supportQueries);
    }

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppAppBar(
        title: const Text('Help & support'),
        actions: [
          IconButton(
            onPressed: openHistory,
            tooltip: 'Query history',
            icon: const Icon(Icons.history_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => previewQuery.refetch(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle('Contact us'),
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
              if (showMyQueries) ...[
                const SizedBox(height: 32),
                Row(
                  children: [
                    const Expanded(child: _SectionTitle('My queries')),
                    TextButton(
                      onPressed: () =>
                          Get.toNamed(AppConstants.routes.supportQueries),
                      child: const Text('See all'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 1,
                  color: const Color(AppColors.surfaceColor),
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < previewQueries.length; i++) ...[
                        if (i > 0)
                          const Divider(
                            height: 1,
                            color: Color(AppColors.dividerColor),
                          ),
                        SupportQueryListTile(
                          query: previewQueries[i],
                          onTap: () => openDetail(previewQueries[i].id),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              const _SectionTitle('Send a query'),
              const SizedBox(height: 8),
              const Text(
                'Describe your issue. We will reply on your email or phone.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(AppColors.textSecondaryColor),
                ),
              ),
              const SizedBox(height: 16),
              Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CustomTextField(
                      controller: contactController,
                      labelText: 'Email or phone',
                      hintText: 'you@email.com or +919876543210',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(
                        Icons.alternate_email,
                        color: Color(AppColors.textSecondaryColor),
                      ),
                      validator: Validators.validateEmailOrPhone,
                    ),
                    const SizedBox(height: 16),
                    _SubjectAutocompleteField(
                      controller: subjectController,
                      focusNode: subjectFocusNode,
                      suggestions: _subjectSuggestions,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: messageController,
                      labelText: 'Message',
                      hintText: 'Tell us more…',
                      minLines: 4,
                      maxLines: 8,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      maxLength: 4000,
                      validator: (v) =>
                          Validators.validateRequired(v, 'Message'),
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      text: 'Send query',
                      onPressed: submitting.value ? null : submit,
                      isLoading: submitting.value,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const _SectionTitle('Frequently asked questions'),
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
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                        ),
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

class _SubjectAutocompleteField extends StatelessWidget {
  const _SubjectAutocompleteField({
    required this.controller,
    required this.focusNode,
    required this.suggestions,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final List<String> suggestions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'Subject',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(AppColors.textColor),
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            return Autocomplete<String>(
              textEditingController: controller,
              focusNode: focusNode,
              optionsBuilder: (value) {
                final query = value.text.trim().toLowerCase();
                if (query.isEmpty) return suggestions;
                return suggestions.where(
                  (option) => option.toLowerCase().contains(query),
                );
              },
              fieldViewBuilder:
                  (context, fieldController, fieldFocusNode, onFieldSubmitted) {
                return CustomTextField(
                  controller: fieldController,
                  focusNode: fieldFocusNode,
                  hintText: 'What is this about?',
                  textCapitalization: TextCapitalization.sentences,
                  onFieldSubmitted: (_) => onFieldSubmitted(),
                  suffixIcon: IconButton(
                    onPressed: () {
                      if (fieldFocusNode.hasFocus) {
                        fieldFocusNode.unfocus();
                      } else {
                        fieldFocusNode.requestFocus();
                      }
                    },
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Color(AppColors.textSecondaryColor),
                    ),
                  ),
                  validator: (v) {
                    final required = Validators.validateRequired(v, 'Subject');
                    if (required != null) return required;
                    if (v!.trim().length > 200) {
                      return 'Subject must be at most 200 characters';
                    }
                    return null;
                  },
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Material(
                  elevation: 4,
                  color: const Color(AppColors.surfaceColor),
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox(
                    width: constraints.maxWidth,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 240),
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          color: Color(AppColors.dividerColor),
                        ),
                        itemBuilder: (context, index) {
                          final option = options.elementAt(index);
                          return ListTile(
                            dense: true,
                            title: Text(
                              option,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(AppColors.textColor),
                              ),
                            ),
                            onTap: () => onSelected(option),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(AppColors.textColor),
      ),
    );
  }
}

class _FaqEntry {
  const _FaqEntry({required this.question, required this.answer});

  final String question;
  final String answer;
}
