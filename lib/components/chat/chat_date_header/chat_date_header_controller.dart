import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:get/get.dart';

class ChatDateHeaderController extends GetxController {
  ChatDateHeaderController({required this.date});

  final DateTime date;
  final label = ''.obs;

  @override
  void onInit() {
    super.onInit();
    label.value = formatLabel(date);
  }

  static String formatLabel(DateTime date) {
    final local = date.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(local.year, local.month, local.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('d MMM y').format(local);
  }

  static bool sameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    final left = a.toLocal();
    final right = b.toLocal();
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}
