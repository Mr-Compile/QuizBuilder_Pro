import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/responsive_utils.dart';
import '../../models/question.dart';
import '../../models/quiz_answer.dart';
import '../../models/quiz_result.dart';
import '../../models/topic.dart';
import '../../models/user.dart';
import '../../services/service_locator.dart';
import '../../widgets/role_guard.dart';
import '../../widgets/responsive_widgets.dart';

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
    _startQuizSession();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _endQuizSessionSync();
    super.dispose();
  }

  Future<void> _startQuizSession() async {
    final quizSession = await ServiceLocator.quizSession;
    await quizSession.startQuiz();
  }

  Future<void> _endQuizSession() async {
    final quizSession = await ServiceLocator.quizSession;
    await quizSession.endQuiz();
  }

  void _endQuizSessionSync() {
    // Synchronous version for dispose
    ServiceLocator.quizSession.then((quizSession) {
      quizSession.endQuiz();
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _remainingSeconds = _questions.length * _timePerQuestion;
    // Ensure timer starts with proper state update
    setState(() {
      _remainingSeconds = _questions.length * _timePerQuestion;
    });
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

  void _selectAnswer(int? questionId, String answer) {
    if (questionId != null) {
      setState(() {
        _answers[questionId] = answer.trim().toUpperCase();
      });
    }
  }

  void _loadQuestions() {
    _questionsFuture = _db.getQuestions(
      topicId: widget.topic.id,
      difficulty: widget.difficulty,
    ).then((questions) {
      final copy = List<Question>.of(questions);
      copy.shuffle(Random());
      // Reset index to ensure we start at question 1
      _currentIndex = 0;
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
    await _endQuizSession();

    final correctCount = _questions.where((q) {
      final userAnswer = _answers[q.id]?.trim().toUpperCase() ?? '';
      final correctAnswer = q.correctAnswer.trim().toUpperCase();
      return userAnswer == correctAnswer;
    }).length;
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
      final userAnswer = _answers[q.id]?.trim().toUpperCase() ?? '';
      final correctAnswer = q.correctAnswer.trim().toUpperCase();
      final isCorrect = userAnswer == correctAnswer;
      return QuizAnswer(
        resultId: resultId,
        questionId: q.id!,
        userAnswer: userAnswer,
        correctAnswer: correctAnswer,
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

  void _onPopInvokedWithResult(bool didPop, dynamic result) {
    if (!didPop) {
      // Show dialog when trying to exit during quiz
      _showExitDialog();
    }
  }

  void _showExitDialog() {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Quiz in Progress'),
        content: const Text('You must finish the quiz before leaving this screen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continue Quiz'),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileQuestionCard(Question question) {
    return SingleChildScrollView(
      child: ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.question,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: context.responsiveSpacing * 2),
            _OptionTile(
              label: 'A',
              text: question.optionA,
              selected: _answers[question.id] == 'A',
              onTap: () => _selectAnswer(question.id, 'A'),
            ),
            _OptionTile(
              label: 'B',
              text: question.optionB,
              selected: _answers[question.id] == 'B',
              onTap: () => _selectAnswer(question.id, 'B'),
            ),
            _OptionTile(
              label: 'C',
              text: question.optionC,
              selected: _answers[question.id] == 'C',
              onTap: () => _selectAnswer(question.id, 'C'),
            ),
            _OptionTile(
              label: 'D',
              text: question.optionD,
              selected: _answers[question.id] == 'D',
              onTap: () => _selectAnswer(question.id, 'D'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletQuestionCard(Question question) {
    return SingleChildScrollView(
      child: ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.question,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: context.isTablet ? 20 : 22,
                  ),
            ),
            SizedBox(height: context.responsiveSpacing * 2),
            ResponsiveGrid(
              mobileColumns: 1,
              tabletColumns: 2,
              desktopColumns: 2,
              childAspectRatio: context.isLandscape ? 3.0 : 2.5,
              children: [
                _OptionTile(
                  label: 'A',
                  text: question.optionA,
                  selected: _answers[question.id] == 'A',
                  onTap: () => _selectAnswer(question.id, 'A'),
                ),
                _OptionTile(
                  label: 'B',
                  text: question.optionB,
                  selected: _answers[question.id] == 'B',
                  onTap: () => _selectAnswer(question.id, 'B'),
                ),
                _OptionTile(
                  label: 'C',
                  text: question.optionC,
                  selected: _answers[question.id] == 'C',
                  onTap: () => _selectAnswer(question.id, 'C'),
                ),
                _OptionTile(
                  label: 'D',
                  text: question.optionD,
                  selected: _answers[question.id] == 'D',
                  onTap: () => _selectAnswer(question.id, 'D'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopQuestionCard(Question question) {
    return _buildTabletQuestionCard(question);
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRole: AppConstants.roleStudent,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: _onPopInvokedWithResult,
        child: Scaffold(
          appBar: AppBar(
            title: Text('${widget.topic.name} — ${widget.difficulty}'),
            automaticallyImplyLeading: false,
          actions: [
            Padding(
              padding: EdgeInsets.only(right: context.responsiveSpacing / 2),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.isMobile ? 8 : 12,
                  vertical: context.isMobile ? 4 : 6,
                ),
                decoration: BoxDecoration(
                  color: _remainingSeconds < 60 ? AppColors.delete.withValues(alpha: 0.2) : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(context.responsiveBorderRadius),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.clock,
                      size: context.isMobile ? 16 : 20,
                      color: _remainingSeconds < 60 ? AppColors.delete : AppColors.primary,
                    ),
                    SizedBox(width: context.isMobile ? 4 : 8),
                    Text(
                      _formatTime(_remainingSeconds),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: context.isMobile ? 13 : 15,
                        color: _remainingSeconds < 60 ? AppColors.delete : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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

            return ResponsiveContainer(
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: context.isMobile ? 8 : 10,
                  ),
                  SizedBox(height: context.responsiveSpacing),
                  Text(
                    'Question ${_currentIndex + 1} of ${_questions.length}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: context.isMobile ? 16 : 18,
                        ),
                  ),
                  SizedBox(height: context.responsiveSpacing),
                  Expanded(
                    child: ResponsiveBuilder(
                      mobile: _buildMobileQuestionCard(question),
                      tablet: _buildTabletQuestionCard(question),
                      desktop: _buildDesktopQuestionCard(question),
                    ),
                  ),
                  SizedBox(height: context.responsiveSpacing),
                  SizedBox(
                    width: double.infinity,
                    height: context.isMobile ? 50 : 56,
                    child: ElevatedButton.icon(
                      onPressed: _answers.containsKey(_questions[_currentIndex].id) ? _submit : null,
                      icon: Icon(
                        _currentIndex == _questions.length - 1 ? LucideIcons.check : LucideIcons.arrowRight,
                        size: context.isMobile ? 20 : 24,
                      ),
                      label: Text(
                        _currentIndex == _questions.length - 1 ? 'Finish Quiz' : 'Next',
                        style: TextStyle(fontSize: context.isMobile ? 16 : 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _currentIndex == _questions.length - 1 ? AppColors.finishQuiz : AppColors.startQuiz,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: context.responsiveSpacing,
                          vertical: context.isMobile ? 12 : 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(context.responsiveBorderRadius),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
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
    final isInGrid = context.isTablet || context.isDesktop;
    
    return Card(
      color: selected ? Theme.of(context).colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.responsiveBorderRadius),
        child: Padding(
          padding: EdgeInsets.all(
            isInGrid ? context.responsiveCardPadding : 0,
          ),
          child: isInGrid
              ? _buildGridLayout(context, color, selected)
              : ListTile(
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
                ),
        ),
      ),
    );
  }

  Widget _buildGridLayout(BuildContext context, Color color, bool selected) {
    return Row(
      children: [
        CircleAvatar(
          radius: context.isTablet ? 20 : 24,
          backgroundColor: selected ? Theme.of(context).colorScheme.primary : Colors.transparent,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : color,
              fontWeight: FontWeight.bold,
              fontSize: context.isTablet ? 16 : 18,
            ),
          ),
        ),
        SizedBox(width: context.responsiveSpacing),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: context.isTablet ? 14 : 16,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
