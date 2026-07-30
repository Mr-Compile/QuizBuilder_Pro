import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/dialog_helper.dart';
import '../../database/database_helper.dart';
import '../../models/question.dart';
import '../../models/topic.dart';
import '../../services/groq_ai_service.dart';
import '../../services/service_locator.dart';
import '../../widgets/role_guard.dart';

/// Generate quiz questions with the Groq AI API and save selected ones.
class AiGenerateScreen extends StatefulWidget {
  const AiGenerateScreen({super.key});

  @override
  State<AiGenerateScreen> createState() => _AiGenerateScreenState();
}

class _AiGenerateScreenState extends State<AiGenerateScreen> {
  final _db = ServiceLocator.db;
  final _apiKeyController = TextEditingController();
  final _quantityController = TextEditingController(text: '5');
  final _categoryController = TextEditingController(text: 'General');
  late Future<GroqAiService> _groqFuture;
  late Future<List<Topic>> _topicsFuture;

  List<Topic> _topics = [];
  Topic? _selectedTopic;
  String? _selectedDifficulty;
  List<Question> _generated = [];
  List<bool> _selected = [];
  bool _isGenerating = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _groqFuture = ServiceLocator.groq;
    _topicsFuture = _loadTopics();
    _selectedDifficulty = AppConstants.difficultyEasy;
  }

  Future<List<Topic>> _loadTopics() async {
    final topics = await _db.getAllTopics();
    setState(() {
      _topics = topics;
      if (topics.isNotEmpty) _selectedTopic = topics.first;
    });
    return topics;
  }

  Future<void> _saveApiKey() async {
    final groq = await _groqFuture;
    await groq.saveApiKey(_apiKeyController.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('API key saved')),
    );
  }

  Future<void> _generate() async {
    if (_selectedTopic == null) {
      await DialogHelper.showError(
        context,
        'Please select a topic before generating questions.',
        title: 'Missing topic',
      );
      return;
    }

    final quantity = int.tryParse(_quantityController.text.trim()) ?? 0;
    if (quantity <= 0 || quantity > 20) {
      await DialogHelper.showError(
        context,
        'Enter a quantity between 1 and 20.',
        title: 'Invalid quantity',
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final groq = await _groqFuture;
      final questions = await groq.generateQuestions(
        topicId: _selectedTopic!.id!,
        difficulty: _selectedDifficulty!,
        quantity: quantity,
        category: _categoryController.text.trim(),
      );

      setState(() {
        _generated = questions;
        _selected = List.generate(questions.length, (_) => true);
      });
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      if (message.contains('No internet')) {
        await DialogHelper.showNoInternet(context, onRetry: _generate);
      } else {
        await DialogHelper.showError(context, message, onRetry: _generate);
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _saveSelected() async {
    if (_selectedTopic == null) return;

    final toSave = <Question>[];
    for (int i = 0; i < _generated.length; i++) {
      if (_selected[i]) toSave.add(_generated[i]);
    }

    if (toSave.isEmpty) {
      await DialogHelper.showError(
        context,
        'Select at least one generated question to save.',
        title: 'Nothing selected',
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final groq = await _groqFuture;
      final user = await (await ServiceLocator.auth).getCurrentUser();
      final createdBy = user?.id ?? 1;
      await groq.saveQuestions(toSave, createdBy);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${toSave.length} question(s) saved')),
      );
      setState(() {
        _generated = [];
        _selected = [];
      });
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      await DialogHelper.showError(context, message, title: 'Save failed');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRole: AppConstants.roleTeacher,
      child: Scaffold(
        appBar: AppBar(title: const Text('AI Question Generation')),
        body: FutureBuilder(
          future: _topicsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.mediumSpacing),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.cardPadding),
                      child: Column(
                        children: [
                          FutureBuilder(
                            future: _groqFuture,
                            builder: (context, groqSnapshot) {
                              final key = groqSnapshot.hasData
                                  ? groqSnapshot.data!.getApiKey()
                                  : null;
                              if (key != null && _apiKeyController.text.isEmpty) {
                                _apiKeyController.text = key;
                              }
                              return TextField(
                                controller: _apiKeyController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: 'Groq API Key',
                                  prefixIcon: const Icon(LucideIcons.key),
                                  suffixIcon: IconButton(
                                    icon: const Icon(LucideIcons.save, color: AppColors.add),
                                    onPressed: _saveApiKey,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: AppTheme.mediumSpacing),
                          DropdownButtonFormField<Topic?>(
                            value: _selectedTopic,
                            decoration: const InputDecoration(labelText: 'Topic'),
                            items: _topics
                                .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                                .toList(),
                            onChanged: (value) => setState(() => _selectedTopic = value),
                          ),
                          const SizedBox(height: AppTheme.mediumSpacing),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String?>(
                                  value: _selectedDifficulty,
                                  decoration: const InputDecoration(labelText: 'Difficulty'),
                                  items: const [
                                    DropdownMenuItem(value: AppConstants.difficultyEasy, child: Text('Easy')),
                                    DropdownMenuItem(value: AppConstants.difficultyMedium, child: Text('Medium')),
                                    DropdownMenuItem(value: AppConstants.difficultyHard, child: Text('Hard')),
                                  ],
                                  onChanged: (value) => setState(() => _selectedDifficulty = value),
                                ),
                              ),
                              const SizedBox(width: AppTheme.smallSpacing),
                              Expanded(
                                child: TextField(
                                  controller: _quantityController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Quantity',
                                    prefixIcon: Icon(LucideIcons.hash),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.mediumSpacing),
                          TextField(
                            controller: _categoryController,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              prefixIcon: Icon(LucideIcons.tag),
                            ),
                          ),
                          const SizedBox(height: AppTheme.largeSpacing),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isGenerating ? null : _generate,
                              icon: _isGenerating
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(LucideIcons.wand),
                              label: const Text('Generate Questions'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.startQuiz,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.largeSpacing),
                  if (_generated.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Generated Questions', style: Theme.of(context).textTheme.titleLarge),
                        TextButton.icon(
                          onPressed: _isSaving ? null : _saveSelected,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(LucideIcons.save),
                          label: const Text('Save Selected'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.smallSpacing),
                    ...List.generate(_generated.length, (index) {
                      final q = _generated[index];
                      return Card(
                        child: CheckboxListTile(
                          value: _selected[index],
                          onChanged: (value) => setState(() => _selected[index] = value ?? false),
                          title: Text(q.question, maxLines: 3, overflow: TextOverflow.ellipsis),
                          subtitle: Text('A: ${q.optionA}  B: ${q.optionB}\nCorrect: ${q.correctAnswer}'),
                          isThreeLine: true,
                        ),
                      );
                    }),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _quantityController.dispose();
    _categoryController.dispose();
    super.dispose();
  }
}
