import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/config/constants.dart';

/// Booking reference row: label, short id, copy — same chrome as the ticket screen.
class BookingReferenceCard extends StatelessWidget {
  final String? bookingId;
  final EdgeInsetsGeometry margin;

  const BookingReferenceCard({
    super.key,
    required this.bookingId,
    this.margin = const EdgeInsets.only(bottom: 24),
  });

  static String displayReference(String? id) {
    if (id == null || id.isEmpty) return '#N/A';
    final short = id.length >= 8 ? id.substring(0, 8) : id;
    return '#$short';
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(AppColors.primaryColor).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(AppColors.primaryColor).withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(AppColors.primaryColor).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.confirmation_number_outlined,
              color: Color(AppColors.primaryColor),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Booking Reference',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  display,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(AppColors.primaryColor),
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          if (hasId)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => copyBookingId(context, id),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(AppColors.primaryColor).withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.copy,
                    color: Color(AppColors.primaryColor),
                    size: 18,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
