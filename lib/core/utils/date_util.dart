import 'package:intl/intl.dart';

/// Average Gregorian month length (365.25 / 12 days).
const double _secondsPerAvgMonth = 86400 * (365.25 / 12);

const double _secondsPerAvgYear = 86400 * 365.25;

String formatDateOnly(DateTime dt, String localeName) {
  return DateFormat('EEE, d MMM y', localeName).format(dt.toLocal());
}

String formatDateTime(String raw, String localeName) {
  try {
    return DateFormat(
      'EEE, d MMM y · HH:mm',
      localeName,
    ).format(DateTime.parse(raw).toLocal());
  } catch (_) {
    return raw;
  }
}

/// Relative time like `5 sec ago`, `2 hours ago`, `1.5 months ago`, `1.4 years ago`.
///
/// [reference] is parsed with [DateTime.parse] (after trim). If parsing fails,
/// returns [invalidDateLabel]. Otherwise it is compared to [clock] (defaults to
/// `DateTime.now()`); both sides use local time. Future dates return `just now`.
///
/// Rules: seconds → minutes → hours → days (integer); then fractional months
/// until 12 months; from 12 months onward only fractional years.
String timeAgo(
  String reference, {
  DateTime? clock,
  String invalidDateLabel = 'Invalid date',
}) {
  final DateTime past;
  try {
    past = DateTime.parse(reference.trim());
  } catch (_) {
    return invalidDateLabel;
  }

  final now = (clock ?? DateTime.now()).toLocal();
  var diff = now.difference(past.toLocal());
  if (diff.isNegative) {
    return 'just now';
  }

  final totalSeconds = diff.inSeconds;
  if (totalSeconds < 60) {
    return 'just now';
  }

  final minutes = diff.inMinutes;
  if (minutes < 60) {
    return minutes == 1 ? '1 min ago' : '$minutes min ago';
  }

  final hours = diff.inHours;
  if (hours < 24) {
    return hours == 1 ? '1 hour ago' : '$hours hours ago';
  }

  final days = diff.inDays;
  if (days < 30) {
    return days == 1 ? '1 day ago' : '$days days ago';
  }

  final monthsExact = totalSeconds / _secondsPerAvgMonth;
  if (monthsExact < 12) {
    final q = _oneDecimal(monthsExact);
    return '$q month ago';
  }

  final yearsExact = totalSeconds / _secondsPerAvgYear;
  final y = _oneDecimal(yearsExact);
  return '$y year ago';
}

/// One fractional digit; whole numbers without `.0`.
String _oneDecimal(double value) {
  final rounded = (value * 10).round() / 10;
  final whole = rounded.round();
  if ((rounded - whole).abs() < 1e-9) {
    return whole.toString();
  }
  return rounded.toStringAsFixed(1);
}
