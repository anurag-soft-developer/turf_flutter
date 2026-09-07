import 'package:flutter/material.dart';
import 'package:flutter_application_1/chat/model/chat_models.dart';
import 'package:flutter_application_1/chat/model/chat_scope.dart';
import 'package:flutter_application_1/components/shared/app_network_image.dart';
import 'package:flutter_application_1/core/config/constants.dart';
import 'package:flutter_application_1/core/utils/date_util.dart';

class ChatInboxTile extends StatelessWidget {
  const ChatInboxTile({
    super.key,
    required this.item,
    required this.onTap,
    this.selected = false,
    this.isSelecting = false,
    this.onLongPress,
  });

  static const Color _primary = Color(AppColors.primaryColor);

  final ChatInboxItem item;
  final bool selected;
  final bool isSelecting;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.imageUrl;
    final timeLabel =
        item.lastMessageAt.isEmpty ? '' : timeAgo(item.lastMessageAt);
    final unread = item.unreadCount > 0;

    return Material(
      color: selected
          ? _primary.withValues(alpha: 0.12)
          : const Color(AppColors.backgroundColor),
      child: ListTile(
        onTap: onTap,
        onLongPress: onLongPress,
        leading: isSelecting
            ? Checkbox(
                value: selected,
                onChanged: (_) => onTap(),
                activeColor: _primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              )
            : CircleAvatar(
                backgroundColor: _primary.withValues(alpha: 0.12),
                backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                    ? AppNetworkImage.provider(imageUrl)
                    : null,
                child: imageUrl == null || imageUrl.isEmpty
                    ? Icon(
                        _iconForScope(item.scope),
                        color: _primary,
                      )
                    : null,
              ),
        title: Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
            color: const Color(AppColors.textColor),
          ),
        ),
        subtitle: Text(
          item.lastMessageBody,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
            color: const Color(AppColors.textSecondaryColor),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (timeLabel.isNotEmpty)
              Text(
                timeLabel,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(AppColors.textSecondaryColor),
                ),
              ),
            if (unread) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  item.unreadCount > 99 ? '99+' : '${item.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _iconForScope(ChatScope scope) {
    return switch (scope) {
      ChatScope.team => Icons.groups_outlined,
      ChatScope.match => Icons.sports_soccer_outlined,
      ChatScope.player => Icons.person_outline,
    };
  }
}
