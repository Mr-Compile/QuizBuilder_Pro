import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'validation_result.dart';

/// A mixin that provides common form validation functionality.
/// Use this in form State classes to get consistent validation behavior.
mixin FormValidationMixin on State<StatefulWidget> {
  final Map<String, String> _fieldErrors = {};
  bool _isSubmitting = false;

  /// Gets the current field errors.
  Map<String, String> get fieldErrors => Map.unmodifiable(_fieldErrors);

  /// Gets whether the form is currently submitting.
  bool get isSubmitting => _isSubmitting;

  /// Sets the submitting state.
  void setSubmitting(bool submitting) {
    setState(() {
      _isSubmitting = submitting;
    });
  }

  /// Clears all field errors.
  void clearErrors() {
    setState(() {
      _fieldErrors.clear();
    });
  }

  /// Clears error for a specific field.
  void clearFieldError(String field) {
    setState(() {
      _fieldErrors.remove(field);
    });
  }

  /// Sets an error for a specific field.
  void setFieldError(String field, String error) {
    setState(() {
      _fieldErrors[field] = error;
    });
  }

  /// Gets the error for a specific field.
  String? getFieldError(String field) {
    return _fieldErrors[field];
  }

  /// Checks if a specific field has an error.
  bool hasFieldError(String field) {
    return _fieldErrors.containsKey(field);
  }

  /// Validates a single field using a validator function.
  bool validateField(String field, String? value, String? Function(String?) validator) {
    final error = validator(value);
    if (error != null) {
      setFieldError(field, error);
      return false;
    }
    clearFieldError(field);
    return true;
  }

  /// Validates multiple fields at once.
  ValidationResult validateFields(Map<String, String?> fields, Map<String, String? Function(String?)> validators) {
    final errors = <String, String>{};
    
    for (final entry in fields.entries) {
      final field = entry.key;
      final value = entry.value;
      final validator = validators[field];
      
      if (validator != null) {
        final error = validator(value);
        if (error != null) {
          errors[field] = error;
        }
      }
    }
    
    if (errors.isNotEmpty) {
      setState(() {
        _fieldErrors.addAll(errors);
      });
      return ValidationResult.failure(errors);
    }
    
    clearErrors();
    return ValidationResult.success();
  }

  /// Shows a snackbar with validation errors.
  void showValidationErrors(BuildContext context, ValidationResult result) {
    if (result.globalError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.globalError!),
          backgroundColor: Colors.red,
        ),
      );
    } else if (result.errors.isNotEmpty) {
      final firstError = result.errors.values.first;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(firstError),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Formats text input to restrict to specific characters.
  TextInputFormatter createInputFormatter({
    bool allowLetters = true,
    bool allowNumbers = true,
    bool allowSpaces = true,
    bool allowSpecialChars = false,
    String customPattern = '',
  }) {
    String pattern;
    if (customPattern.isNotEmpty) {
      pattern = customPattern;
    } else {
      final patterns = <String>[];
      if (allowLetters) patterns.add(r'a-zA-Z');
      if (allowNumbers) patterns.add(r'0-9');
      if (allowSpaces) patterns.add(r'\s');
      if (allowSpecialChars) patterns.add(r'!@#$%^&*()_+-=[]{}|;:,.<>?');
      pattern = '[${patterns.join('')}]';
    }
    
    return FilteringTextInputFormatter.allow(RegExp(pattern));
  }

  /// Disposes of resources used by the mixin.
  void disposeValidation() {
    _fieldErrors.clear();
  }
}
