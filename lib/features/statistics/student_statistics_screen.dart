import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../database/database_helper.dart';
import '../../models/quiz_result.dart';
import '../../services/service_locator.dart';
import '../../widgets/role_guard.dart';

/// Statistics screen for the logged-in student.
class StudentStatisticsScreen extends StatefulWidget {
  const StudentStatisticsScreen({super.key});

  @override
  State<StudentStatisticsScreen> createState() => _StudentStatisticsScreenState();
}

class _StudentStatisticsScreenState extends State<StudentStatisticsScreen> {
  final _db = ServiceLocator.db;
  late Future<List<QuizResult>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = _loadResults();
    setState(() {});
  }

  Future<List<QuizResult>> _loadResults() async {
    final auth = await ServiceLocator.auth;
    final user = await auth.getCurrentUser();
    if (user == null) return [];
    return _db.getResultsForUser(user.id!);
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRole: AppConstants.roleStudent,
      child: Scaffold(
        appBar: AppBar(title: const Text('My Statistics')),
        body: FutureBuilder(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final results = snapshot.data ?? [];
            if (results.isEmpty) {
              return const Center(child: Text('No data yet. Take a quiz!'));
            }

            final total = results.length;
            final avg = results.map((r) => r.percentage).reduce((a, b) => a + b) / total;
            final highest = results.reduce((a, b) => a.percentage > b.percentage ? a : b);
            final bestTopicId = _bestTopic(results);
            final bestDifficulty = _bestDifficulty(results);

            return Padding(
              padding: const EdgeInsets.all(AppTheme.mediumSpacing),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Summary', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppTheme.smallSpacing),
                  _StatCard(icon: LucideIcons.activity, label: 'Quizzes Taken', value: total.toString(), color: AppColors.primary),
                  _StatCard(icon: LucideIcons.percent, label: 'Average Score', value: '${avg.toStringAsFixed(1)}%', color: AppColors.accent),
                  _StatCard(icon: LucideIcons.trophy, label: 'Highest Score', value: '${highest.percentage.toStringAsFixed(1)}%', color: AppColors.add),
                  _FutureTopicCard(topicId: bestTopicId, db: _db, label: 'Best Topic'),
                  _StatCard(icon: LucideIcons.layers, label: 'Best Difficulty', value: bestDifficulty, color: AppColors.secondary),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  int _bestTopic(List<QuizResult> results) {
    final counts = <int, int>{};
    for (final r in results) {
      if (r.passed) {
        counts[r.topicId] = (counts[r.topicId] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return results.first.topicId;
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  String _bestDifficulty(List<QuizResult> results) {
    final counts = <String, int>{};
    for (final r in results) {
      if (r.passed) {
        counts[r.difficulty] = (counts[r.difficulty] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return 'N/A';
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(label),
        trailing: Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color)),
      ),
    );
  }
}

class _FutureTopicCard extends StatelessWidget {
  final int topicId;
  final DatabaseHelper db;
  final String label;

  const _FutureTopicCard({
    required this.topicId,
    required this.db,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: db.getTopicById(topicId),
      builder: (context, snapshot) {
        final topic = snapshot.data;
        return _StatCard(
          icon: LucideIcons.bookOpen,
          label: label,
          value: topic?.name ?? 'Unknown',
          color: AppColors.secondary,
        );
      },
    );
  }
}
