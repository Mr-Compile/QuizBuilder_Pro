import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../database/database_helper.dart';
import '../../models/quiz_result.dart';
import '../../models/topic.dart';
import '../../services/service_locator.dart';
import '../../widgets/role_guard.dart';

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
        final topic = topicSnapshot.data as Topic?;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.mediumSpacing),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.largeSpacing),
                  child: Column(
                    children: [
                      Icon(
                        result.passed ? LucideIcons.trophy : LucideIcons.alertCircle,
                        size: 72,
                        color: result.passed ? AppColors.add : AppColors.delete,
                      ),
                      const SizedBox(height: AppTheme.mediumSpacing),
                      Text(
                        result.passed ? 'PASS' : 'FAIL',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: result.passed ? AppColors.add : AppColors.delete,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: AppTheme.smallSpacing),
                      Text(
                        '${result.percentage.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppTheme.mediumSpacing),
                      _ScoreRow(label: 'Score', value: '${result.score}/${result.totalQuestions}'),
                      _ScoreRow(
                        label: 'Correct',
                        value: '${result.score}',
                        color: AppColors.add,
                      ),
                      _ScoreRow(
                        label: 'Incorrect',
                        value: '${result.totalQuestions - result.score}',
                        color: AppColors.delete,
                      ),
                      _ScoreRow(label: 'Topic', value: topic?.name ?? 'Unknown'),
                      _ScoreRow(label: 'Difficulty', value: result.difficulty),
                      _ScoreRow(label: 'Date', value: result.createdAt.substring(0, 16).replaceFirst('T', ' ')),
                    ],
                  ),
                ),
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
                      icon: const Icon(LucideIcons.home),
                      label: const Text('Dashboard'),
                    ),
                  ),
                  const SizedBox(width: AppTheme.mediumSpacing),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppRoutes.quizReview,
                        arguments: {'resultId': result.id},
                      ),
                      icon: const Icon(LucideIcons.eye),
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
                  icon: const Icon(LucideIcons.refreshCcw),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.startQuiz,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _ScoreRow({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
