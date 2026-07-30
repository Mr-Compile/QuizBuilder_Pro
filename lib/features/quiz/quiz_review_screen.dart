import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
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

            return ListView.builder(
              padding: const EdgeInsets.all(AppTheme.mediumSpacing),
              itemCount: answers.length,
              itemBuilder: (context, index) {
                final a = answers[index];
                return _ReviewCard(answer: a, db: _db);
              },
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

        return Card(
          color: answer.isCorrect ? AppColors.correct.withValues(alpha: 0.2) : AppColors.incorrect.withValues(alpha: 0.2),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      answer.isCorrect ? LucideIcons.checkCircle : LucideIcons.xCircle,
                      color: answer.isCorrect ? AppColors.add : AppColors.delete,
                    ),
                    const SizedBox(width: AppTheme.smallSpacing),
                    Expanded(
                      child: Text(
                        question.question,
                        style: Theme.of(context).textTheme.titleSmall,
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
    final text = question.optionLetterToText(value);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('$label: $value'),
        Expanded(
          child: Text(
            text,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: isCorrect ? AppColors.add : AppColors.delete,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
