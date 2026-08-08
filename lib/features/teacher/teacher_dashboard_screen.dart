import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
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

/// Teacher dashboard with summary cards, charts, and quick actions.
class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  late Future<DashboardData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRole: AppConstants.roleTeacher,
      child: NavigationScaffold(
        title: 'Teacher Dashboard',
        currentRoute: AppRoutes.teacherDashboard,
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
                      _buildSummaryCards(context, data.summary),
                      SizedBox(height: context.responsiveSpacing * 2),
                      _buildChartsSection(context, data),
                      SizedBox(height: context.responsiveSpacing * 2),
                      _buildRecentActivity(context, data),
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
          'Welcome Back!',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Here\'s what\'s happening with your classes today.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(BuildContext context, Summary data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: context.responsiveSpacing),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 1200 ? 4 : 
                                   constraints.maxWidth > 600 ? 2 : 1;
            return Wrap(
              spacing: context.responsiveSpacing,
              runSpacing: context.responsiveSpacing,
              children: [
                SizedBox(
                  width: (constraints.maxWidth - (context.responsiveSpacing * (crossAxisCount - 1))) / crossAxisCount,
                  child: EnhancedSummaryCard(
                    label: 'Total Students',
                    value: AnalyticsWidgets.formatNumber(data.totalStudents),
                    icon: LucideIcons.users,
                    color: AppColors.primary,
                    onTap: () => Navigator.of(context).pushReplacementNamed(AppRoutes.studentManagement),
                  ),
                ),
                SizedBox(
                  width: (constraints.maxWidth - (context.responsiveSpacing * (crossAxisCount - 1))) / crossAxisCount,
                  child: EnhancedSummaryCard(
                    label: 'Active Students',
                    value: AnalyticsWidgets.formatNumber(data.activeStudents),
                    icon: LucideIcons.userCheck,
                    color: AppColors.add,
                  ),
                ),
                SizedBox(
                  width: (constraints.maxWidth - (context.responsiveSpacing * (crossAxisCount - 1))) / crossAxisCount,
                  child: EnhancedSummaryCard(
                    label: 'Total Topics',
                    value: AnalyticsWidgets.formatNumber(data.topics),
                    icon: LucideIcons.bookOpen,
                    color: AppColors.secondary,
                    onTap: () => Navigator.of(context).pushReplacementNamed(AppRoutes.topicManagement),
                  ),
                ),
                SizedBox(
                  width: (constraints.maxWidth - (context.responsiveSpacing * (crossAxisCount - 1))) / crossAxisCount,
                  child: EnhancedSummaryCard(
                    label: 'Total Questions',
                    value: AnalyticsWidgets.formatNumber(data.questions),
                    icon: LucideIcons.helpCircle,
                    color: AppColors.accent,
                    onTap: () => Navigator.of(context).pushReplacementNamed(AppRoutes.questionManagement),
                  ),
                ),
                SizedBox(
                  width: (constraints.maxWidth - (context.responsiveSpacing * (crossAxisCount - 1))) / crossAxisCount,
                  child: EnhancedSummaryCard(
                    label: 'AI Questions',
                    value: AnalyticsWidgets.formatNumber(data.aiQuestions),
                    icon: LucideIcons.wand2,
                    color: AppColors.startQuiz,
                  ),
                ),
                SizedBox(
                  width: (constraints.maxWidth - (context.responsiveSpacing * (crossAxisCount - 1))) / crossAxisCount,
                  child: EnhancedSummaryCard(
                    label: 'Quiz Attempts Today',
                    value: AnalyticsWidgets.formatNumber(data.attemptsToday),
                    icon: LucideIcons.clipboardList,
                    color: AppColors.edit,
                    onTap: () => Navigator.of(context).pushReplacementNamed(AppRoutes.results),
                  ),
                ),
                SizedBox(
                  width: (constraints.maxWidth - (context.responsiveSpacing * (crossAxisCount - 1))) / crossAxisCount,
                  child: EnhancedSummaryCard(
                    label: 'Total Attempts',
                    value: AnalyticsWidgets.formatNumber(data.totalAttempts),
                    icon: LucideIcons.barChart2,
                    color: AppColors.info,
                  ),
                ),
                SizedBox(
                  width: (constraints.maxWidth - (context.responsiveSpacing * (crossAxisCount - 1))) / crossAxisCount,
                  child: EnhancedSummaryCard(
                    label: 'Avg Student Score',
                    value: AnalyticsWidgets.formatPercentage(data.averageScore),
                    icon: LucideIcons.percent,
                    color: AppColors.success,
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
          icon: LucideIcons.users,
          label: 'Manage Students',
          subtitle: 'Add, edit, or deactivate student accounts',
          color: AppColors.primary,
          onTap: () => Navigator.of(context).pushReplacementNamed(AppRoutes.studentManagement),
        ),
        SizedBox(height: context.responsiveSpacing),
        EnhancedActionCard(
          icon: LucideIcons.bookOpen,
          label: 'Manage Topics',
          subtitle: 'Create and organize quiz topics',
          color: AppColors.secondary,
          onTap: () => Navigator.of(context).pushReplacementNamed(AppRoutes.topicManagement),
        ),
        SizedBox(height: context.responsiveSpacing),
        EnhancedActionCard(
          icon: LucideIcons.helpCircle,
          label: 'Manage Questions',
          subtitle: 'Add, edit, or remove quiz questions',
          color: AppColors.accent,
          onTap: () => Navigator.of(context).pushReplacementNamed(AppRoutes.questionManagement),
        ),
        SizedBox(height: context.responsiveSpacing),
        EnhancedActionCard(
          icon: LucideIcons.wand2,
          label: 'AI Generate Questions',
          subtitle: 'Use AI to generate quiz questions',
          color: AppColors.startQuiz,
          onTap: () => Navigator.of(context).pushReplacementNamed(AppRoutes.aiGenerate),
        ),
      ],
    );
  }

  Widget _buildTabletQuickActions(BuildContext context) {
    return ResponsiveGrid(
      mobileColumns: 1,
      tabletColumns: 2,
      desktopColumns: 4,
      childAspectRatio: 2.0,
      children: [
        EnhancedActionCard(
          icon: LucideIcons.users,
          label: 'Manage Students',
          subtitle: 'Add, edit, or deactivate student accounts',
          color: AppColors.primary,
          onTap: () => Navigator.of(context).pushReplacementNamed(AppRoutes.studentManagement),
        ),
        EnhancedActionCard(
          icon: LucideIcons.bookOpen,
          label: 'Manage Topics',
          subtitle: 'Create and organize quiz topics',
          color: AppColors.secondary,
          onTap: () => Navigator.of(context).pushReplacementNamed(AppRoutes.topicManagement),
        ),
        EnhancedActionCard(
          icon: LucideIcons.helpCircle,
          label: 'Manage Questions',
          subtitle: 'Add, edit, or remove quiz questions',
          color: AppColors.accent,
          onTap: () => Navigator.of(context).pushReplacementNamed(AppRoutes.questionManagement),
        ),
        EnhancedActionCard(
          icon: LucideIcons.wand2,
          label: 'AI Generate Questions',
          subtitle: 'Use AI to generate quiz questions',
          color: AppColors.startQuiz,
          onTap: () => Navigator.of(context).pushReplacementNamed(AppRoutes.aiGenerate),
        ),
      ],
    );
  }

  Widget _buildDesktopQuickActions(BuildContext context) {
    return _buildTabletQuickActions(context);
  }

  Widget _buildChartsSection(BuildContext context, DashboardData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analytics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: _mediumSpacing),
        _buildQuizAttemptsChart(data),
        const SizedBox(height: _mediumSpacing),
        _buildAverageScoreChart(data),
        const SizedBox(height: _mediumSpacing),
        _buildTopicDistributionChart(data),
        const SizedBox(height: _mediumSpacing),
        _buildTopStudentsChart(data),
      ],
    );
  }

  Widget _buildQuizAttemptsChart(DashboardData data) {
    if (data.weeklyAttempts.isEmpty) {
      return AnalyticsWidgets.emptyChartState(message: 'No quiz attempts data yet');
    }
    
    final spots = data.weeklyAttempts.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.toDouble());
    }).toList();

    final labels = _getLast7DaysLabels();

    return AnalyticsWidgets.lineChart(
      spots: spots,
      title: 'Quiz Attempts (Last 7 Days)',
      labels: labels,
      color: AppColors.primary,
    );
  }

  Widget _buildAverageScoreChart(DashboardData data) {
    if (data.scoresByDifficulty.isEmpty) {
      return AnalyticsWidgets.emptyChartState(message: 'No score data yet');
    }

    final barGroups = data.scoresByDifficulty.entries.map((entry) {
      return BarChartGroupData(
        x: data.scoresByDifficulty.keys.toList().indexOf(entry.key),
        barRods: [
          BarChartRodData(
            toY: entry.value,
            color: _getDifficultyColor(entry.key),
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
      title: 'Average Score by Difficulty',
      labels: data.scoresByDifficulty.keys.toList(),
    );
  }

  Widget _buildTopicDistributionChart(DashboardData data) {
    if (data.topicDistribution.isEmpty) {
      return AnalyticsWidgets.emptyChartState(message: 'No topic data yet');
    }

    final total = data.topicDistribution.values.reduce((a, b) => a + b);
    final sections = data.topicDistribution.entries.map((entry) {
      final value = entry.value / total;
      return PieChartSectionData(
        value: value,
        title: '${(value * 100).toStringAsFixed(0)}%',
        color: _getTopicColor(entry.key),
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return AnalyticsWidgets.pieChart(
      sections: sections,
      title: 'Question Distribution by Topic',
      labels: data.topicDistribution.keys.toList(),
    );
  }

  Widget _buildTopStudentsChart(DashboardData data) {
    if (data.topStudents.isEmpty) {
      return AnalyticsWidgets.emptyChartState(message: 'No student data yet');
    }

    final barGroups = data.topStudents.asMap().entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value.score.toDouble(),
            color: AppColors.add,
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();

    final labels = data.topStudents.map((s) => s.name).toList();

    return AnalyticsWidgets.horizontalBarChart(
      barGroups: barGroups,
      title: 'Top 5 Students',
      labels: labels,
      color: AppColors.add,
    );
  }

  Widget _buildRecentActivity(BuildContext context, DashboardData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: _mediumSpacing),
        if (data.recentAttempts.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(_mediumSpacing),
              child: Text(
                'No recent activity',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          )
        else
          ...data.recentAttempts.take(5).map((attempt) => Card(
                margin: const EdgeInsets.only(bottom: _smallSpacing),
                child: ListTile(
                  leading: Icon(
                    attempt.passed ? LucideIcons.checkCircle : LucideIcons.xCircle,
                    color: attempt.passed ? AppColors.add : AppColors.delete,
                  ),
                  title: Text(attempt.studentName),
                  subtitle: Text('${attempt.topicName} • ${attempt.difficulty}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        AnalyticsWidgets.formatPercentage(attempt.percentage),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        AnalyticsWidgets.formatRelativeDate(attempt.date),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              )),
      ],
    );
  }

  List<String> _getLast7DaysLabels() {
    final labels = <String>[];
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      labels.add(DateFormat('E').format(date));
    }
    return labels;
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return AppColors.add;
      case 'medium':
        return AppColors.edit;
      case 'hard':
        return AppColors.delete;
      default:
        return AppColors.primary;
    }
  }

  Color _getTopicColor(String topic) {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.accent,
      AppColors.add,
      AppColors.edit,
    ];
    final index = topic.hashCode % colors.length;
    return colors[index.abs()];
  }

  Future<DashboardData> _loadDashboardData() async {
    final db = ServiceLocator.db;
    final results = await db.getAllResults();
    final questions = await db.getAllQuestions();
    final students = await db.getAllStudents();
    final topics = await db.getAllTopics();
    
    // Calculate summary
    final totalStudents = students.length;
    final activeStudents = students.where((s) => s.isActive).length;
    final totalTopics = topics.length;
    final totalQuestions = questions.length;
    final aiQuestions = questions.where((q) => q.source == AppConstants.sourceAi).length;
    final totalAttempts = results.length;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final attemptsToday = results.where((r) {
      final resultDate = DateTime.parse(r.createdAt);
      final resultDay = DateTime(resultDate.year, resultDate.month, resultDate.day);
      return resultDay == today;
    }).length;

    final averageScore = results.isEmpty 
        ? 0.0 
        : results.map((r) => r.percentage).reduce((a, b) => a + b) / results.length;

    // Calculate weekly attempts
    final weeklyAttempts = List<int>.filled(7, 0);
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: 6 - i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      
      weeklyAttempts[i] = results.where((r) {
        final resultDate = DateTime.parse(r.createdAt);
        return resultDate.isAfter(dayStart) && resultDate.isBefore(dayEnd);
      }).length;
    }

    // Calculate scores by difficulty
    final scoresByDifficulty = <String, double>{};
    for (final difficulty in [AppConstants.difficultyEasy, AppConstants.difficultyMedium, AppConstants.difficultyHard]) {
      final difficultyResults = results.where((r) => r.difficulty == difficulty);
      if (difficultyResults.isNotEmpty) {
        final avg = difficultyResults.map((r) => r.percentage).reduce((a, b) => a + b) / difficultyResults.length;
        scoresByDifficulty[difficulty] = avg;
      }
    }

    // Calculate topic distribution
    final topicDistribution = <String, int>{};
    for (final topic in topics) {
      final count = questions.where((q) => q.topicId == topic.id).length;
      if (count > 0) {
        topicDistribution[topic.name] = count;
      }
    }

    // Calculate top students
    final studentScores = <int, double>{};
    for (final result in results) {
      studentScores[result.userId] = (studentScores[result.userId] ?? 0) + result.percentage;
    }
    
    final topStudents = studentScores.entries.map((entry) {
      final student = students.firstWhere(
        (s) => s.id == entry.key,
        orElse: () => User(id: entry.key, fullName: 'Unknown', username: 'unknown', password: '', role: AppConstants.roleStudent),
      );
      final avgScore = studentScores[entry.key]! / results.where((r) => r.userId == entry.key).length;
      return TopStudentData(
        name: student.fullName,
        score: avgScore,
      );
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    // Build recent attempts
    final recentAttempts = results.take(10).map((result) {
      final student = students.firstWhere(
        (s) => s.id == result.userId,
        orElse: () => User(id: result.userId, fullName: 'Unknown', username: 'unknown', password: '', role: AppConstants.roleStudent),
      );
      final topic = topics.firstWhere(
        (t) => t.id == result.topicId,
        orElse: () => Topic(id: result.topicId, name: 'Unknown', description: ''),
      );
      return RecentAttemptData(
        studentName: student.fullName,
        topicName: topic.name,
        difficulty: result.difficulty,
        percentage: result.percentage,
        passed: result.passed,
        date: DateTime.parse(result.createdAt),
      );
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return DashboardData(
      summary: Summary(
        totalStudents: totalStudents,
        activeStudents: activeStudents,
        topics: totalTopics,
        questions: totalQuestions,
        aiQuestions: aiQuestions,
        attemptsToday: attemptsToday,
        totalAttempts: totalAttempts,
        averageScore: averageScore,
      ),
      weeklyAttempts: weeklyAttempts,
      scoresByDifficulty: scoresByDifficulty,
      topicDistribution: topicDistribution,
      topStudents: topStudents.take(5).toList(),
      recentAttempts: recentAttempts,
    );
  }
}

class Summary {
  final int totalStudents;
  final int activeStudents;
  final int topics;
  final int questions;
  final int aiQuestions;
  final int attemptsToday;
  final int totalAttempts;
  final double averageScore;

  Summary({
    required this.totalStudents,
    required this.activeStudents,
    required this.topics,
    required this.questions,
    required this.aiQuestions,
    required this.attemptsToday,
    required this.totalAttempts,
    required this.averageScore,
  });
}

class DashboardData {
  final Summary summary;
  final List<int> weeklyAttempts;
  final Map<String, double> scoresByDifficulty;
  final Map<String, int> topicDistribution;
  final List<TopStudentData> topStudents;
  final List<RecentAttemptData> recentAttempts;

  DashboardData({
    required this.summary,
    required this.weeklyAttempts,
    required this.scoresByDifficulty,
    required this.topicDistribution,
    required this.topStudents,
    required this.recentAttempts,
  });
}

class TopStudentData {
  final String name;
  final double score;

  TopStudentData({required this.name, required this.score});
}

class RecentAttemptData {
  final String studentName;
  final String topicName;
  final String difficulty;
  final double percentage;
  final bool passed;
  final DateTime date;

  RecentAttemptData({
    required this.studentName,
    required this.topicName,
    required this.difficulty,
    required this.percentage,
    required this.passed,
    required this.date,
  });
}