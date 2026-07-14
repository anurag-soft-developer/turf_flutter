import 'package:phone_numbers_parser/phone_numbers_parser.dart';

/// Normalize a phone to E.164.
///
/// When [destinationCountry] is null, requires an explicit country calling code
/// (leading `+`). With a destination country, national numbers are accepted.
String normalizePhone(
  String input, {
  IsoCode? destinationCountry,
}) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) {
    throw const FormatException('Phone number is required');
  }

  if (destinationCountry == null && !trimmed.startsWith('+')) {
    throw const FormatException(
      'Phone must include country code, e.g. +919876543210',
    );
  }

  try {
    final parsed = PhoneNumber.parse(
      trimmed,
      destinationCountry: destinationCountry,
    );
    if (!parsed.isValid()) {
      throw const FormatException('Invalid phone number');
    }
    return parsed.international;
  } catch (e) {
    if (e is FormatException) rethrow;
    throw const FormatException('Invalid phone number');
  }
}

/// Digits-only national number (strips spaces, dashes, parentheses).
String extractNationalDigits(String input) {
  return input.replaceAll(RegExp(r'\D'), '');
}

/// True when [raw] looks like a phone rather than an email.
bool looksLikePhone(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty || trimmed.contains('@')) return false;
  if (trimmed.startsWith('+')) return true;

  final digits = extractNationalDigits(trimmed);
  if (digits.length < 7 || digits.length > 15) return false;

  // Allow common phone formatting characters only.
  return RegExp(r'^[\d\s\-().]+$').hasMatch(trimmed);
}

/// True when the value already includes an international dialing prefix (`+`).
bool hasPhoneCountryCode(String raw) {
  return raw.trim().startsWith('+');
}

/// Resolved auth contact: exactly one of [email] or [phone].
class AuthIdentifier {
  final String? email;
  final String? phone;

  const AuthIdentifier._({this.email, this.phone});

  factory AuthIdentifier.email(String email) =>
      AuthIdentifier._(email: email);

  factory AuthIdentifier.phone(String phone) =>
      AuthIdentifier._(phone: phone);

  bool get isEmail => email != null;
  bool get isPhone => phone != null;

  Map<String, dynamic> toJsonFields() => {
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
      };
}

/// Detect email (`@`) or phone (leading `+`) and normalize.
/// Throws [FormatException] when the value is neither a valid email nor phone
/// with country code. Prefer [resolveAuthIdentifier] when the UI can prompt
/// for a missing country code.
AuthIdentifier resolveIdentifier(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    throw const FormatException('Email or phone is required');
  }

  if (trimmed.contains('@')) {
    return AuthIdentifier.email(trimmed.toLowerCase());
  }

  if (trimmed.startsWith('+')) {
    return AuthIdentifier.phone(normalizePhone(trimmed));
  }

  throw const FormatException(
    'Enter an email or phone with country code (e.g. +919876543210)',
  );
}
