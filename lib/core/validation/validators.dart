/// Common validator functions for form fields.
/// Provides reusable validation logic across the application.
class Validators {
  Validators._();

  /// Validates that a field is not empty.
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null ? '$fieldName is required' : 'This field is required';
    }
    return null;
  }

  /// Validates minimum length.
  static String? minLength(String? value, int minLength, {String? fieldName}) {
    if (value != null && value.length < minLength) {
      return fieldName != null 
          ? '$fieldName must be at least $minLength characters'
          : 'Must be at least $minLength characters';
    }
    return null;
  }

  /// Validates maximum length.
  static String? maxLength(String? value, int maxLength, {String? fieldName}) {
    if (value != null && value.length > maxLength) {
      return fieldName != null 
          ? '$fieldName must not exceed $maxLength characters'
          : 'Must not exceed $maxLength characters';
    }
    return null;
  }

  /// Validates email format.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Validates that a field contains only alphanumeric characters and spaces.
  static String? alphanumeric(String? value, {String? fieldName}) {
    if (value != null && !RegExp(r'^[a-zA-Z0-9\s]+$').hasMatch(value)) {
      return fieldName != null 
          ? '$fieldName can only contain letters, numbers, and spaces'
          : 'Can only contain letters, numbers, and spaces';
    }
    return null;
  }

  /// Validates that a field contains only letters and spaces.
  static String? lettersOnly(String? value, {String? fieldName}) {
    if (value != null && !RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return fieldName != null 
          ? '$fieldName can only contain letters and spaces'
          : 'Can only contain letters and spaces';
    }
    return null;
  }

  /// Validates username format (alphanumeric with underscores).
  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    if (value.length > 20) {
      return 'Username must not exceed 20 characters';
    }
    return null;
  }

  /// Validates password strength.
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Password must contain at least one special character';
    }
    return null;
  }

  /// Validates that a number is within a range.
  static String? numberRange(String? value, num min, num max, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null ? '$fieldName is required' : 'This field is required';
    }
    final number = num.tryParse(value);
    if (number == null) {
      return 'Please enter a valid number';
    }
    if (number < min || number > max) {
      return fieldName != null 
          ? '$fieldName must be between $min and $max'
          : 'Must be between $min and $max';
    }
    return null;
  }

  /// Validates that a field matches another field (e.g., password confirmation).
  static String? match(String? value, String? otherValue, {String? fieldName}) {
    if (value != otherValue) {
      return fieldName != null 
          ? '$fieldName does not match'
          : 'Fields do not match';
    }
    return null;
  }

  /// Composes multiple validators into a single validator function.
  static String? Function(String?) compose(List<String? Function(String?)> validators) {
    return (value) {
      for (final validator in validators) {
        final result = validator(value);
        if (result != null) {
          return result;
        }
      }
      return null;
    };
  }
}
