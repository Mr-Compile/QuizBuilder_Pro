/// Represents the result of a validation operation.
class ValidationResult {
  final bool isValid;
  final Map<String, String> errors;
  final String? globalError;

  const ValidationResult({
    required this.isValid,
    this.errors = const {},
    this.globalError,
  });

  /// Creates a successful validation result.
  factory ValidationResult.success() {
    return const ValidationResult(isValid: true);
  }

  /// Creates a failed validation result with field errors.
  factory ValidationResult.failure(Map<String, String> errors) {
    return ValidationResult(
      isValid: false,
      errors: errors,
    );
  }

  /// Creates a failed validation result with a global error.
  factory ValidationResult.globalFailure(String error) {
    return ValidationResult(
      isValid: false,
      globalError: error,
    );
  }

  /// Adds an error to a specific field.
  ValidationResult addError(String field, String error) {
    final newErrors = Map<String, String>.from(errors);
    newErrors[field] = error;
    return ValidationResult(
      isValid: false,
      errors: newErrors,
      globalError: globalError,
    );
  }

  /// Gets the error for a specific field.
  String? getError(String field) {
    return errors[field];
  }

  /// Checks if a specific field has an error.
  bool hasError(String field) {
    return errors.containsKey(field);
  }

  /// Gets all error messages as a list.
  List<String> get allErrors {
    return [...errors.values, if (globalError != null) globalError!];
  }
}
