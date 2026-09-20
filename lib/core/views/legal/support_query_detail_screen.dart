import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:intl/intl.dart';

import '../../../components/shared/custom_button.dart';
import '../../../components/shared/custom_text_field.dart';
import '../../../support/model/support_query_model.dart';
import '../../../support/support_service.dart';
import '../../../support/util/support_display_helpers.dart';
import '../../components/app_bar/app_bar_background.dart';
import '../../config/constants.dart';
import '../../query/query_keys.dart';
import '../../query/query_retry.dart';
import '../../utils/app_snackbar.dart';
import '../../utils/exception_handler.dart';
import '../../utils/validators.dart';

class SupportQueryDetailScreen extends HookWidget {
  const SupportQueryDetailScreen({super.key, required this.queryId});

  final String queryId;

  @override
  Widget build(BuildContext context) {
    final service = useMemoized(SupportService.new);
    final replyController = useTextEditingController();
    final submitting = useState(false);
    final queryClient = useQueryClient();

    final detailQuery = useQuery<SupportQueryModel?, Object>(
      QueryKeys.supportQuery(queryId),
      (_) => service.getById(queryId),
      retry: noRetry,
    );

    final query = detailQuery.data;
    final resolved = query?.isResolved ?? false;

    Future<void> sendReply() async {
      final body = replyController.text.trim();
      if (body.isEmpty) {
        AppSnackbar.info(title: 'Message required', message: 'Enter a reply.');
        return;
      }
      if (resolved) return;

      submitting.value = true;
      try {
        await service.addReply(queryId, body);
        replyController.clear();
        await detailQuery.refetch();
        queryClient.invalidateQueries(
          queryKey: QueryKeys.supportQueriesPreview,
        );
        queryClient.invalidateQueries(
          queryKey: QueryKeys.supportQueriesHistoryPrefix,
        );
        AppSnackbar.success(title: 'Sent', message: 'Your reply was added.');
      } catch (e) {
        ExceptionHandler.handleException(e);
      } finally {
        submitting.value = false;
      }
    }

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppAppBar(title: Text(query?.subject ?? 'Support query')),
      body: detailQuery.isLoading && query == null
          ? const Center(child: CircularProgressIndicator())
          : detailQuery.isError && query == null
          ? Center(
              child: TextButton(
                onPressed: () => detailQuery.refetch(),
                child: const Text('Could not load query. Retry'),
              ),
            )
          : query == null
          ? const Center(child: Text('Query not found'))
          : RefreshIndicator(
              onRefresh: () async => detailQuery.refetch(),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _StatusHeader(query: query),
                  const SizedBox(height: 20),
                  _ThreadSection(query: query),
                  if (!resolved) ...[
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: replyController,
                      labelText: 'Your reply',
                      hintText: 'Add a follow-up message…',
                      maxLines: 4,
                      validator: (v) =>
                          Validators.validateRequired(v, 'Message'),
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Send reply',
                      isLoading: submitting.value,
                      onPressed: submitting.value ? null : sendReply,
                    ),
                  ] else
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'This query is resolved. Open a new message from Help & support if you need more help.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.query});

  final SupportQueryModel query;

  @override
  Widget build(BuildContext context) {
    final statusColor = supportStatusColor(query.status);
    final created = DateTime.tryParse(query.createdAt);

    return Card(
      elevation: 1,
      color: const Color(AppColors.surfaceColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: statusColor.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    supportStatusLabel(query.status),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            if (query.contactDisplay.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                query.contactDisplay,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(AppColors.textSecondaryColor),
                ),
              ),
            ],
            if (created != null) ...[
              const SizedBox(height: 8),
              Text(
                DateFormat('MMM d, yyyy · HH:mm').format(created.toLocal()),
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(AppColors.textSecondaryColor),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ThreadSection extends StatelessWidget {
  const _ThreadSection({required this.query});

  final SupportQueryModel query;

  @override
  Widget build(BuildContext context) {
    final replies = [...query.replies]
      ..sort(
        (a, b) =>
            DateTime.parse(a.createdAt).compareTo(DateTime.parse(b.createdAt)),
      );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Conversation',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(AppColors.textColor),
          ),
        ),
        const SizedBox(height: 12),
        _MessageBubble(
          body: query.message,
          isAdmin: false,
          createdAt: query.createdAt,
          label: 'You',
        ),
        for (final reply in replies)
          _MessageBubble(
            body: reply.body,
            isAdmin: reply.isPlatformAdmin,
            createdAt: reply.createdAt,
            label: reply.isPlatformAdmin ? 'Support' : 'You',
          ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.body,
    required this.isAdmin,
    required this.createdAt,
    required this.label,
  });

  final String body;
  final bool isAdmin;
  final String createdAt;
  final String label;

  @override
  Widget build(BuildContext context) {
    final parsed = DateTime.tryParse(createdAt);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: isAdmin ? Alignment.centerLeft : Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.85,
          ),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isAdmin
                ? const Color(AppColors.primaryColor).withValues(alpha: 0.08)
                : const Color(AppColors.surfaceColor),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isAdmin
                  ? const Color(AppColors.primaryColor).withValues(alpha: 0.2)
                  : const Color(AppColors.dividerColor),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isAdmin
                          ? const Color(AppColors.primaryColor)
                          : const Color(AppColors.textSecondaryColor),
                    ),
                  ),
                  if (parsed != null)
                    Text(
                      DateFormat('MMM d · HH:mm').format(parsed.toLocal()),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(AppColors.textSecondaryColor),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                body,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: Color(AppColors.textColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
