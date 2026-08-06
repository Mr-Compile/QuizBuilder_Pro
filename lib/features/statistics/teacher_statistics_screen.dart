import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/quiz_result.dart';
import '../../models/user.dart';
import '../../models/topic.dart';
import '../../services/service_locator.dart';
import '../../widgets/role_guard.dart';
import '../../widgets/navigation_scaffold.dart';
import '../../widgets/enhanced_cards.dart';
import '../../widgets/analytics_widgets.dart';
import '../../core/routes/app_routes.dart';

/// Global statistics visible only to teachers with collapsible sections.
class TeacherStatisticsScreen extends StatefulWidget {
  const TeacherStatisticsScreen({super.key});

  @override
  State<TeacherStatisticsScreen> createState() => _TeacherStatisticsScreenState();
}

class _TeacherStatisticsScreenState extends State<TeacherStatisticsScreen> {
  final _db = ServiceLocator.db;
  late Future<StatisticsData> _dataFuture;

  // Section expansion states
  final Map<String, bool> _expandedSections = {
    'overview': true,
    'performance': true,
    'difficulty': true,
    'topic': true,
    'students': true,
    'trends': true,
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
      allowedRole: AppConstants.roleTeacher,
      child: NavigationScaffold(
        title: 'Global Statistics',
        currentRoute: AppRoutes.teacherStatistics,
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
              return const Center(child: Text('No attempts yet.'));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.mediumSpacing),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOverviewSection(data),
                  _buildPerformanceSection(data),
                  _buildDifficultySection(data),
                  _buildTopicSection(data),
                  _buildStudentRankingsSection(data),
                  _buildTrendsSection(data),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOverviewSection(StatisticsData data) {
    final isExpanded = _expandedSections['overview'] ?? true;
    return Column(
      children: [
        AnalyticsWidgets.sectionHeader(
          title: 'Overview',
          isExpanded: isExpanded,
          onTap: () => _toggleSection('overview'),
          icon: LucideIcons.layoutDashboard,
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
                    icon: LucideIcons.clipboardList,
                    label: 'Total Attempts',
                    value: AnalyticsWidgets.formatNumber(data.totalAttempts),
                    color: AppColors.primary,
                  ),
                  DataCard(
                    icon: LucideIcons.percent,
                    label: 'Average Score',
                    value: AnalyticsWidgets.formatPercentage(data.averageScore),
                    color: AppColors.accent,
                  ),
                  DataCard(
                    icon: LucideIcons.trendingUp,
                    label: 'Highest Score',
                    value: AnalyticsWidgets.formatPercentage(data.highestScore),
                    color: AppColors.add,
                  ),
                  DataCard(
                    icon: LucideIcons.trendingDown,
                    label: 'Lowest Score',
                    value: AnalyticsWidgets.formatPercentage(data.lowestScore),
                    color: AppColors.delete,
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

  Widget _buildPerformanceSection(StatisticsData data) {
    final isExpanded = _expandedSections['performance'] ?? true;
    return Column(
      children: [
        AnalyticsWidgets.sectionHeader(
          title: 'Performance Analytics',
          isExpanded: isExpanded,
          onTap: () => _toggleSection('performance'),
          icon: LucideIcons.barChart2,
        ),
        if (isExpanded) ...[
          const SizedBox(height: AppTheme.smallSpacing),
          DataCard(
            icon: LucideIcons.percent,
            label: 'Average Score',
            value: AnalyticsWidgets.formatPercentage(data.averageScore),
            color: AppColors.accent,
          ),
          const SizedBox(height: AppTheme.smallSpacing),
          DataCard(
            icon: LucideIcons.checkCircle,
            label: 'Pass Rate',
            value: AnalyticsWidgets.formatPercentage(data.passRate),
            color: AppColors.add,
          ),
          const SizedBox(height: AppTheme.smallSpacing),
          DataCard(
            icon: LucideIcons.xCircle,
            label: 'Failure Rate',
            value: AnalyticsWidgets.formatPercentage(data.failureRate),
            color: AppColors.delete,
          ),
          const SizedBox(height: AppTheme.largeSpacing),
        ],
      ],
    );
  }

  Widget _buildDifficultySection(StatisticsData data) {
    final isExpanded = _expandedSections['difficulty'] ?? true;
    return Column(
      children: [
        AnalyticsWidgets.sectionHeader(
          title: 'Difficulty Analytics',
          isExpanded: isExpanded,
          onTap: () => _toggleSection('difficulty'),
          icon: LucideIcons.layers,
        ),
        if (isExpanded) ...[
          const SizedBox(height: AppTheme.smallSpacing),
          for (final entry in data.difficultyStats.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.smallSpacing),
              child: DataCard(
                icon: LucideIcons.activity,
                label: entry.key,
                value: '${AnalyticsWidgets.formatNumber(entry.value.attempts)} attempts',
                color: _getDifficultyColor(entry.key),
              ),
            ),
          const SizedBox(height: AppTheme.largeSpacing),
        ],
      ],
    );
  }

  Widget _buildTopicSection(StatisticsData data) {
    final isExpanded = _expandedSections['topic'] ?? true;
    return Column(
      children: [
        AnalyticsWidgets.sectionHeader(
          title: 'Topic Analytics',
          isExpanded: isExpanded,
          onTap: () => _toggleSection('topic'),
          icon: LucideIcons.bookOpen,
        ),
        if (isExpanded) ...[
          const SizedBox(height: AppTheme.smallSpacing),
          DataCard(
            icon: LucideIcons.target,
            label: 'Most Attempted Topic',
            value: data.mostAttemptedTopic,
            color: AppColors.primary,
          ),
          const SizedBox(height: AppTheme.smallSpacing),
          DataCard(
            icon: LucideIcons.trophy,
            label: 'Highest Scoring Topic',
            value: data.highestScoringTopic,
            color: AppColors.add,
          ),
          const SizedBox(height: AppTheme.smallSpacing),
          DataCard(
            icon: LucideIcons.trendingDown,
            label: 'Lowest Scoring Topic',
            value: data.lowestScoringTopic,
            color: AppColors.delete,
          ),
          const SizedBox(height: AppTheme.largeSpacing),
        ],
      ],
    );
  }

  Widget _buildStudentRankingsSection(StatisticsData data) {
    final isExpanded = _expandedSections['students'] ?? true;
    return Column(
      children: [
        AnalyticsWidgets.sectionHeader(
          title: 'Student Rankings',
          isExpanded: isExpanded,
          onTap: () => _toggleSection('students'),
          icon: LucideIcons.award,
        ),
        if (isExpanded) ...[
          const SizedBox(height: AppTheme.smallSpacing),
          if (data.topStudents.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacing4),
                child: Text(
                  'No student data available',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            )
          else
            ...data.topStudents.asMap().entries.map((entry) {
              final index = entry.key;
              final student = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: AppTheme.smallSpacing),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getRankColor(index),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(student.name),
                  subtitle: Text('${student.passCount} passed quizzes'),
                  trailing: Text(
                    AnalyticsWidgets.formatPercentage(student.averageScore),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            }),
          const SizedBox(height: AppTheme.largeSpacing),
        ],
      ],
    );
  }

  Widget _buildTrendsSection(StatisticsData data) {
    final isExpanded = _expandedSections['trends'] ?? true;
    return Column(
      children: [
        AnalyticsWidgets.sectionHeader(
          title: 'Trend Analytics',
          isExpanded: isExpanded,
          onTap: () => _toggleSection('trends'),
          icon: LucideIcons.trendingUp,
        ),
        if (isExpanded) ...[
          const SizedBox(height: AppTheme.smallSpacing),
          _buildWeeklyTrendChart(data),
          const SizedBox(height: AppTheme.mediumSpacing),
          _buildMonthlyParticipationChart(data),
        ],
      ],
    );
  }

  Widget _buildWeeklyTrendChart(StatisticsData data) {
    if (data.weeklyTrend.isEmpty) {
      return AnalyticsWidgets.emptyChartState(message: 'No weekly trend data');
    }

    final spots = data.weeklyTrend.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.toDouble());
    }).toList();

    final labels = _getLast7DaysLabels();

    return AnalyticsWidgets.lineChart(
      spots: spots,
      title: 'Weekly Quiz Trend',
      labels: labels,
      color: AppColors.primary,
    );
  }

  Widget _buildMonthlyParticipationChart(StatisticsData data) {
    if (data.monthlyData.isEmpty) {
      return AnalyticsWidgets.emptyChartState(message: 'No monthly data');
    }

    final barGroups = data.monthlyData.entries.map((entry) {
      return BarChartGroupData(
        x: data.monthlyData.keys.toList().indexOf(entry.key),
        barRods: [
          BarChartRodData(
            toY: entry.value.toDouble(),
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
      title: 'Monthly Participation',
      labels: data.monthlyData.keys.toList(),
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

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber;
      case 1:
        return Colors.grey;
      case 2:
        return Colors.brown;
      default:
        return AppColors.primary;
    }
  }

  Future<StatisticsData> _loadStatisticsData() async {
    final results = await _db.getAllResults();
    final students = await _db.getAllStudents();
    final topics = await _db.getAllTopics();

    if (results.isEmpty) {
      return StatisticsData.empty();
    }

    final total = results.length;
    final avg = results.map((r) => r.percentage).reduce((a, b) => a + b) / total;
    final highest = results.reduce((a, b) => a.percentage > b.percentage ? a : b);
    final lowest = results.reduce((a, b) => a.percentage < b.percentage ? a : b);

    final passed = results.where((r) => r.passed).length;
    final passRate = (passed / total) * 100;
    final failureRate = 100 - passRate;

    // Difficulty stats
    final difficultyStats = <String, DifficultyStats>{};
    for (final difficulty in [AppConstants.difficultyEasy, AppConstants.difficultyMedium, AppConstants.difficultyHard]) {
      final difficultyResults = results.where((r) => r.difficulty == difficulty);
      if (difficultyResults.isNotEmpty) {
        final avgScore = difficultyResults.map((r) => r.percentage).reduce((a, b) => a + b) / difficultyResults.length;
        difficultyStats[difficulty] = DifficultyStats(
          attempts: difficultyResults.length,
          averageScore: avgScore,
        );
      }
    }

    // Topic analytics
    final topicAttempts = <String, int>{};
    final topicScores = <String, List<double>>{};
    for (final result in results) {
      final topic = topics.firstWhere(
        (t) => t.id == result.topicId,
        orElse: () => Topic(id: result.topicId, name: 'Unknown', description: ''),
      );
      topicAttempts[topic.name] = (topicAttempts[topic.name] ?? 0) + 1;
      topicScores.putIfAbsent(topic.name, () => []).add(result.percentage);
    }

    final mostAttemptedTopic = topicAttempts.isEmpty 
        ? 'N/A' 
        : topicAttempts.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    String highestScoringTopic = 'N/A';
    double highestTopicAvg = 0;
    topicScores.forEach((topic, scores) {
      final avg = scores.reduce((a, b) => a + b) / scores.length;
      if (avg > highestTopicAvg) {
        highestTopicAvg = avg;
        highestScoringTopic = topic;
      }
    });

    String lowestScoringTopic = 'N/A';
    double lowestTopicAvg = 100;
    topicScores.forEach((topic, scores) {
      final avg = scores.reduce((a, b) => a + b) / scores.length;
      if (avg < lowestTopicAvg) {
        lowestTopicAvg = avg;
        lowestScoringTopic = topic;
      }
    });

    // Top students
    final studentStats = <int, StudentStats>{};
    for (final result in results) {
      studentStats.putIfAbsent(result.userId, () => StudentStats(passCount: 0, totalScore: 0, count: 0));
      final stats = studentStats[result.userId]!;
      if (result.passed) {
        stats.passCount++;
      }
      stats.totalScore += result.percentage;
      stats.count++;
    }

    final topStudents = studentStats.entries.map((entry) {
      final student = students.firstWhere(
        (s) => s.id == entry.key,
        orElse: () => User(id: entry.key, fullName: 'Unknown', username: 'unknown', password: '', role: AppConstants.roleStudent),
      );
      final stats = entry.value;
      return TopStudent(
        name: student.fullName,
        passCount: stats.passCount,
        averageScore: stats.totalScore / stats.count,
      );
    }).toList()
      ..sort((a, b) => b.averageScore.compareTo(a.averageScore));

    // Weekly trend
    final weeklyTrend = List<int>.filled(7, 0);
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: 6 - i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      
      weeklyTrend[i] = results.where((r) {
        final resultDate = DateTime.parse(r.createdAt);
        return resultDate.isAfter(dayStart) && resultDate.isBefore(dayEnd);
      }).length;
    }

    // Monthly data
    final monthlyData = <String, int>{};
    for (final result in results) {
      final date = DateTime.parse(result.createdAt);
      final monthKey = DateFormat('MMM y').format(date);
      monthlyData[monthKey] = (monthlyData[monthKey] ?? 0) + 1;
    }

    return StatisticsData(
      results: results,
      totalAttempts: total,
      averageScore: avg,
      highestScore: highest.percentage,
      lowestScore: lowest.percentage,
      passRate: passRate,
      failureRate: failureRate,
      difficultyStats: difficultyStats,
      mostAttemptedTopic: mostAttemptedTopic,
      highestScoringTopic: highestScoringTopic,
      lowestScoringTopic: lowestScoringTopic,
      topStudents: topStudents.take(10).toList(),
      weeklyTrend: weeklyTrend,
      monthlyData: monthlyData,
    );
  }
}

class StatisticsData {
  final List<QuizResult> results;
  final int totalAttempts;
  final double averageScore;
  final double highestScore;
  final double lowestScore;
  final double passRate;
  final double failureRate;
  final Map<String, DifficultyStats> difficultyStats;
  final String mostAttemptedTopic;
  final String highestScoringTopic;
  final String lowestScoringTopic;
  final List<TopStudent> topStudents;
  final List<int> weeklyTrend;
  final Map<String, int> monthlyData;

  StatisticsData({
    required this.results,
    required this.totalAttempts,
    required this.averageScore,
    required this.highestScore,
    required this.lowestScore,
    required this.passRate,
    required this.failureRate,
    required this.difficultyStats,
    required this.mostAttemptedTopic,
    required this.highestScoringTopic,
    required this.lowestScoringTopic,
    required this.topStudents,
    required this.weeklyTrend,
    required this.monthlyData,
  });

  factory StatisticsData.empty() {
    return StatisticsData(
      results: [],
      totalAttempts: 0,
      averageScore: 0,
      highestScore: 0,
      lowestScore: 0,
      passRate: 0,
      failureRate: 0,
      difficultyStats: {},
      mostAttemptedTopic: 'N/A',
      highestScoringTopic: 'N/A',
      lowestScoringTopic: 'N/A',
      topStudents: [],
      weeklyTrend: [],
      monthlyData: {},
    );
  }
}

class DifficultyStats {
  final int attempts;
  final double averageScore;

  DifficultyStats({required this.attempts, required this.averageScore});
}

class StudentStats {
  int passCount;
  double totalScore;
  int count;

  StudentStats({required this.passCount, required this.totalScore, required this.count});
}

class TopStudent {
  final String name;
  final int passCount;
  final double averageScore;

  TopStudent({required this.name, required this.passCount, required this.averageScore});
}
