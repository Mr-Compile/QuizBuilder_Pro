/// Global, human-readable constants used by the QuizBuilder Pro app.
class AppConstants {
  AppConstants._();

  static const String appName = 'QuizBuilder Pro';
  static const String appTagline = 'Create, learn, and practice quizzes online or offline.';

  static const String defaultTeacherUsername = 'teacher';
  static const String defaultTeacherPassword = 'Teacher123!';

  static const String roleTeacher = 'teacher';
  static const String roleStudent = 'student';

  static const String sourceManual = 'manual';
  static const String sourceAi = 'ai';

  static const String difficultyEasy = 'Easy';
  static const String difficultyMedium = 'Medium';
  static const String difficultyHard = 'Hard';

  static const String groqEndpoint = 'https://api.groq.com/openai/v1/chat/completions';
  static const String groqModel = 'llama-3.1-8b-instant';

  static const String prefsSessionUserId = 'sessionUserId';
  static const String prefsSessionRole = 'sessionRole';
  static const String prefsApiKey = 'groqApiKey';
  static const String prefsTheme = 'appTheme';

  // AI Generation Quota Constants
  static const int teacherDailyQuota = 10;
  static const int studentDailyQuota = 0;
  static const String prefsLastQuotaResetDate = 'lastQuotaResetDate';
}
