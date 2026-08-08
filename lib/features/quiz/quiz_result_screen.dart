import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../database/database_helper.dart';
import '../../models/quiz_result.dart';
import '../../models/topic.dart';
import '../../services/service_locator.dart';
import '../../widgets/role_guard.dart';
import '../../widgets/enhanced_cards.dart';

/// Displays the score, percentage and pass/fail status after a quiz.
class QuizResultScreen extends StatefulWidget {
  final int? resultId;

  const QuizResultScreen({super.key, this.resultId});

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  final _db = ServiceLocator.db;
  late Future<QuizResult?> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = _db.getAllResults().then((results) {
      if (widget.resultId != null) {
        return results.where((r) => r.id == widget.resultId).firstOrNull;
      }
      return results.isNotEmpty ? results.first : null;
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRole: AppConstants.roleStudent,
      child: Scaffold(
        appBar: AppBar(title: const Text('Quiz Result')),
        body: FutureBuilder(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final result = snapshot.data;
            if (result == null) {
              return const Center(child: Text('Result not found.'));
            }

            return _ResultView(result: result, db: _db);
          },
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  final QuizResult result;
  final DatabaseHelper db;

  const _ResultView({required this.result, required this.db});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: db.getTopicById(result.topicId),
      builder: (context, topicSnapshot) {
        final Topic? topic = topicSnapshot.data;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.mediumSpacing),
          child: Column(
            children: [
              Card(
                elevation: 4,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        (result.passed ? AppColors.add : AppColors.delete).withValues(alpha: 0.1),
                        (result.passed ? AppColors.add : AppColors.delete).withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                  padding: EdgeInsets.all(MediaQuery.of(context).size.width < 360 ? AppTheme.mediumSpacing : AppTheme.largeSpacing),
                  child: Column(
                    children: [
                      Icon(
                        result.passed ? LucideIcons.trophy : LucideIcons.alertCircle,
                        size: MediaQuery.of(context).size.width < 360 ? 48 : 64,
                        color: result.passed ? AppColors.add : AppColors.delete,
                      ),
                      const SizedBox(height: AppTheme.mediumSpacing),
                      StatusBadge(
                        label: result.passed ? 'PASS' : 'FAIL',
                        color: result.passed ? AppColors.add : AppColors.delete,
                        isActive: true,
                      ),
                      const SizedBox(height: AppTheme.smallSpacing),
                      Text(
                        '${result.percentage.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: result.passed ? AppColors.add : AppColors.delete,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.mediumSpacing),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isSmallScreen = constraints.maxWidth < 360;
                  return Wrap(
                    spacing: AppTheme.smallSpacing,
                    runSpacing: AppTheme.smallSpacing,
                    children: [
                      SizedBox(
                        width: isSmallScreen ? constraints.maxWidth : (constraints.maxWidth - AppTheme.smallSpacing) / 2,
                        child: DataCard(
                          icon: LucideIcons.target,
                          label: 'Score',
                          value: '${result.score}/${result.totalQuestions}',
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(
                        width: isSmallScreen ? constraints.maxWidth : (constraints.maxWidth - AppTheme.smallSpacing) / 2,
                        child: DataCard(
                          icon: LucideIcons.checkCircle,
                          label: 'Correct',
                          value: '${result.score}',
                          color: AppColors.add,
                        ),
                      ),
                      SizedBox(
                        width: isSmallScreen ? constraints.maxWidth : (constraints.maxWidth - AppTheme.smallSpacing) / 2,
                        child: DataCard(
                          icon: LucideIcons.xCircle,
                          label: 'Incorrect',
                          value: '${result.totalQuestions - result.score}',
                          color: AppColors.delete,
                        ),
                      ),
                      SizedBox(
                        width: isSmallScreen ? constraints.maxWidth : (constraints.maxWidth - AppTheme.smallSpacing) / 2,
                        child: DataCard(
                          icon: LucideIcons.bookOpen,
                          label: 'Topic',
                          value: topic?.name ?? 'Unknown',
                          color: AppColors.secondary,
                        ),
                      ),
                      SizedBox(
                        width: isSmallScreen ? constraints.maxWidth : (constraints.maxWidth - AppTheme.smallSpacing) / 2,
                        child: DataCard(
                          icon: LucideIcons.layers,
                          label: 'Difficulty',
                          value: result.difficulty,
                          color: AppColors.accent,
                        ),
                      ),
                      SizedBox(
                        width: isSmallScreen ? constraints.maxWidth : (constraints.maxWidth - AppTheme.smallSpacing) / 2,
                        child: DataCard(
                          icon: LucideIcons.calendar,
                          label: 'Date',
                          value: result.createdAt.substring(0, 16).replaceFirst('T', ' '),
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppTheme.largeSpacing),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.studentDashboard,
                        (route) => false,
                      ),
                      icon: const Icon(LucideIcons.home, size: 16),
                      label: const Text('Dashboard'),
                    ),
                  ),
                  const SizedBox(width: AppTheme.smallSpacing),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppRoutes.quizReview,
                        arguments: {'resultId': result.id},
                      ),
                      icon: const Icon(LucideIcons.eye, size: 16),
                      label: const Text('Review'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.edit,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.smallSpacing),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.topicSelect,
                    (route) => false,
                  ),
                  icon: const Icon(LucideIcons.refreshCcw, size: 16),
                  label: const Text('Try Another Quiz'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.startQuiz,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.smallSpacing),
              TextButton.icon(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.studentDashboard,
                  (route) => false,
                ),
                icon: const Icon(LucideIcons.skipForward, size: 16),
                label: const Text('Skip Review & Go to Dashboard'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: AppTheme.smallSpacing),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => ServiceLocator.export.exportToPdf(result.id!),
                      icon: const Icon(LucideIcons.fileText, size: 16),
                      label: const Text('Export PDF'),
                    ),
                  ),
                  const SizedBox(width: AppTheme.smallSpacing),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => ServiceLocator.export.exportToExcel(result.id!),
                      icon: const Icon(LucideIcons.table, size: 16),
                      label: const Text('Export Excel'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
