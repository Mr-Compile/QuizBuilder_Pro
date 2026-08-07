import 'package:shared_preferences/shared_preferences.dart';

/// Service to track quiz session state across the app.
/// Used to prevent students from logging out during an active quiz.
class QuizSessionService {
  final SharedPreferences _prefs;
  static const String _quizInProgressKey = 'quiz_in_progress';

  QuizSessionService(this._prefs);

  /// Marks a quiz as in progress.
  Future<void> startQuiz() async {
    await _prefs.setBool(_quizInProgressKey, true);
  }

  /// Marks a quiz as finished.
  Future<void> endQuiz() async {
    await _prefs.setBool(_quizInProgressKey, false);
  }

  /// Returns whether a quiz is currently in progress.
  bool get quizInProgress => _prefs.getBool(_quizInProgressKey) ?? false;
}
