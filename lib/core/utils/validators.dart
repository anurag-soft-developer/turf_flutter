import 'package:validators/validators.dart' as validator;

import '../config/constants.dart';

class Validators {
  /// Matches NestJS: `(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]` with length 8–50.
  static final RegExp passwordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,50}$',
  );

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    if (!validator.isEmail(value)) {
      return 'Enter a valid email address';
    }

    return null;
  }

  /// Rules aligned with [passwordRegex] / NestJS. Empty input returns only the required message.
  static List<String> passwordRequirementErrors(String? value) {
    final s = value ?? '';
    if (s.isEmpty) {
      return ['Password is required'];
    }

    final errors = <String>[];

    if (s.length < 8 || s.length > 50) {
      errors.add('Password must be between 8 and 50 characters');
    }
    if (!RegExp(r'[a-z]').hasMatch(s)) {
      errors.add('At least one lowercase letter is required');
    }
    if (!RegExp(r'[A-Z]').hasMatch(s)) {
      errors.add('At least one uppercase letter is required');
    }
    if (!RegExp(r'\d').hasMatch(s)) {
      errors.add('At least one number is required');
    }
    if (!RegExp(r'[@$!%*?&]').hasMatch(s)) {
      errors.add(r'At least one special character is required (@$!%*?&)');
    }
    if (!RegExp(r'^[A-Za-z\d@$!%*?&]+$').hasMatch(s)) {
      errors.add(r'Only letters, numbers, and @$!%*?& are allowed');
    }

    return errors;
  }

  /// Sign-up / new password: multiple errors as separate lines under the field.
  static String? validatePassword(String? value) {
    final errors = passwordRequirementErrors(value);
    if (errors.isEmpty) return null;
    return errors.join('\n');
  }

  /// Login (existing password): do not enforce policy rules.
  static String? validateLoginPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (!validator.equals(value, password)) {
      return 'Passwords do not match';
    }

    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }

    if (!validator.isLength(value, 2)) {
      return 'Name must be at least 2 characters long';
    }

    if (value.length > 50) {
      return 'Name must be less than 50 characters';
    }

    if (!validator.isAlpha(value)) {
      return 'Name must contain only letters';
    }

    return null;
  }

  static String? validateOtp(String? value) {
    if (value == null || value.isEmpty) {
      return 'OTP is required';
    }
    if (!validator.isNumeric(value)) {
      return 'OTP must contain only numbers';
    }
    if (value.length != AppConstants.otp.length) {
      return 'OTP must be ${AppConstants.otp.length} digits';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return null; // URL is optional
    }

    if (!validator.isURL(value)) {
      return 'Enter a valid URL';
    }

    return null;
  }

  static String? validateCreditCard(String? value) {
    if (value == null || value.isEmpty) {
      return 'Credit card number is required';
    }

    if (!validator.isCreditCard(value)) {
      return 'Enter a valid credit card number';
    }

    return null;
  }

  static String? validateNumeric(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    if (!validator.isNumeric(value)) {
      return '$fieldName must be a number';
    }

    return null;
  }

  static String? validateAlphaNumeric(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    if (!validator.isAlphanumeric(value)) {
      return '$fieldName must contain only letters and numbers';
    }

    return null;
  }
}
