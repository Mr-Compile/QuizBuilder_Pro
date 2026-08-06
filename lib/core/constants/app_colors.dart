import 'package:flutter/material.dart';

/// Static color palette used throughout QuizBuilder Pro.
/// These colors are intentionally simple so the theme files can mix them with
/// Material 3 dynamic colors.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF10B981); // Emerald Green
  static const Color secondary = Color(0xFF059669); // Darker Green
  static const Color accent = Color(0xFFF59E0B); // Amber

  // Action colors
  static const Color add = Color(0xFF22C55E); // Green
  static const Color edit = Color(0xFF3B82F6); // Blue
  static const Color delete = Color(0xFFEF4444); // Red
  static const Color cancel = Color(0xFF9CA3AF); // Gray
  static const Color startQuiz = Color(0xFF9333EA); // Purple
  static const Color finishQuiz = Color(0xFFF97316); // Orange
  static const Color login = Color(0xFF10B981); // Emerald Green
  static const Color logout = Color(0xFFEF4444); // Red

  // Background helpers
  static const Color correct = Color(0xFF86EFAC);
  static const Color incorrect = Color(0xFFFCA5A5);
  static const Color surfaceLight = Color(0xFFF8FAFC);
  static const Color surfaceDark = Color(0xFF1E293B);
}
