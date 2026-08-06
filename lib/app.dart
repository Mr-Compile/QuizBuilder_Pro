import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants/app_constants.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/splash_screen.dart';
import 'features/question/ai_generate_screen.dart';
import 'features/teacher/question_form_screen.dart';
import 'features/teacher/question_management_screen.dart';
import 'features/quiz/difficulty_selection_screen.dart';
import 'features/quiz/quiz_result_screen.dart';
import 'features/quiz/quiz_review_screen.dart';
import 'features/quiz/quiz_screen.dart';
import 'features/quiz/review_wrong_answers_screen.dart';
import 'features/quiz/topic_selection_screen.dart';
import 'features/settings/about_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/statistics/student_statistics_screen.dart';
import 'features/statistics/teacher_statistics_screen.dart';
import 'features/student/history_screen.dart';
import 'features/student/profile_screen.dart';
import 'features/student/student_dashboard_screen.dart';
import 'features/teacher/results_screen.dart';
import 'features/teacher/student_detail_screen.dart';
import 'features/teacher/student_form_screen.dart';
import 'features/teacher/student_management_screen.dart';
import 'features/teacher/teacher_dashboard_screen.dart';
import 'features/teacher/topic_form_screen.dart';
import 'features/teacher/topic_management_screen.dart';

/// Root widget of the application.
class QuizBuilderProApp extends StatefulWidget {
  const QuizBuilderProApp({super.key});

  static final GlobalKey<QuizBuilderProAppState> globalKey = GlobalKey();

  static QuizBuilderProAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<QuizBuilderProAppState>();
  }

  @override
  State<QuizBuilderProApp> createState() => QuizBuilderProAppState();
}

class QuizBuilderProAppState extends State<QuizBuilderProApp> {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(AppConstants.prefsTheme);
    setState(() {
      _themeMode = _parseTheme(saved);
    });
  }

  ThemeMode _parseTheme(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    String value;
    switch (mode) {
      case ThemeMode.light:
        value = 'light';
        break;
      case ThemeMode.dark:
        value = 'dark';
        break;
      default:
        value = 'system';
    }
    await prefs.setString(AppConstants.prefsTheme, value);
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: _onGenerateRoute,
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    final name = settings.name;
    final args = settings.arguments as Map<String, dynamic>?;

    switch (name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case AppRoutes.teacherDashboard:
        return MaterialPageRoute(builder: (_) => const TeacherDashboardScreen());
      case AppRoutes.studentManagement:
        return MaterialPageRoute(builder: (_) => const StudentManagementScreen());
      case AppRoutes.studentForm:
        return MaterialPageRoute(builder: (_) => StudentFormScreen(user: args?['user']));
      case AppRoutes.studentDetail:
        return MaterialPageRoute(builder: (_) => StudentDetailScreen(student: args?['student']));
      case AppRoutes.topicManagement:
        return MaterialPageRoute(builder: (_) => const TopicManagementScreen());
      case AppRoutes.topicForm:
        return MaterialPageRoute(builder: (_) => TopicFormScreen(topic: args?['topic']));
      case AppRoutes.questionManagement:
        return MaterialPageRoute(builder: (_) => const QuestionManagementScreen());
      case AppRoutes.questionForm:
        return MaterialPageRoute(builder: (_) => QuestionFormScreen(question: args?['question']));
      case AppRoutes.aiGenerate:
        return MaterialPageRoute(builder: (_) => const AiGenerateScreen());
      case AppRoutes.results:
        return MaterialPageRoute(builder: (_) => const ResultsScreen());
      case AppRoutes.teacherStatistics:
        return MaterialPageRoute(builder: (_) => const TeacherStatisticsScreen());
      case AppRoutes.studentDashboard:
        return MaterialPageRoute(builder: (_) => const StudentDashboardScreen());
      case AppRoutes.topicSelect:
        return MaterialPageRoute(builder: (_) => const TopicSelectionScreen());
      case AppRoutes.difficultySelect:
        return MaterialPageRoute(
          builder: (_) => DifficultySelectionScreen(topic: args?['topic']),
        );
      case AppRoutes.quiz:
        return MaterialPageRoute(
          builder: (_) => QuizScreen(
            topic: args?['topic'],
            difficulty: args?['difficulty'],
          ),
        );
      case AppRoutes.quizResult:
        return MaterialPageRoute(
          builder: (_) => QuizResultScreen(resultId: args?['resultId'] as int?),
        );
      case AppRoutes.quizReview:
        return MaterialPageRoute(
          builder: (_) => QuizReviewScreen(resultId: args?['resultId'] as int?),
        );
      case AppRoutes.history:
        return MaterialPageRoute(builder: (_) => const HistoryScreen());
      case AppRoutes.studentStatistics:
        return MaterialPageRoute(builder: (_) => const StudentStatisticsScreen());
      case AppRoutes.reviewWrongAnswers:
        return MaterialPageRoute(builder: (_) => const ReviewWrongAnswersScreen());
      case AppRoutes.profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case AppRoutes.about:
        return MaterialPageRoute(builder: (_) => const AboutScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Page not found')),
          ),
        );
    }
  }
}
