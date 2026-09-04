import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/config/constants.dart';

/// Slim footer: label, full Mongo `_id`, copy.
class BookingReferenceCard extends StatelessWidget {
  final String? bookingId;
  final EdgeInsetsGeometry margin;

  const BookingReferenceCard({
    super.key,
    required this.bookingId,
    this.margin = EdgeInsets.zero,
  });

  static String displayReference(String? id) {
    if (id == null || id.isEmpty) return 'N/A';
    return id;
  }

  static void copyBookingId(BuildContext context, String? id) {
    if (id == null || id.isEmpty) return;
    Clipboard.setData(ClipboardData(text: id));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Booking ID copied'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final id = bookingId;
    final hasId = id != null && id.isNotEmpty;
    final display = displayReference(id);

    return Container(
      margin: margin,
      padding: const EdgeInsets.only(top: 10),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(AppColors.dividerColor)),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'Ref',
            style: TextStyle(
              fontSize: 11,
              color: Color(AppColors.textSecondaryColor),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              display,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(AppColors.textColor),
                letterSpacing: 0.3,
              ),
            ),
          ),
          if (hasId)
            InkWell(
              onTap: () => copyBookingId(context, id),
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.copy_rounded,
                  size: 14,
                  color: Color(AppColors.textSecondaryColor),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
