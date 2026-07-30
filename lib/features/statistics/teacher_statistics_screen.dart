import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/quiz_result.dart';
import '../../models/user.dart';
import '../../services/service_locator.dart';
import '../../widgets/role_guard.dart';

/// Global statistics visible only to teachers.
class TeacherStatisticsScreen extends StatefulWidget {
  const TeacherStatisticsScreen({super.key});

  @override
  State<TeacherStatisticsScreen> createState() => _TeacherStatisticsScreenState();
}

class _TeacherStatisticsScreenState extends State<TeacherStatisticsScreen> {
  final _db = ServiceLocator.db;
  late Future<List<QuizResult>> _future;
  late Future<List<User>> _studentsFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = _db.getAllResults();
    _studentsFuture = _db.getAllStudents();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRole: AppConstants.roleTeacher,
      child: Scaffold(
        appBar: AppBar(title: const Text('Global Statistics')),
        body: FutureBuilder(
          future: _future,
          builder: (context, resultSnapshot) {
            if (resultSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final results = resultSnapshot.data ?? [];

            return FutureBuilder(
              future: _studentsFuture,
              builder: (context, studentsSnapshot) {
                final students = studentsSnapshot.data ?? [];

                if (results.isEmpty) {
                  return const Center(child: Text('No attempts yet.'));
                }

                final total = results.length;
                final avg = results.map((r) => r.percentage).reduce((a, b) => a + b) / total;
                final highest = results.reduce((a, b) => a.percentage > b.percentage ? a : b);
                final lowest = results.reduce((a, b) => a.percentage < b.percentage ? a : b);
                final perDifficulty = _perDifficulty(results);
                final topStudents = _topStudents(results, students);

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.mediumSpacing),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Overview', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: AppTheme.smallSpacing),
                      _StatCard(icon: LucideIcons.clipboardList, label: 'Total Attempts', value: total.toString(), color: AppColors.primary),
                      _StatCard(icon: LucideIcons.percent, label: 'Average Score', value: '${avg.toStringAsFixed(1)}%', color: AppColors.accent),
                      _StatCard(icon: LucideIcons.trendingUp, label: 'Highest Score', value: '${highest.percentage.toStringAsFixed(1)}%', color: AppColors.add),
                      _StatCard(icon: LucideIcons.trendingDown, label: 'Lowest Score', value: '${lowest.percentage.toStringAsFixed(1)}%', color: AppColors.delete),
                      const SizedBox(height: AppTheme.largeSpacing),
                      Text('Attempts per Difficulty', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: AppTheme.smallSpacing),
                      for (final entry in perDifficulty.entries)
                        _StatCard(
                          icon: LucideIcons.activity,
                          label: entry.key,
                          value: entry.value.toString(),
                          color: AppColors.secondary,
                        ),
                      const SizedBox(height: AppTheme.largeSpacing),
                      Text('Top Students', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: AppTheme.smallSpacing),
                      for (final entry in topStudents.entries)
                        _StatCard(
                          icon: LucideIcons.award,
                          label: entry.value,
                          value: '${entry.key} passes',
                          color: AppColors.add,
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Map<String, int> _perDifficulty(List<QuizResult> results) {
    final counts = <String, int>{};
    for (final r in results) {
      counts[r.difficulty] = (counts[r.difficulty] ?? 0) + 1;
    }
    return counts;
  }

  Map<int, String> _topStudents(List<QuizResult> results, List<User> students) {
    final passes = <int, int>{};
    for (final r in results) {
      if (r.passed) {
        passes[r.userId] = (passes[r.userId] ?? 0) + 1;
      }
    }

    final sorted = passes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final map = <int, String>{};
    for (final entry in sorted.take(5)) {
      final student = students.where((s) => s.id == entry.key).firstOrNull;
      map[entry.value] = student?.fullName ?? 'Student';
    }
    return map;
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
