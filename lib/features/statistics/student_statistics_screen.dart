import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/quiz_result.dart';
import '../../models/topic.dart';
import '../../services/service_locator.dart';
import '../../widgets/role_guard.dart';
import '../../widgets/navigation_scaffold.dart';
import '../../widgets/enhanced_cards.dart';
import '../../widgets/analytics_widgets.dart';
import '../../core/routes/app_routes.dart';

/// Enhanced statistics screen for the logged-in student with improved readability.
class StudentStatisticsScreen extends StatefulWidget {
  const StudentStatisticsScreen({super.key});

  @override
  State<StudentStatisticsScreen> createState() => _StudentStatisticsScreenState();
}

class _StudentStatisticsScreenState extends State<StudentStatisticsScreen> {
  final _db = ServiceLocator.db;
  late Future<StudentStatisticsData> _dataFuture;

  // Section expansion states
  final Map<String, bool> _expandedSections = {
    'summary': true,
    'topics': true,
    'difficulty': true,
    'improvement': true,
    'recent': true,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _dataFuture = _loadStatisticsData();
    setState(() {});
  }

  void _toggleSection(String section) {
    setState(() {
      _expandedSections[section] = !(_expandedSections[section] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRole: AppConstants.roleStudent,
      child: NavigationScaffold(
        title: 'My Statistics',
        currentRoute: AppRoutes.studentStatistics,
        body: FutureBuilder(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data;
            if (data == null) {
              return const Center(child: Text('Error loading statistics'));
            }

            if (data.results.isEmpty) {
              return const Center(child: Text('No data yet. Take a quiz!'));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.mediumSpacing),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummarySection(data),
                  _buildTopicSection(data),
                  _buildDifficultySection(data),
                  _buildImprovementSection(data),
                  _buildRecentResultsSection(data),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummarySection(StudentStatisticsData data) {
    final isExpanded = _expandedSections['summary'] ?? true;
    return Column(
      children: [
        AnalyticsWidgets.sectionHeader(
          title: 'Personal Summary',
          isExpanded: isExpanded,
          onTap: () => _toggleSection('summary'),
          icon: LucideIcons.user,
        ),
        if (isExpanded) ...[
          const SizedBox(height: AppTheme.smallSpacing),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth < 360 ? 1 : 2;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppTheme.spacing2,
                crossAxisSpacing: AppTheme.spacing2,
                childAspectRatio: 2.0,
                children: [
                  DataCard(
                    icon: LucideIcons.activity,
                    label: 'Quizzes Taken',
                    value: AnalyticsWidgets.formatNumber(data.totalQuizzes),
                    color: AppColors.primary,
                  ),
                  DataCard(
                    icon: LucideIcons.percent,
                    label: 'Average Score',
                    value: AnalyticsWidgets.formatPercentage(data.averageScore),
                    color: AppColors.accent,
                  ),
                  DataCard(
                    icon: LucideIcons.trophy,
                    label: 'Highest Score',
                    value: AnalyticsWidgets.formatPercentage(data.highestScore),
                    color: AppColors.add,
                  ),
                  DataCard(
                    icon: LucideIcons.target,
                    label: 'Best Topic',
                    value: data.bestTopic,
                    color: AppColors.secondary,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppTheme.largeSpacing),
        ],
      ],
    );
  }

  Widget _buildTopicSection(StudentStatisticsData data) {
    final isExpanded = _expandedSections['topics'] ?? true;
    return Column(
      children: [
        AnalyticsWidgets.sectionHeader(
          title: 'Topic Performance',
          isExpanded: isExpanded,
          onTap: () => _toggleSection('topics'),
          icon: LucideIcons.bookOpen,
        ),
        if (isExpanded) ...[
          const SizedBox(height: AppTheme.smallSpacing),
          DataCard(
            icon: LucideIcons.star,
            label: 'Best Topic',
            value: data.bestTopic,
            color: AppColors.add,
          ),
          const SizedBox(height: AppTheme.smallSpacing),
          DataCard(
            icon: LucideIcons.trendingDown,
            label: 'Weakest Topic',
            value: data.weakestTopic,
            color: AppColors.delete,
          ),
          const SizedBox(height: AppTheme.smallSpacing),
          _buildTopicPerformanceChart(data),
          const SizedBox(height: AppTheme.largeSpacing),
        ],
      ],
    );
  }

  Widget _buildTopicPerformanceChart(StudentStatisticsData data) {
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
      title: 'Average Score by Topic',
      labels: data.topicPerformance.keys.toList(),
    );
  }

  Widget _buildDifficultySection(StudentStatisticsData data) {
    final isExpanded = _expandedSections['difficulty'] ?? true;
    return Column(
      children: [
        AnalyticsWidgets.sectionHeader(
          title: 'Difficulty Comparison',
          isExpanded: isExpanded,
          onTap: () => _toggleSection('difficulty'),
          icon: LucideIcons.layers,
        ),
        if (isExpanded) ...[
          const SizedBox(height: AppTheme.smallSpacing),
          for (final entry in data.difficultyPerformance.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.smallSpacing),
              child: DataCard(
                icon: LucideIcons.activity,
                label: entry.key,
                value: AnalyticsWidgets.formatPercentage(entry.value),
                color: _getDifficultyColor(entry.key),
              ),
            ),
          const SizedBox(height: AppTheme.largeSpacing),
        ],
      ],
    );
  }

  Widget _buildImprovementSection(StudentStatisticsData data) {
    final isExpanded = _expandedSections['improvement'] ?? true;
    return Column(
      children: [
        AnalyticsWidgets.sectionHeader(
          title: 'Improvement Trend',
          isExpanded: isExpanded,
          onTap: () => _toggleSection('improvement'),
          icon: LucideIcons.trendingUp,
        ),
        if (isExpanded) ...[
          const SizedBox(height: AppTheme.smallSpacing),
          _buildImprovementChart(data),
          const SizedBox(height: AppTheme.smallSpacing),
          DataCard(
            icon: LucideIcons.zap,
            label: 'Improvement Rate',
            value: data.improvementRate > 0 
                ? '+${AnalyticsWidgets.formatPercentage(data.improvementRate)}' 
                : AnalyticsWidgets.formatPercentage(data.improvementRate),
            color: data.improvementRate >= 0 ? AppColors.add : AppColors.delete,
          ),
          const SizedBox(height: AppTheme.largeSpacing),
        ],
      ],
    );
  }

  Widget _buildImprovementChart(StudentStatisticsData data) {
    if (data.scoreHistory.isEmpty) {
      return AnalyticsWidgets.emptyChartState(message: 'No history data yet');
    }

    final spots = data.scoreHistory.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();

    final labels = data.scoreHistory.asMap().entries.map((entry) {
      return '#${entry.key + 1}';
    }).toList();

    return AnalyticsWidgets.lineChart(
      spots: spots,
      title: 'Score History (Last 10 Quizzes)',
      labels: labels,
      color: AppColors.primary,
      showAverageLine: true,
    );
  }

  Widget _buildRecentResultsSection(StudentStatisticsData data) {
    final isExpanded = _expandedSections['recent'] ?? true;
    return Column(
      children: [
        AnalyticsWidgets.sectionHeader(
          title: 'Recent Quiz Results',
          isExpanded: isExpanded,
          onTap: () => _toggleSection('recent'),
          icon: LucideIcons.history,
        ),
        if (isExpanded) ...[
          const SizedBox(height: AppTheme.smallSpacing),
          if (data.recentResults.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacing4),
                child: Text(
                  'No recent results',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            )
          else
            ...data.recentResults.take(5).map((result) => Card(
                  margin: const EdgeInsets.only(bottom: AppTheme.smallSpacing),
                  child: ListTile(
                    leading: Icon(
                      result.passed ? LucideIcons.checkCircle : LucideIcons.xCircle,
                      color: result.passed ? AppColors.add : AppColors.delete,
                    ),
                    title: Text(result.topicName),
                    subtitle: Text(
                      '${result.difficulty} • ${AnalyticsWidgets.formatRelativeDate(result.date)}',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          AnalyticsWidgets.formatPercentage(result.percentage),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${result.correctAnswers}/${result.totalQuestions}',
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
      ],
    );
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

  Future<StudentStatisticsData> _loadStatisticsData() async {
    final auth = await ServiceLocator.auth;
    final user = await auth.getCurrentUser();
    if (user == null) {
      throw Exception('User not found');
    }

    final results = await _db.getResultsForUser(user.id!);
    final topics = await _db.getAllTopics();

    if (results.isEmpty) {
      return StudentStatisticsData.empty();
    }

    final totalQuizzes = results.length;
    final averageScore = results.map((r) => r.percentage).reduce((a, b) => a + b) / totalQuizzes;
    final highestScore = results.map((r) => r.percentage).reduce((a, b) => a > b ? a : b);

    // Topic performance
    final topicPerformance = <String, List<double>>{};
    final topicCounts = <String, int>{};
    for (final result in results) {
      final topic = topics.firstWhere(
        (t) => t.id == result.topicId,
        orElse: () => Topic(id: result.topicId, name: 'Unknown', description: ''),
      );
      topicPerformance.putIfAbsent(topic.name, () => []).add(result.percentage);
      topicCounts[topic.name] = (topicCounts[topic.name] ?? 0) + 1;
    }

    final topicAverages = <String, double>{};
    topicPerformance.forEach((topic, scores) {
      topicAverages[topic] = scores.reduce((a, b) => a + b) / scores.length;
    });

    final bestTopic = topicAverages.isEmpty 
        ? 'N/A' 
        : topicAverages.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    final weakestTopic = topicAverages.isEmpty 
        ? 'N/A' 
        : topicAverages.entries.reduce((a, b) => a.value < b.value ? a : b).key;

    // Difficulty performance
    final difficultyPerformance = <String, double>{};
    for (final difficulty in [AppConstants.difficultyEasy, AppConstants.difficultyMedium, AppConstants.difficultyHard]) {
      final difficultyResults = results.where((r) => r.difficulty == difficulty);
      if (difficultyResults.isNotEmpty) {
        final avg = difficultyResults.map((r) => r.percentage).reduce((a, b) => a + b) / difficultyResults.length;
        difficultyPerformance[difficulty] = avg;
      }
    }

    // Score history for improvement trend
    final scoreHistory = results.take(10).map((r) => r.percentage).toList();

    // Calculate improvement rate (compare first half with second half)
    double improvementRate = 0;
    if (scoreHistory.length >= 4) {
      final midPoint = scoreHistory.length ~/ 2;
      final firstHalfAvg = scoreHistory.sublist(0, midPoint).reduce((a, b) => a + b) / midPoint;
      final secondHalfAvg = scoreHistory.sublist(midPoint).reduce((a, b) => a + b) / (scoreHistory.length - midPoint);
      improvementRate = secondHalfAvg - firstHalfAvg;
    }

    // Recent results with details
    final recentResults = <RecentQuizResult>[];
    for (final result in results.take(5)) {
      final topic = topics.firstWhere(
        (t) => t.id == result.topicId,
        orElse: () => Topic(id: result.topicId, name: 'Unknown', description: ''),
      );
      if (result.id != null) {
        final answers = await _db.getAnswersForResult(result.id!);
        final correctAnswers = answers.where((a) => a.isCorrect).length;
        
        recentResults.add(RecentQuizResult(
          topicName: topic.name,
          difficulty: result.difficulty,
          percentage: result.percentage,
          passed: result.passed,
          date: DateTime.parse(result.createdAt),
          correctAnswers: correctAnswers,
          totalQuestions: result.totalQuestions,
        ));
      }
    }

    return StudentStatisticsData(
      results: results,
      totalQuizzes: totalQuizzes,
      averageScore: averageScore,
      highestScore: highestScore,
      bestTopic: bestTopic,
      weakestTopic: weakestTopic,
      topicPerformance: topicAverages,
      difficultyPerformance: difficultyPerformance,
      scoreHistory: scoreHistory,
      improvementRate: improvementRate,
      recentResults: recentResults,
    );
  }
}

class StudentStatisticsData {
  final List<QuizResult> results;
  final int totalQuizzes;
  final double averageScore;
  final double highestScore;
  final String bestTopic;
  final String weakestTopic;
  final Map<String, double> topicPerformance;
  final Map<String, double> difficultyPerformance;
  final List<double> scoreHistory;
  final double improvementRate;
  final List<RecentQuizResult> recentResults;

  StudentStatisticsData({
    required this.results,
    required this.totalQuizzes,
    required this.averageScore,
    required this.highestScore,
    required this.bestTopic,
    required this.weakestTopic,
    required this.topicPerformance,
    required this.difficultyPerformance,
    required this.scoreHistory,
    required this.improvementRate,
    required this.recentResults,
  });

  factory StudentStatisticsData.empty() {
    return StudentStatisticsData(
      results: [],
      totalQuizzes: 0,
      averageScore: 0,
      highestScore: 0,
      bestTopic: 'N/A',
      weakestTopic: 'N/A',
      topicPerformance: {},
      difficultyPerformance: {},
      scoreHistory: [],
      improvementRate: 0,
      recentResults: [],
    );
  }
}

class RecentQuizResult {
  final String topicName;
  final String difficulty;
  final double percentage;
  final bool passed;
  final DateTime date;
  final int correctAnswers;
  final int totalQuestions;

  RecentQuizResult({
    required this.topicName,
    required this.difficulty,
    required this.percentage,
    required this.passed,
    required this.date,
    required this.correctAnswers,
    required this.totalQuestions,
  });
}
