import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/validation/validators.dart';
import '../../models/question.dart';
import '../../models/topic.dart';
import '../../services/service_locator.dart';
import '../../widgets/role_guard.dart';
import '../../widgets/navigation_scaffold.dart';
import '../../core/routes/app_routes.dart';

/// Create or edit a multiple-choice question manually.
class QuestionFormScreen extends StatefulWidget {
  final Question? question;

  const QuestionFormScreen({super.key, this.question});

  @override
  State<QuestionFormScreen> createState() => _QuestionFormScreenState();
}

class _QuestionFormScreenState extends State<QuestionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _optionAController = TextEditingController();
  final _optionBController = TextEditingController();
  final _optionCController = TextEditingController();
  final _optionDController = TextEditingController();
  final _categoryController = TextEditingController();
  final _db = ServiceLocator.db;

  Topic? _selectedTopic;
  String? _selectedDifficulty;
  String? _correctAnswer;
  List<Topic> _topics = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadTopics();
    if (widget.question != null) {
      _questionController.text = widget.question!.question;
      _optionAController.text = widget.question!.optionA;
      _optionBController.text = widget.question!.optionB;
      _optionCController.text = widget.question!.optionC;
      _optionDController.text = widget.question!.optionD;
      _correctAnswer = widget.question!.correctAnswer;
      _selectedDifficulty = widget.question!.difficulty;
      _categoryController.text = widget.question!.category;
    } else {
      _correctAnswer = 'A';
      _selectedDifficulty = AppConstants.difficultyEasy;
      _categoryController.text = 'General';
    }
  }

  Future<void> _loadTopics() async {
    final topics = await _db.getAllTopics();
    setState(() {
      _topics = topics;
      if (widget.question != null) {
        _selectedTopic = topics.where((t) => t.id == widget.question!.topicId).firstOrNull;
      } else if (topics.isNotEmpty) {
        _selectedTopic = topics.first;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Custom validation for topic selection
    if (_selectedTopic == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a topic.'), backgroundColor: Colors.red),
      );
      return;
    }

    // Validate that all options are unique
    final options = [
      _optionAController.text.trim(),
      _optionBController.text.trim(),
      _optionCController.text.trim(),
      _optionDController.text.trim(),
    ];
    if (options.toSet().length != options.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All options must be unique.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = await (await ServiceLocator.auth).getCurrentUser();
      final now = DateTime.now().toIso8601String();

      final question = Question(
        id: widget.question?.id,
        topicId: _selectedTopic!.id!,
        question: _questionController.text.trim(),
        optionA: _optionAController.text.trim(),
        optionB: _optionBController.text.trim(),
        optionC: _optionCController.text.trim(),
        optionD: _optionDController.text.trim(),
        correctAnswer: _correctAnswer!,
        difficulty: _selectedDifficulty!,
        category: _categoryController.text.trim(),
        source: AppConstants.sourceManual,
        createdBy: user?.id,
        createdAt: now,
      );

      if (widget.question == null) {
        await _db.insertQuestion(question);
      } else {
        await _db.updateQuestion(question);
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save question: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.question != null;

    return RoleGuard(
      allowedRole: AppConstants.roleTeacher,
      child: NavigationScaffold(
        title: isEdit ? 'Edit Question' : 'Add Question',
        currentRoute: AppRoutes.questionForm,
        showDrawer: false,
        body: _topics.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.only(
                left: AppTheme.mediumSpacing,
                right: AppTheme.mediumSpacing,
                top: AppTheme.mediumSpacing,
                bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.mediumSpacing,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    DropdownButtonFormField<Topic?>(
                      initialValue: _selectedTopic,
                      decoration: const InputDecoration(labelText: 'Topic'),
                      items: _topics
                          .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedTopic = value),
                      validator: (value) => value == null ? 'Select a topic' : null,
                    ),
                    const SizedBox(height: AppTheme.mediumSpacing),
                    TextFormField(
                      controller: _questionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Question',
                        prefixIcon: Icon(LucideIcons.helpCircle),
                        alignLabelWithHint: true,
                      ),
                      validator: Validators.compose([
                        (value) => Validators.required(value),
                        (value) => Validators.minLength(value, 10, fieldName: 'Question'),
                        (value) => Validators.maxLength(value, 500, fieldName: 'Question'),
                      ]),
                    ),
                    const SizedBox(height: AppTheme.mediumSpacing),
                    TextFormField(
                      controller: _optionAController,
                      decoration: const InputDecoration(labelText: 'Option A'),
                      validator: Validators.required,
                    ),
                    const SizedBox(height: AppTheme.smallSpacing),
                    TextFormField(
                      controller: _optionBController,
                      decoration: const InputDecoration(labelText: 'Option B'),
                      validator: Validators.required,
                    ),
                    const SizedBox(height: AppTheme.smallSpacing),
                    TextFormField(
                      controller: _optionCController,
                      decoration: const InputDecoration(labelText: 'Option C'),
                      validator: Validators.required,
                    ),
                    const SizedBox(height: AppTheme.smallSpacing),
                    TextFormField(
                      controller: _optionDController,
                      decoration: const InputDecoration(labelText: 'Option D'),
                      validator: Validators.required,
                    ),
                    const SizedBox(height: AppTheme.mediumSpacing),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isSmallScreen = constraints.maxWidth < 360;
                        if (isSmallScreen) {
                          return Column(
                            children: [
                              DropdownButtonFormField<String?>(
                                initialValue: _correctAnswer,
                                decoration: const InputDecoration(labelText: 'Correct Answer'),
                                items: const [
                                  DropdownMenuItem(value: 'A', child: Text('A')),
                                  DropdownMenuItem(value: 'B', child: Text('B')),
                                  DropdownMenuItem(value: 'C', child: Text('C')),
                                  DropdownMenuItem(value: 'D', child: Text('D')),
                                ],
                                onChanged: (value) => setState(() => _correctAnswer = value),
                              ),
                              const SizedBox(height: AppTheme.smallSpacing),
                              DropdownButtonFormField<String?>(
                                initialValue: _selectedDifficulty,
                                decoration: const InputDecoration(labelText: 'Difficulty'),
                                items: const [
                                  DropdownMenuItem(value: AppConstants.difficultyEasy, child: Text('Easy')),
                                  DropdownMenuItem(value: AppConstants.difficultyMedium, child: Text('Medium')),
                                  DropdownMenuItem(value: AppConstants.difficultyHard, child: Text('Hard')),
                                ],
                                onChanged: (value) => setState(() => _selectedDifficulty = value),
                              ),
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String?>(
                                initialValue: _correctAnswer,
                                decoration: const InputDecoration(labelText: 'Correct Answer'),
                                items: const [
                                  DropdownMenuItem(value: 'A', child: Text('A')),
                                  DropdownMenuItem(value: 'B', child: Text('B')),
                                  DropdownMenuItem(value: 'C', child: Text('C')),
                                  DropdownMenuItem(value: 'D', child: Text('D')),
                                ],
                                onChanged: (value) => setState(() => _correctAnswer = value),
                              ),
                            ),
                            const SizedBox(width: AppTheme.smallSpacing),
                            Expanded(
                              child: DropdownButtonFormField<String?>(
                                initialValue: _selectedDifficulty,
                                decoration: const InputDecoration(labelText: 'Difficulty'),
                                items: const [
                                  DropdownMenuItem(value: AppConstants.difficultyEasy, child: Text('Easy')),
                                  DropdownMenuItem(value: AppConstants.difficultyMedium, child: Text('Medium')),
                                  DropdownMenuItem(value: AppConstants.difficultyHard, child: Text('Hard')),
                                ],
                                onChanged: (value) => setState(() => _selectedDifficulty = value),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: AppTheme.mediumSpacing),
                    TextFormField(
                      controller: _categoryController,
                      decoration: const InputDecoration(labelText: 'Category'),
                      validator: Validators.compose([
                        (value) => Validators.required(value),
                        (value) => Validators.maxLength(value, 50, fieldName: 'Category'),
                      ]),
                    ),
                    const SizedBox(height: AppTheme.largeSpacing),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(LucideIcons.x),
                            label: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: AppTheme.mediumSpacing),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isSubmitting ? null : _save,
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(LucideIcons.save),
                            label: const Text('Save'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.add,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    ),
    );
  }

  @override
  void dispose() {
    _questionController.dispose();
    _optionAController.dispose();
    _optionBController.dispose();
    _optionCController.dispose();
    _optionDController.dispose();
    _categoryController.dispose();
    super.dispose();
  }
}
