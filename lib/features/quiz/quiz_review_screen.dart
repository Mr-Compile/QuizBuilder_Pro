import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../database/database_helper.dart';
import '../../models/question.dart';
import '../../models/quiz_answer.dart';
import '../../services/service_locator.dart';
import '../../widgets/role_guard.dart';

/// Shows each question, the student's answer and the correct answer.
class QuizReviewScreen extends StatefulWidget {
  final int? resultId;

  const QuizReviewScreen({super.key, this.resultId});

  @override
  State<QuizReviewScreen> createState() => _QuizReviewScreenState();
}

class _QuizReviewScreenState extends State<QuizReviewScreen> {
  final _db = ServiceLocator.db;
  late Future<List<QuizAnswer>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    if (widget.resultId != null) {
      _future = _db.getAnswersForResult(widget.resultId!);
    } else {
      _future = Future.value([]);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRole: AppConstants.roleStudent,
      child: Scaffold(
        appBar: AppBar(title: const Text('Review Answers')),
        body: FutureBuilder(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final answers = snapshot.data ?? [];
            if (answers.isEmpty) {
              return const Center(child: Text('No answers to review.'));
            }

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppTheme.mediumSpacing),
                    itemCount: answers.length,
                    itemBuilder: (context, index) {
                      final a = answers[index];
                      return _ReviewCard(answer: a, db: _db);
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(AppTheme.mediumSpacing),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
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
                          onPressed: () => Navigator.pushNamedAndRemoveUntil(
                            context,
                            AppRoutes.topicSelect,
                            (route) => false,
                          ),
                          icon: const Icon(LucideIcons.refreshCcw, size: 16),
                          label: const Text('New Quiz'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.startQuiz,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final QuizAnswer answer;
  final DatabaseHelper db;

  const _ReviewCard({required this.answer, required this.db});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: db.getQuestionById(answer.questionId),
      builder: (context, snapshot) {
        final question = snapshot.data;
        if (question == null) return const SizedBox.shrink();

        final color = answer.isCorrect ? AppColors.add : AppColors.delete;

        return Card(
          elevation: 2,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.1),
                  color.withValues(alpha: 0.05),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacing2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppTheme.roundedLg),
                        ),
                        child: Icon(
                          answer.isCorrect ? LucideIcons.checkCircle : LucideIcons.xCircle,
                          color: color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppTheme.smallSpacing),
                      Expanded(
                        child: Text(
                          question.question,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.mediumSpacing),
                  _AnswerRow(label: 'Your answer', value: answer.userAnswer, question: question, isCorrect: answer.isCorrect),
                  _AnswerRow(label: 'Correct answer', value: answer.correctAnswer, question: question, isCorrect: true),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AnswerRow extends StatelessWidget {
  final String label;
  final String value;
  final Question question;
  final bool isCorrect;

  const _AnswerRow({
    required this.label,
    required this.value,
    required this.question,
    required this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    final text = value.isEmpty ? 'Not Answered' : question.optionLetterToText(value);
    final color = isCorrect ? AppColors.add : AppColors.delete;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 0,
            child: Text(
              '$label: ${value.isEmpty ? '-' : value}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                  ),
            ),
          ),
          const SizedBox(width: AppTheme.smallSpacing),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.end,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: value.isEmpty ? Colors.grey : color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
