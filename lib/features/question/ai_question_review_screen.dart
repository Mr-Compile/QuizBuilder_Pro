import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/dialog_helper.dart';
import '../../models/question.dart';
import '../../models/topic.dart';
import '../../models/user.dart';
import '../../services/groq_ai_service.dart';
import '../../services/service_locator.dart';
import '../../widgets/role_guard.dart';

/// Full-screen review page for AI-generated questions with multi-select import.
class AiQuestionReviewScreen extends StatefulWidget {
  final List<Question> generatedQuestions;
  final Topic topic;
  final String difficulty;
  final int quantity;

  const AiQuestionReviewScreen({
    super.key,
    required this.generatedQuestions,
    required this.topic,
    required this.difficulty,
    required this.quantity,
  });

  @override
  State<AiQuestionReviewScreen> createState() => _AiQuestionReviewScreenState();
}

class _AiQuestionReviewScreenState extends State<AiQuestionReviewScreen> {
  final _db = ServiceLocator.db;
  late Future<GroqAiService> _groqFuture;
  late List<Question> _questions;
  late List<bool> _selected;
  bool _isSaving = false;
  bool _isRegenerating = false;
  final Set<int> _regeneratingIndices = {};
  User? _currentUser;

  static const double _smallSpacing = AppTheme.spacing2;
  static const double _mediumSpacing = AppTheme.spacing4;

  @override
  void initState() {
    super.initState();
    _groqFuture = ServiceLocator.groq;
    _questions = List.from(widget.generatedQuestions);
    _selected = List.generate(_questions.length, (_) => true);
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final auth = await ServiceLocator.auth;
    final user = await auth.getCurrentUser();
    if (user != null && mounted) {
      setState(() => _currentUser = user);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRole: AppConstants.roleTeacher,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Review Generated Questions'),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            _buildToolbar(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(_mediumSpacing),
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  final question = _questions[index];
                  return _buildQuestionCard(question, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    final selectedCount = _selected.where((s) => s).length;
    
    return Container(
      padding: const EdgeInsets.all(_mediumSpacing),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Wrap(
        spacing: _smallSpacing,
        runSpacing: _smallSpacing,
        children: [
          TextButton.icon(
            onPressed: _selectAll,
            icon: const Icon(LucideIcons.checkSquare),
            label: const Text('Select All'),
          ),
          TextButton.icon(
            onPressed: _deselectAll,
            icon: const Icon(LucideIcons.square),
            label: const Text('Deselect All'),
          ),
          const SizedBox(width: _smallSpacing),
          Container(
            height: 24,
            width: 1,
            color: Colors.grey.shade300,
          ),
          Text(
            '$selectedCount selected',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          if (_isSaving)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            ElevatedButton.icon(
              onPressed: selectedCount > 0 ? _saveSelected : null,
              icon: const Icon(LucideIcons.save),
              label: const Text('Save Selected'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.add,
                foregroundColor: Colors.white,
              ),
            ),
          const SizedBox(width: _smallSpacing),
          OutlinedButton.icon(
            onPressed: _isRegenerating ? null : _regenerateAll,
            icon: _isRegenerating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.refreshCw),
            label: const Text('Regenerate All'),
          ),
          const SizedBox(width: _smallSpacing),
          OutlinedButton.icon(
            onPressed: _isRegenerating ? null : _regenerateSelected,
            icon: const Icon(LucideIcons.refreshCw, size: 16),
            label: const Text('Regenerate Selected'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Question question, int index) {
    final isRegenerating = _regeneratingIndices.contains(index);
    
    return Card(
      margin: const EdgeInsets.only(bottom: _mediumSpacing),
      child: Padding(
        padding: const EdgeInsets.all(_mediumSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: _selected[index],
                  onChanged: (value) => setState(() => _selected[index] = value ?? false),
                ),
                Expanded(
                  child: Text(
                    'Question ${index + 1}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _smallSpacing,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(question.difficulty).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    question.difficulty,
                    style: TextStyle(
                      color: _getDifficultyColor(question.difficulty),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: _smallSpacing),
                // Action buttons
                IconButton(
                  icon: isRegenerating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(LucideIcons.refreshCw, size: 18),
                  onPressed: isRegenerating ? null : () => _regenerateSingle(index),
                  tooltip: 'Regenerate this question',
                ),
                IconButton(
                  icon: const Icon(LucideIcons.edit3, size: 18),
                  onPressed: () => _editQuestion(index),
                  tooltip: 'Edit this question',
                ),
                IconButton(
                  icon: const Icon(LucideIcons.trash2, size: 18),
                  onPressed: () => _deleteQuestion(index),
                  tooltip: 'Delete this question',
                ),
              ],
            ),
            const SizedBox(height: _smallSpacing),
            Text(
              question.question,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: _mediumSpacing),
            _buildOptions(question),
            const SizedBox(height: _smallSpacing),
            Container(
              padding: const EdgeInsets.all(_smallSpacing),
              decoration: BoxDecoration(
                color: AppColors.add.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.checkCircle,
                    color: AppColors.add,
                    size: 16,
                  ),
                  const SizedBox(width: _smallSpacing),
                  Text(
                    'Correct Answer: ${question.correctAnswer}',
                    style: const TextStyle(
                      color: AppColors.add,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: _smallSpacing),
            Row(
              children: [
                Icon(
                  LucideIcons.bookOpen,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.topic.name,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: _smallSpacing),
                Icon(
                  LucideIcons.tag,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  question.category,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptions(Question question) {
    final options = [
      ('A', question.optionA),
      ('B', question.optionB),
      ('C', question.optionC),
      ('D', question.optionD),
    ];

    return Column(
      children: options.map((option) {
        final isCorrect = option.$1 == question.correctAnswer;
        return Container(
          margin: const EdgeInsets.only(bottom: _smallSpacing),
          padding: const EdgeInsets.all(_smallSpacing),
          decoration: BoxDecoration(
            color: isCorrect 
                ? AppColors.add.withValues(alpha: 0.1)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isCorrect ? AppColors.add : Colors.grey.shade300,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isCorrect ? AppColors.add : Colors.grey.shade400,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    option.$1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: _smallSpacing),
              Expanded(
                child: Text(
                  option.$2,
                  style: TextStyle(
                    fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (isCorrect)
                const Icon(
                  LucideIcons.check,
                  color: AppColors.add,
                  size: 16,
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return AppColors.add;
      case 'medium':
        return AppColors.edit;
      case 'hard':
        return AppColors.delete;
      default:
        return AppColors.primary;
    }
  }

  void _selectAll() {
    setState(() => _selected = List.generate(_selected.length, (_) => true));
  }

  void _deselectAll() {
    setState(() => _selected = List.generate(_selected.length, (_) => false));
  }

  Future<void> _saveSelected() async {
    final toSave = <Question>[];
    for (int i = 0; i < _questions.length; i++) {
      if (_selected[i]) toSave.add(_questions[i]);
    }

    if (toSave.isEmpty) {
      await DialogHelper.showError(
        context,
        'Select at least one generated question to save.',
        title: 'Nothing selected',
      );
      return;
    }

    // Check for duplicates
    final duplicates = await _checkForDuplicates(toSave);
    if (duplicates.isNotEmpty) {
      await _showDuplicateDialog(duplicates, toSave);
      return;
    }

    await _performSave(toSave);
  }

  Future<List<Question>> _checkForDuplicates(List<Question> questions) async {
    final existingQuestions = await _db.getQuestions(topicId: widget.topic.id);
    final duplicates = <Question>[];

    for (final question in questions) {
      final isDuplicate = existingQuestions.any((existing) =>
          existing.question.toLowerCase() == question.question.toLowerCase());
      if (isDuplicate) {
        duplicates.add(question);
      }
    }

    return duplicates;
  }

  Future<void> _showDuplicateDialog(List<Question> duplicates, List<Question> toSave) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(LucideIcons.alertTriangle, color: AppColors.edit),
            SizedBox(width: _smallSpacing),
            Text('Duplicate Questions Found'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${duplicates.length} of ${toSave.length} questions already exist in this topic.',
            ),
            const SizedBox(height: _mediumSpacing),
            const Text(
              'What would you like to do?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'skip'),
            child: const Text('Skip Duplicates'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'unique'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.add,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save Unique Only'),
          ),
        ],
      ),
    );

    if (result == null || result == 'cancel') return;

    if (result == 'skip') {
      final unique = toSave.where((q) => !duplicates.contains(q)).toList();
      if (unique.isEmpty) {
        if (!mounted) return;
        await DialogHelper.showError(
          context,
          'All questions are duplicates. No questions to save.',
          title: 'All Duplicates',
        );
        return;
      }
      await _performSave(unique);
    } else if (result == 'unique') {
      await _performSave(toSave);
    }
  }

  Future<void> _performSave(List<Question> questions) async {
    setState(() => _isSaving = true);

    try {
      final groq = await _groqFuture;
      final user = await (await ServiceLocator.auth).getCurrentUser();
      final createdBy = user?.id ?? 1;
      await groq.saveQuestions(questions, createdBy);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${questions.length} question(s) saved successfully')),
      );
      
      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      await DialogHelper.showError(context, message, title: 'Save failed');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    // Clean up any resources if needed
    super.dispose();
  }

  Future<void> _regenerateAll() async {
    // SECURITY: Get current user for quota enforcement
    if (_currentUser == null) {
      final auth = await ServiceLocator.auth;
      _currentUser = await auth.getCurrentUser();
      if (_currentUser == null) {
        if (!mounted) return;
        await DialogHelper.showError(
          context,
          'You must be logged in to regenerate questions.',
          title: 'Authentication required',
        );
        return;
      }
    }

    setState(() => _isRegenerating = true);

    try {
      final groq = await _groqFuture;
      final questions = await groq.generateQuestions(
        topicId: widget.topic.id!,
        difficulty: widget.difficulty,
        quantity: widget.quantity,
        category: widget.topic.name,
        user: _currentUser!,
      );

      if (!mounted) return;

      setState(() {
        _questions = questions;
        _selected = List.generate(questions.length, (_) => true);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All questions regenerated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      await DialogHelper.showError(context, message, title: 'Regeneration failed');
    } finally {
      setState(() => _isRegenerating = false);
    }
  }

  Future<void> _regenerateSelected() async {
    final selectedIndices = <int>[];
    for (int i = 0; i < _selected.length; i++) {
      if (_selected[i]) selectedIndices.add(i);
    }

    if (selectedIndices.isEmpty) {
      await DialogHelper.showError(
        context,
        'Please select at least one question to regenerate.',
        title: 'No selection',
      );
      return;
    }

    setState(() => _isRegenerating = true);

    try {
      final groq = await _groqFuture;
      final selectedQuestions = selectedIndices.map((i) => _questions[i]).toList();
      
      final regenerated = await groq.regenerateSelectedQuestions(
        questions: selectedQuestions,
        topicName: widget.topic.name,
      );

      if (!mounted) return;

      setState(() {
        for (int i = 0; i < selectedIndices.length; i++) {
          _questions[selectedIndices[i]] = regenerated[i];
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${selectedIndices.length} question(s) regenerated')),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      await DialogHelper.showError(context, message, title: 'Regeneration failed');
    } finally {
      setState(() => _isRegenerating = false);
    }
  }

  Future<void> _regenerateSingle(int index) async {
    setState(() => _regeneratingIndices.add(index));

    try {
      final groq = await _groqFuture;
      final newQuestion = await groq.regenerateSingleQuestion(
        originalQuestion: _questions[index],
        topicName: widget.topic.name,
      );

      if (!mounted) return;

      setState(() {
        _questions[index] = newQuestion;
        _regeneratingIndices.remove(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Question regenerated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _regeneratingIndices.remove(index));
      final message = e.toString().replaceFirst('Exception: ', '');
      await DialogHelper.showError(context, message, title: 'Regeneration failed');
    }
  }

  Future<void> _editQuestion(int index) async {
    final question = _questions[index];
    final questionController = TextEditingController(text: question.question);
    final optionAController = TextEditingController(text: question.optionA);
    final optionBController = TextEditingController(text: question.optionB);
    final optionCController = TextEditingController(text: question.optionC);
    final optionDController = TextEditingController(text: question.optionD);
    String correctAnswer = question.correctAnswer;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Edit Question ${index + 1}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: questionController,
                  decoration: const InputDecoration(
                    labelText: 'Question',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: _smallSpacing),
                TextField(
                  controller: optionAController,
                  decoration: const InputDecoration(
                    labelText: 'Option A',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: _smallSpacing),
                TextField(
                  controller: optionBController,
                  decoration: const InputDecoration(
                    labelText: 'Option B',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: _smallSpacing),
                TextField(
                  controller: optionCController,
                  decoration: const InputDecoration(
                    labelText: 'Option C',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: _smallSpacing),
                TextField(
                  controller: optionDController,
                  decoration: const InputDecoration(
                    labelText: 'Option D',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: _mediumSpacing),
                const Text('Correct Answer:'),
                const SizedBox(height: _smallSpacing),
                Row(
                  children: ['A', 'B', 'C', 'D'].map((letter) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ignore: deprecated_member_use
                        Radio<String>(
                          value: letter,
                          // ignore: deprecated_member_use
                          groupValue: correctAnswer,
                          // ignore: deprecated_member_use
                          onChanged: (value) => setDialogState(() => correctAnswer = value!),
                        ),
                        Text(letter),
                        const SizedBox(width: _mediumSpacing),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {
        _questions[index] = Question(
          id: question.id,
          topicId: question.topicId,
          question: questionController.text.trim(),
          optionA: optionAController.text.trim(),
          optionB: optionBController.text.trim(),
          optionC: optionCController.text.trim(),
          optionD: optionDController.text.trim(),
          correctAnswer: correctAnswer,
          difficulty: question.difficulty,
          category: question.category,
          source: question.source,
          createdBy: question.createdBy,
          createdAt: question.createdAt,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Question updated successfully')),
      );
    }

    questionController.dispose();
    optionAController.dispose();
    optionBController.dispose();
    optionCController.dispose();
    optionDController.dispose();
  }

  Future<void> _deleteQuestion(int index) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(LucideIcons.trash2, color: AppColors.delete),
            SizedBox(width: _smallSpacing),
            Text('Delete Question'),
          ],
        ),
        content: Text('Are you sure you want to delete question ${index + 1}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.delete,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      setState(() {
        _questions.removeAt(index);
        _selected.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Question deleted')),
      );
    }
  }
}
