import 'package:intl/intl.dart';

/// Simple helper functions used by multiple features.
class Helpers {
  Helpers._();

  /// Formats a [DateTime] to a readable local string.
  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }

  /// Rounds a double to [fractionDigits] decimals.
  static double round(double value, {int fractionDigits = 1}) {
    final mult = pow(10, fractionDigits);
    return (value * mult).roundToDouble() / mult;
  }

  /// Capitalizes the first letter of a string.
  static String capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}

/// Minimal `pow` helper to avoid importing `dart:math` everywhere.
double pow(double base, int exponent) {
  double result = 1;
  for (int i = 0; i < exponent; i++) {
    result *= base;
  }
  return result;
}
