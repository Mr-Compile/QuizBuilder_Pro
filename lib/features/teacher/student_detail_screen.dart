import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/quiz_result.dart';
import '../../models/user.dart';
import '../../services/service_locator.dart';
import '../../widgets/role_guard.dart';
import '../../widgets/enhanced_cards.dart';
import '../../widgets/navigation_scaffold.dart';
import '../../core/routes/app_routes.dart';

/// Teacher view for a single student's performance and progress.
class StudentDetailScreen extends StatefulWidget {
  final User student;

  const StudentDetailScreen({super.key, required this.student});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  final _db = ServiceLocator.db;
  late Future<List<QuizResult>> _resultsFuture;
  late Future<List<Map<String, dynamic>>> _topicsFuture;

  static const double _smallSpacing = AppTheme.spacing2;
  static const double _mediumSpacing = AppTheme.spacing4;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _resultsFuture = _db.getResultsForStudent(widget.student.id!);
    _topicsFuture = _db.getTopicPerformanceForStudent(widget.student.id!);
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRole: AppConstants.roleTeacher,
      child: NavigationScaffold(
        title: widget.student.fullName,
        currentRoute: AppRoutes.studentDetail,
        showDrawer: false,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(_mediumSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStudentHeader(context),
              const SizedBox(height: _mediumSpacing),
              _buildResultsSection(context),
              const SizedBox(height: _mediumSpacing),
              _buildTopicPerformanceSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentHeader(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(_mediumSpacing),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: widget.student.isActive ? AppColors.add : AppColors.cancel,
              child: Icon(
                widget.student.isActive ? LucideIcons.userCheck : LucideIcons.userX,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: _mediumSpacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.student.fullName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text('@${widget.student.username}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600)),
                  const SizedBox(height: 4),
                  StatusBadge(
                    label: widget.student.isActive ? 'Active' : 'Inactive',
                    color: widget.student.isActive ? AppColors.add : AppColors.cancel,
                    isActive: widget.student.isActive,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Results', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: _smallSpacing),
        FutureBuilder(
          future: _resultsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final results = snapshot.data ?? [];

            if (results.isEmpty) {
              return _buildEmptyBox('No quiz attempts yet.');
            }

            final avg = results.isEmpty ? 0.0 : results.map((r) => r.percentage).reduce((a, b) => a + b) / results.length;

            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: EnhancedSummaryCard(
                        label: 'Attempts',
                        value: results.length.toString(),
                        icon: LucideIcons.clipboardList,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: _smallSpacing),
                    Expanded(
                      child: EnhancedSummaryCard(
                        label: 'Avg Score',
                        value: '${avg.toStringAsFixed(1)}%',
                        icon: LucideIcons.percent,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: _smallSpacing),
                ...results.take(10).map((r) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: r.passed ? AppColors.add : AppColors.delete,
                      child: Icon(r.passed ? LucideIcons.check : LucideIcons.x, color: Colors.white),
                    ),
                    title: Text('${r.score}/${r.totalQuestions} correct'),
                    subtitle: Text('Difficulty: ${r.difficulty}'),
                    trailing: Text('${r.percentage.toStringAsFixed(1)}%'),
                  ),
                )),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildTopicPerformanceSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Topic Breakdown', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: _smallSpacing),
        FutureBuilder(
          future: _topicsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final topics = snapshot.data ?? [];

            if (topics.isEmpty) {
              return _buildEmptyBox('No topic data available.');
            }

            return Column(
              children: topics.map((t) {
                final avg = (t['avg_percentage'] as num).toDouble();
                final color = avg >= 60 ? AppColors.add : (avg >= 40 ? AppColors.accent : AppColors.delete);
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withValues(alpha: 0.15),
                      child: Icon(LucideIcons.bookOpen, color: color),
                    ),
                    title: Text(t['topic_name'] as String),
                    subtitle: Text('Attempts: ${t['attempts']}  |  Best: ${(t['best_percentage'] as num).toDouble().toStringAsFixed(1)}%'),
                    trailing: Text(
                      '${avg.toStringAsFixed(1)}%',
                      style: TextStyle(color: color, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyBox(String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(_mediumSpacing),
        child: Center(child: Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600))),
      ),
    );
  }
}
