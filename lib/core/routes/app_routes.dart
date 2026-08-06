/// Central list of named routes for the application.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';

  // Teacher
  static const String teacherDashboard = '/teacher/dashboard';
  static const String studentManagement = '/teacher/students';
  static const String studentForm = '/teacher/students/form';
  static const String studentDetail = '/teacher/students/detail';
  static const String topicManagement = '/teacher/topics';
  static const String topicForm = '/teacher/topics/form';
  static const String questionManagement = '/teacher/questions';
  static const String questionForm = '/teacher/questions/form';
  static const String aiGenerate = '/teacher/questions/ai-generate';
  static const String results = '/teacher/results';
  static const String teacherStatistics = '/teacher/statistics';

  // Student
  static const String studentDashboard = '/student/dashboard';
  static const String topicSelect = '/student/topics';
  static const String difficultySelect = '/student/difficulty';
  static const String quiz = '/student/quiz';
  static const String quizResult = '/student/result';
  static const String quizReview = '/student/review';
  static const String reviewWrongAnswers = '/student/review-wrong';
  static const String profile = '/student/profile';
  static const String history = '/student/history';
  static const String studentStatistics = '/student/statistics';

  // Shared
  static const String settings = '/settings';
  static const String about = '/about';
}
