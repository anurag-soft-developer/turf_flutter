import 'package:phone_numbers_parser/phone_numbers_parser.dart';

/// Normalize a phone to E.164. Requires an explicit country calling code
/// (leading `+`); national-only numbers are rejected.
String normalizePhone(String input) {
  final trimmed = input.trim();
  if (!trimmed.startsWith('+')) {
    throw const FormatException(
      'Phone must include country code, e.g. +919876543210',
    );
  }
  try {
    final parsed = PhoneNumber.parse(trimmed);
    if (!parsed.isValid()) {
      throw const FormatException('Invalid phone number');
    }
    return parsed.international;
  } catch (e) {
    if (e is FormatException) rethrow;
    throw const FormatException('Invalid phone number');
  }
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
/// Throws [FormatException] when the value is neither a valid email nor phone.
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
