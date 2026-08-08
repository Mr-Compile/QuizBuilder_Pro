import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive_utils.dart';
import '../../models/user.dart';
import '../../models/topic.dart';
import '../../services/service_locator.dart';
import '../../widgets/role_guard.dart';
import '../../widgets/enhanced_cards.dart';
import '../../widgets/navigation_scaffold.dart';
import '../../widgets/analytics_widgets.dart';
import '../../widgets/responsive_widgets.dart';

// Spacing constants for better readability
const double _smallSpacing = AppTheme.spacing2;
const double _mediumSpacing = AppTheme.spacing4;

/// Student dashboard with personalized analytics, charts, and quick actions.
class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  User? _user;
  late Future<StudentDashboardData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _dataFuture = _loadDashboardData();
  }

  Future<void> _loadUser() async {
    final auth = await ServiceLocator.auth;
    final user = await auth.getCurrentUser();
    setState(() => _user = user);
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRole: AppConstants.roleStudent,
      child: NavigationScaffold(
        title: 'Student Dashboard',
        currentRoute: AppRoutes.studentDashboard,
        isDashboard: true,
        body: FutureBuilder(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data;
            if (data == null) {
              return const Center(child: Text('Error loading dashboard data'));
            }
            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(context.responsiveSpacing),
                child: ResponsiveContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      SizedBox(height: context.responsiveSpacing * 2),
                      _buildSummaryCards(context, data),
                      SizedBox(height: context.responsiveSpacing * 2),
                      _buildChartsSection(context, data),
                      SizedBox(height: context.responsiveSpacing * 2),
                      _buildContinueLearning(context, data),
                      SizedBox(height: context.responsiveSpacing * 2),
                      _buildQuickActions(context),
                      SizedBox(height: context.responsiveSpacing),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome, ${_user?.fullName ?? 'Student'}!',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Ready to learn? Choose a topic and start practicing.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(BuildContext context, StudentDashboardData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Progress',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: context.responsiveSpacing),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 1200 ? 3 : 
                                   constraints.maxWidth > 600 ? 2 : 1;
            return Wrap(
              spacing: context.responsiveSpacing,
              runSpacing: context.responsiveSpacing,
              children: [
                SizedBox(
                  width: (constraints.maxWidth - (context.responsiveSpacing * (crossAxisCount - 1))) / crossAxisCount,
                  child: EnhancedSummaryCard(
                    label: 'Quizzes Taken',
                    value: AnalyticsWidgets.formatNumber(data.quizzesTaken),
                    icon: LucideIcons.clipboardList,
                    color: AppColors.primary,
                    onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.history),
                  ),
                ),
                SizedBox(
                  width: (constraints.maxWidth - (context.responsiveSpacing * (crossAxisCount - 1))) / crossAxisCount,
                  child: EnhancedSummaryCard(
                    label: 'Average Score',
                    value: AnalyticsWidgets.formatPercentage(data.averageScore),
                    icon: LucideIcons.percent,
                    color: AppColors.accent,
                  ),
                ),
                SizedBox(
                  width: (constraints.maxWidth - (context.responsiveSpacing * (crossAxisCount - 1))) / crossAxisCount,
                  child: EnhancedSummaryCard(
                    label: 'Highest Score',
                    value: AnalyticsWidgets.formatPercentage(data.highestScore),
                    icon: LucideIcons.trophy,
                    color: AppColors.add,
                  ),
                ),
                SizedBox(
                  width: (constraints.maxWidth - (context.responsiveSpacing * (crossAxisCount - 1))) / crossAxisCount,
                  child: EnhancedSummaryCard(
                    label: 'Favorite Topic',
                    value: data.favoriteTopic,
                    icon: LucideIcons.star,
                    color: AppColors.secondary,
                  ),
                ),
                SizedBox(
                  width: (constraints.maxWidth - (context.responsiveSpacing * (crossAxisCount - 1))) / crossAxisCount,
                  child: EnhancedSummaryCard(
                    label: 'Best Difficulty',
                    value: data.bestDifficulty,
                    icon: LucideIcons.layers,
                    color: AppColors.edit,
                  ),
                ),
                SizedBox(
                  width: (constraints.maxWidth - (context.responsiveSpacing * (crossAxisCount - 1))) / crossAxisCount,
                  child: EnhancedSummaryCard(
                    label: 'Current Streak',
                    value: '${data.currentStreak}',
                    icon: LucideIcons.zap,
                    color: AppColors.startQuiz,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: context.responsiveSpacing),
        ResponsiveBuilder(
          mobile: _buildMobileQuickActions(context),
          tablet: _buildTabletQuickActions(context),
          desktop: _buildDesktopQuickActions(context),
        ),
      ],
    );
  }

  Widget _buildMobileQuickActions(BuildContext context) {
    return Column(
      children: [
        EnhancedActionCard(
          icon: LucideIcons.bookOpen,
          label: 'Browse Topics',
          subtitle: 'Explore available quiz topics',
          color: AppColors.secondary,
          onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.topicSelect),
        ),
        SizedBox(height: context.responsiveSpacing),
        EnhancedActionCard(
          icon: LucideIcons.history,
          label: 'My History',
          subtitle: 'View past quiz results',
          color: AppColors.edit,
          onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.history),
        ),
        SizedBox(height: context.responsiveSpacing),
        EnhancedActionCard(
          icon: LucideIcons.barChart2,
          label: 'My Statistics',
          subtitle: 'Track your learning progress',
          color: AppColors.add,
          onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.studentStatistics),
        ),
        SizedBox(height: context.responsiveSpacing),
        EnhancedActionCard(
          icon: LucideIcons.bookX,
          label: 'Review Mistakes',
          subtitle: 'Practice questions you got wrong',
          color: AppColors.delete,
          onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.reviewWrongAnswers),
        ),
        SizedBox(height: context.responsiveSpacing),
        EnhancedActionCard(
          icon: LucideIcons.user,
          label: 'My Profile',
          subtitle: 'Update your name or password',
          color: AppColors.accent,
          onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.profile),
        ),
      ],
    );
  }

  Widget _buildTabletQuickActions(BuildContext context) {
    return ResponsiveGrid(
      mobileColumns: 1,
      tabletColumns: 2,
      desktopColumns: 3,
      childAspectRatio: 2.0,
      children: [
        EnhancedActionCard(
          icon: LucideIcons.bookOpen,
          label: 'Browse Topics',
          subtitle: 'Explore available quiz topics',
          color: AppColors.secondary,
          onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.topicSelect),
        ),
        EnhancedActionCard(
          icon: LucideIcons.history,
          label: 'My History',
          subtitle: 'View past quiz results',
          color: AppColors.edit,
          onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.history),
        ),
        EnhancedActionCard(
          icon: LucideIcons.barChart2,
          label: 'My Statistics',
          subtitle: 'Track your learning progress',
          color: AppColors.add,
          onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.studentStatistics),
        ),
        EnhancedActionCard(
          icon: LucideIcons.bookX,
          label: 'Review Mistakes',
          subtitle: 'Practice questions you got wrong',
          color: AppColors.delete,
          onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.reviewWrongAnswers),
        ),
        EnhancedActionCard(
          icon: LucideIcons.user,
          label: 'My Profile',
          subtitle: 'Update your name or password',
          color: AppColors.accent,
          onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.profile),
        ),
      ],
    );
  }

  Widget _buildDesktopQuickActions(BuildContext context) {
    return _buildTabletQuickActions(context);
  }

  Widget _buildChartsSection(BuildContext context, StudentDashboardData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Analytics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: _mediumSpacing),
        _buildScoresChart(data),
        const SizedBox(height: _mediumSpacing),
        _buildTopicPerformanceChart(data),
        const SizedBox(height: _mediumSpacing),
        _buildCorrectIncorrectChart(data),
      ],
    );
  }

  Widget _buildScoresChart(StudentDashboardData data) {
    if (data.recentScores.isEmpty) {
      return AnalyticsWidgets.emptyChartState(message: 'No quiz data yet');
    }

    final spots = data.recentScores.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();

    final labels = data.recentScores.asMap().entries.map((entry) {
      return '#${entry.key + 1}';
    }).toList();

    return AnalyticsWidgets.lineChart(
      spots: spots,
      title: 'My Scores (Last 10 Quizzes)',
      labels: labels,
      color: AppColors.primary,
    );
  }

  Widget _buildTopicPerformanceChart(StudentDashboardData data) {
    if (data.topicPerformance.isEmpty) {
      return AnalyticsWidgets.emptyChartState(message: 'No topic data yet');
    }

    final barGroups = data.topicPerformance.entries.map((entry) {
      return BarChartGroupData(
        x: data.topicPerformance.keys.toList().indexOf(entry.key),
        barRods: [
          BarChartRodData(
            toY: entry.value,
            color: AppColors.secondary,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();

    return AnalyticsWidgets.barChart(
      barGroups: barGroups,
      title: 'Performance by Topic',
      labels: data.topicPerformance.keys.toList(),
    );
  }

  Widget _buildCorrectIncorrectChart(StudentDashboardData data) {
    if (data.totalAnswers == 0) {
      return AnalyticsWidgets.emptyChartState(message: 'No answer data yet');
    }

    final correctRatio = data.correctAnswers / data.totalAnswers;
    final incorrectRatio = data.incorrectAnswers / data.totalAnswers;

    final sections = [
      PieChartSectionData(
        value: correctRatio,
        title: '${(correctRatio * 100).toStringAsFixed(0)}%',
        color: AppColors.add,
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: incorrectRatio,
        title: '${(incorrectRatio * 100).toStringAsFixed(0)}%',
        color: AppColors.delete,
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];

    return AnalyticsWidgets.doughnutChart(
      sections: sections,
      title: 'Correct vs Incorrect Answers',
      centerText: '${data.totalAnswers}',
    );
  }

  Widget _buildContinueLearning(BuildContext context, StudentDashboardData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Continue Learning',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: _mediumSpacing),
        if (data.recommendedTopic != null)
          EnhancedActionCard(
            icon: LucideIcons.target,
            label: 'Recommended: ${data.recommendedTopic}',
            subtitle: 'Based on your performance',
            color: AppColors.startQuiz,
            onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.topicSelect),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(_mediumSpacing),
              child: Row(
                children: [
                  Icon(LucideIcons.lightbulb, color: Colors.grey.shade400),
                  const SizedBox(width: _mediumSpacing),
                  Expanded(
                    child: Text(
                      'Complete more quizzes to get personalized recommendations',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: _smallSpacing),
        if (data.lastQuizResult != null)
          Card(
            child: ListTile(
              leading: Icon(
                data.lastQuizResult!.passed ? LucideIcons.checkCircle : LucideIcons.xCircle,
                color: data.lastQuizResult!.passed ? AppColors.add : AppColors.delete,
              ),
              title: Text('Last Quiz: ${data.lastQuizResult!.topicName}'),
              subtitle: Text('${data.lastQuizResult!.difficulty} • ${AnalyticsWidgets.formatRelativeDate(data.lastQuizResult!.date)}'),
              trailing: Text(
                AnalyticsWidgets.formatPercentage(data.lastQuizResult!.percentage),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(_mediumSpacing),
              child: Text(
                'No quizzes taken yet. Start your first quiz!',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ),
      ],
    );
  }

  Future<StudentDashboardData> _loadDashboardData() async {
    final auth = await ServiceLocator.auth;
    final user = await auth.getCurrentUser();
    if (user == null) {
      throw Exception('User not found');
    }

    final db = ServiceLocator.db;
    final results = await db.getResultsForUser(user.id!);
    final topics = await db.getAllTopics();

    // Calculate basic stats
    final quizzesTaken = results.length;
    final averageScore = results.isEmpty 
        ? 0.0 
        : results.map((r) => r.percentage).reduce((a, b) => a + b) / results.length;
    final highestScore = results.isEmpty 
        ? 0.0 
        : results.map((r) => r.percentage).reduce((a, b) => a > b ? a : b);

    // Calculate favorite topic
    final topicCounts = <int, int>{};
    for (final result in results) {
      topicCounts[result.topicId] = (topicCounts[result.topicId] ?? 0) + 1;
    }
    final favoriteTopicId = topicCounts.isEmpty 
        ? null 
        : topicCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    final favoriteTopic = favoriteTopicId != null 
        ? topics.firstWhere(
            (t) => t.id == favoriteTopicId,
            orElse: () => Topic(id: 0, name: 'N/A', description: ''),
          ).name 
        : 'N/A';

    // Calculate best difficulty
    final difficultyScores = <String, List<double>>{};
    for (final result in results) {
      difficultyScores.putIfAbsent(result.difficulty, () => []).add(result.percentage);
    }
    String bestDifficulty = 'N/A';
    double bestAvg = 0;
    difficultyScores.forEach((difficulty, scores) {
      final avg = scores.reduce((a, b) => a + b) / scores.length;
      if (avg > bestAvg) {
        bestAvg = avg;
        bestDifficulty = difficulty;
      }
    });

    // Calculate current streak (consecutive days with quizzes)
    final now = DateTime.now();
    int currentStreak = 0;
    final quizDates = results.map((r) => DateTime.parse(r.createdAt)).toSet()
      .map((d) => DateTime(d.year, d.month, d.day))
      .toList()
      ..sort((a, b) => b.compareTo(a));
    
    for (int i = 0; i < quizDates.length; i++) {
      final expectedDate = now.subtract(Duration(days: i));
      final expectedDay = DateTime(expectedDate.year, expectedDate.month, expectedDate.day);
      if (quizDates.contains(expectedDay)) {
        currentStreak++;
      } else {
        break;
      }
    }

    // Calculate recent scores (last 10)
    final recentScores = results.take(10).map((r) => r.percentage).toList();

    // Calculate topic performance
    final topicPerformance = <String, double>{};
    for (final topic in topics) {
      final topicResults = results.where((r) => r.topicId == topic.id);
      if (topicResults.isNotEmpty) {
        final avg = topicResults.map((r) => r.percentage).reduce((a, b) => a + b) / topicResults.length;
        topicPerformance[topic.name] = avg;
      }
    }

    // Calculate correct/incorrect answers
    int totalAnswers = 0;
    int correctAnswers = 0;
    for (final result in results) {
      if (result.id != null) {
        final answers = await db.getAnswersForResult(result.id!);
        totalAnswers += answers.length;
        correctAnswers += answers.where((a) => a.isCorrect).length;
      }
    }
    final incorrectAnswers = totalAnswers - correctAnswers;

    // Determine recommended topic (weakest performing topic)
    String? recommendedTopic;
    if (topicPerformance.isNotEmpty) {
      final weakest = topicPerformance.entries.reduce((a, b) => a.value < b.value ? a : b);
      if (weakest.value < 70.0) {
        recommendedTopic = weakest.key;
      }
    }

    // Get last quiz result
    LastQuizData? lastQuizResult;
    if (results.isNotEmpty) {
      final lastResult = results.first;
      final topic = topics.firstWhere(
        (t) => t.id == lastResult.topicId,
        orElse: () => Topic(id: 0, name: 'Unknown', description: ''),
      );
      lastQuizResult = LastQuizData(
        topicName: topic.name,
        difficulty: lastResult.difficulty,
        percentage: lastResult.percentage,
        passed: lastResult.passed,
        date: DateTime.parse(lastResult.createdAt),
      );
    }

    return StudentDashboardData(
      quizzesTaken: quizzesTaken,
      averageScore: averageScore,
      highestScore: highestScore,
      favoriteTopic: favoriteTopic,
      bestDifficulty: bestDifficulty,
      currentStreak: currentStreak,
      recentScores: recentScores,
      topicPerformance: topicPerformance,
      totalAnswers: totalAnswers,
      correctAnswers: correctAnswers,
      incorrectAnswers: incorrectAnswers,
      recommendedTopic: recommendedTopic,
      lastQuizResult: lastQuizResult,
    );
  }
}

class StudentDashboardData {
  final int quizzesTaken;
  final double averageScore;
  final double highestScore;
  final String favoriteTopic;
  final String bestDifficulty;
  final int currentStreak;
  final List<double> recentScores;
  final Map<String, double> topicPerformance;
  final int totalAnswers;
  final int correctAnswers;
  final int incorrectAnswers;
  final String? recommendedTopic;
  final LastQuizData? lastQuizResult;

  StudentDashboardData({
    required this.quizzesTaken,
    required this.averageScore,
    required this.highestScore,
    required this.favoriteTopic,
    required this.bestDifficulty,
    required this.currentStreak,
    required this.recentScores,
    required this.topicPerformance,
    required this.totalAnswers,
    required this.correctAnswers,
    required this.incorrectAnswers,
    this.recommendedTopic,
    this.lastQuizResult,
  });
}

class LastQuizData {
  final String topicName;
  final String difficulty;
  final double percentage;
  final bool passed;
  final DateTime date;

  LastQuizData({
    required this.topicName,
    required this.difficulty,
    required this.percentage,
    required this.passed,
    required this.date,
  });
}