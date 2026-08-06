import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/quiz_result.dart';
import '../../services/service_locator.dart';
import '../../widgets/role_guard.dart';

/// Practice mode that focuses only on questions the student has answered incorrectly.
class ReviewWrongAnswersScreen extends StatefulWidget {
  const ReviewWrongAnswersScreen({super.key});

  @override
  State<ReviewWrongAnswersScreen> createState() => _ReviewWrongAnswersScreenState();
}

class _ReviewWrongAnswersScreenState extends State<ReviewWrongAnswersScreen> {
  final _db = ServiceLocator.db;
  final _authFuture = ServiceLocator.auth;
  late Future<void> _loadFuture;

  List<Map<String, dynamic>> _questions = [];
  int _currentIndex = 0;
  String? _selectedAnswer;
  bool _answered = false;
  int _correctCount = 0;
  bool _isFinished = false;

  static const double _smallSpacing = AppTheme.spacing2;
  static const double _mediumSpacing = AppTheme.spacing4;
  static const double _largeSpacing = AppTheme.spacing6;

  @override
  void initState() {
    super.initState();
    _loadFuture = _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final auth = await _authFuture;
    final user = await auth.getCurrentUser();
    if (user == null) return;
    final questions = await _db.getWrongAnswersForStudent(user.id!, limit: 20);
    questions.shuffle(Random());
    setState(() {
      _questions = questions;
    });
  }

  void _selectAnswer(String answer) {
    if (_answered) return;
    setState(() {
      _selectedAnswer = answer;
      _answered = true;
      if (answer == _questions[_currentIndex]['correct_answer']) {
        _correctCount++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _answered = false;
      });
    } else {
      setState(() => _isFinished = true);
    }
  }

  Future<void> _saveResult() async {
    final auth = await _authFuture;
    final user = await auth.getCurrentUser();
    if (user == null || _questions.isEmpty) return;

    final now = DateTime.now().toIso8601String();
    final percentage = (_correctCount / _questions.length) * 100;
    final topicId = _questions.first['topic_id'] as int;
    final result = QuizResult(
      userId: user.id!,
      topicId: topicId,
      difficulty: 'Review',
      score: _correctCount,
      totalQuestions: _questions.length,
      percentage: percentage,
      createdAt: now,
    );
    await _db.insertQuizResult(result);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.studentDashboard);
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRole: AppConstants.roleStudent,
      child: Scaffold(
        appBar: AppBar(title: const Text('Review Mistakes'), elevation: 0),
        body: FutureBuilder(
          future: _loadFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_questions.isEmpty) {
              return _buildEmptyState(context);
            }

            if (_isFinished) {
              return _buildFinishedState(context);
            }

            return _buildQuestion(context);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.award, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: _mediumSpacing),
          Text('Great job!', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: _smallSpacing),
          Text(
            'You have no wrong answers to review. Keep up the good work!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: _largeSpacing),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.studentDashboard),
            icon: const Icon(LucideIcons.home),
            label: const Text('Back to Dashboard'),
          ),
        ],
      ),
    );
  }

  Widget _buildFinishedState(BuildContext context) {
    final percentage = (_correctCount / _questions.length) * 100;
    final passed = percentage >= 60;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(_mediumSpacing),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              passed ? LucideIcons.award : LucideIcons.bookOpen,
              size: 80,
              color: passed ? AppColors.add : AppColors.accent,
            ),
            const SizedBox(height: _mediumSpacing),
            Text('Review Complete!', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: _smallSpacing),
            Text(
              'You got $_correctCount out of ${_questions.length} correct.',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: passed ? AppColors.add : AppColors.delete,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: _largeSpacing),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveResult,
                icon: const Icon(LucideIcons.save),
                label: const Text('Save Review Session'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.add, foregroundColor: Colors.white),
              ),
            ),
            const SizedBox(height: _smallSpacing),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.studentDashboard),
                icon: const Icon(LucideIcons.home),
                label: const Text('Back to Dashboard'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestion(BuildContext context) {
    final q = _questions[_currentIndex];
    final correctAnswer = q['correct_answer'] as String;
    final options = ['A', 'B', 'C', 'D'];
    final optionLabels = [q['option_a'], q['option_b'], q['option_c'], q['option_d']];

    return Padding(
      padding: const EdgeInsets.all(_mediumSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Question ${_currentIndex + 1} of ${_questions.length}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: _smallSpacing),
          LinearProgressIndicator(
            value: (_currentIndex + 1) / _questions.length,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: _largeSpacing),
          Text(
            q['question'] as String,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: _smallSpacing),
          Text(
            'Topic: ${q['topic_name']}  |  Difficulty: ${q['difficulty']}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: _largeSpacing),
          ...List.generate(4, (index) {
            final option = options[index];
            final label = optionLabels[index] as String;
            final isSelected = _selectedAnswer == option;
            final isCorrect = option == correctAnswer;

            Color? tileColor;
            IconData? trailingIcon;
            if (_answered) {
              if (isCorrect) {
                tileColor = AppColors.correct;
                trailingIcon = LucideIcons.check;
              } else if (isSelected) {
                tileColor = AppColors.incorrect;
                trailingIcon = LucideIcons.x;
              }
            }

            return Card(
              color: tileColor,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _answered
                      ? (isCorrect ? AppColors.add : (isSelected ? AppColors.delete : Colors.grey))
                      : (isSelected ? AppColors.primary : Colors.grey.shade300),
                  child: Text(option, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                title: Text(label),
                trailing: trailingIcon != null ? Icon(trailingIcon, color: isCorrect ? AppColors.add : AppColors.delete) : null,
                onTap: () => _selectAnswer(option),
              ),
            );
          }),
          const SizedBox(height: _largeSpacing),
          if (_answered)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _nextQuestion,
                icon: const Icon(LucideIcons.arrowRight),
                label: Text(_currentIndex < _questions.length - 1 ? 'Next Question' : 'Finish'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
