import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/config/constants.dart';
import '../../support/model/support_query_model.dart';
import '../../support/util/support_display_helpers.dart';

class SupportQueryListTile extends StatelessWidget {
  const SupportQueryListTile({
    super.key,
    required this.query,
    required this.onTap,
  });

  final SupportQueryModel query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = supportStatusColor(query.status);
    final created = DateTime.tryParse(query.createdAt);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      query.subject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(AppColors.textColor),
                      ),
                    ),
                    if (query.contactDisplay.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        query.contactDisplay,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(AppColors.textSecondaryColor),
                        ),
                      ),
                    ],
                    if (created != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM d, yyyy · HH:mm').format(created.toLocal()),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(AppColors.textSecondaryColor),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                ),
                child: Text(
                  supportStatusLabel(query.status),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor.withValues(alpha: 0.95),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                color: Color(AppColors.textSecondaryColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
