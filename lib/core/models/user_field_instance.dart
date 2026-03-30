import 'user/user_model.dart';

/// Instance-based helper for working with dynamic user fields
///
/// Usage: final helper = UserFieldInstance(userField);
/// Then: helper.getId(), helper.getName(), etc.
class UserFieldInstance {
  final dynamic _user;

  UserFieldInstance(this._user);

  /// Gets the user ID from the field
  String? getId() {
    if (_user is String) return _user;
    if (_user is UserModel) return _user.id;
    return null;
  }

  /// Gets the UserModel from the field (null if just an ID)
  UserModel? getModel() {
    if (_user is UserModel) return _user;
    return null;
  }

  /// Gets the display name with fallback logic
  String? getName() {
    if (_user is UserModel) {
      return _user.fullName ?? _user.email?.split('@').first;
    }
    return null;
  }

  /// Gets the email
  String? getEmail() {
    if (_user is UserModel) {
      return _user.email;
    }
    return null;
  }

  /// Gets the avatar URL
  String? getAvatar() {
    if (_user is UserModel) {
      return _user.avatar;
    }
    return null;
  }

  /// Gets display name with fallback for unknown users
  String getDisplayName() {
    final name = getName();
    return name ?? 'Unknown User';
  }

  /// Checks if the field has a populated user model
  bool get isPopulated => _user is UserModel;

  /// Checks if the field is just an ID
  bool get isIdOnly => _user is String;
}
