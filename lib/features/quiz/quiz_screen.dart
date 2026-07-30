import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../database/database_helper.dart';
import '../../models/question.dart';
import '../../models/quiz_answer.dart';
import '../../models/quiz_result.dart';
import '../../models/topic.dart';
import '../../models/user.dart';
import '../../services/service_locator.dart';
import '../../widgets/role_guard.dart';

/// Quiz engine that shuffles questions and lets the student answer one at a time.
class QuizScreen extends StatefulWidget {
  final Topic topic;
  final String difficulty;

  const QuizScreen({super.key, required this.topic, required this.difficulty});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final _db = ServiceLocator.db;
  late Future<List<Question>> _questionsFuture;

  List<Question> _questions = [];
  int _currentIndex = 0;
  final Map<int, String> _answers = {};
  
  Timer? _timer;
  int _remainingSeconds = 300; // 5 minutes default
  static const int _timePerQuestion = 60; // 1 minute per question

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _remainingSeconds = _questions.length * _timePerQuestion;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _remainingSeconds--;
      });
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _submit(forceFinish: true);
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _loadQuestions() {
    _questionsFuture = _db.getQuestions(
      topicId: widget.topic.id,
      difficulty: widget.difficulty,
    ).then((questions) {
      final copy = List<Question>.of(questions);
      copy.shuffle(Random());
      _startTimer();
      return copy;
    });
    setState(() {});
  }

  Future<void> _submit({bool forceFinish = false}) async {
    if (_currentIndex < _questions.length - 1) {
      setState(() => _currentIndex++);
      return;
    }

    if (!forceFinish) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Finish Quiz?'),
          content: const Text('You are about to finish the quiz. Continue?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.finishQuiz,
                foregroundColor: Colors.white,
              ),
              child: const Text('Finish'),
            ),
          ],
        ),
      );

      if (confirm != true || !mounted) return;
    }

    _timer?.cancel();

    final correctCount = _questions.where((q) => _answers[q.id] == q.correctAnswer).length;
    final total = _questions.length;
    final percentage = total == 0 ? 0.0 : (correctCount / total) * 100;

    final auth = await ServiceLocator.auth;
    final user = await auth.getCurrentUser() as User;
    final now = DateTime.now().toIso8601String();

    final result = QuizResult(
      userId: user.id!,
      topicId: widget.topic.id!,
      difficulty: widget.difficulty,
      score: correctCount,
      totalQuestions: total,
      percentage: percentage,
      createdAt: now,
    );

    final resultId = await _db.insertQuizResult(result);

    final quizAnswers = _questions.map((q) {
      final userAnswer = _answers[q.id] ?? '';
      final isCorrect = userAnswer == q.correctAnswer;
      return QuizAnswer(
        resultId: resultId,
        questionId: q.id!,
        userAnswer: userAnswer,
        correctAnswer: q.correctAnswer,
        isCorrect: isCorrect,
      );
    }).toList();

    await _db.insertQuizAnswers(quizAnswers);

    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.quizResult,
      arguments: {'resultId': resultId},
    );
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRole: AppConstants.roleStudent,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.topic.name} — ${widget.difficulty}'),
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _remainingSeconds < 60 ? AppColors.delete.withOpacity(0.2) : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.clock,
                    size: 18,
                    color: _remainingSeconds < 60 ? AppColors.delete : AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatTime(_remainingSeconds),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _remainingSeconds < 60 ? AppColors.delete : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: FutureBuilder(
          future: _questionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            _questions = snapshot.data ?? [];
            if (_questions.isEmpty) {
              return const Center(child: Text('No questions available for this topic and difficulty.'));
            }

            final question = _questions[_currentIndex];
            final progress = (_currentIndex + 1) / _questions.length;

            return Padding(
              padding: const EdgeInsets.all(AppTheme.mediumSpacing),
              child: Column(
                children: [
                  LinearProgressIndicator(value: progress, minHeight: 8),
                  const SizedBox(height: AppTheme.smallSpacing),
                  Text('Question ${_currentIndex + 1} of ${_questions.length}'),
                  const SizedBox(height: AppTheme.mediumSpacing),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.cardPadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                question.question,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: AppTheme.largeSpacing),
                              _OptionTile(
                                label: 'A',
                                text: question.optionA,
                                selected: _answers[question.id] == 'A',
                                onTap: () => setState(() => _answers[question.id!] = 'A'),
                              ),
                              _OptionTile(
                                label: 'B',
                                text: question.optionB,
                                selected: _answers[question.id] == 'B',
                                onTap: () => setState(() => _answers[question.id!] = 'B'),
                              ),
                              _OptionTile(
                                label: 'C',
                                text: question.optionC,
                                selected: _answers[question.id] == 'C',
                                onTap: () => setState(() => _answers[question.id!] = 'C'),
                              ),
                              _OptionTile(
                                label: 'D',
                                text: question.optionD,
                                selected: _answers[question.id] == 'D',
                                onTap: () => setState(() => _answers[question.id!] = 'D'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.mediumSpacing),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _answers.containsKey(_questions[_currentIndex].id) ? _submit : null,
                      icon: Icon(_currentIndex == _questions.length - 1 ? LucideIcons.check : LucideIcons.arrowRight),
                      label: Text(_currentIndex == _questions.length - 1 ? 'Finish Quiz' : 'Next'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _currentIndex == _questions.length - 1 ? AppColors.finishQuiz : AppColors.startQuiz,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: AppTheme.mediumSpacing),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String label;
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline;
    return Card(
      color: selected ? Theme.of(context).colorScheme.primaryContainer : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: selected ? Theme.of(context).colorScheme.primary : Colors.transparent,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(text),
        onTap: onTap,
      ),
    );
  }
}
