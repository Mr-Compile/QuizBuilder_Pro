import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/dialog_helper.dart';
import '../../models/question.dart';
import '../../models/topic.dart';
import '../../services/groq_ai_service.dart';
import '../../services/service_locator.dart';
import '../../widgets/role_guard.dart';
import '../../widgets/enhanced_navigation.dart';

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

  static const double _smallSpacing = AppTheme.spacing2;
  static const double _mediumSpacing = AppTheme.spacing4;

  @override
  void initState() {
    super.initState();
    _groqFuture = ServiceLocator.groq;
    _topicsFuture = _loadTopics();
    _selectedDifficulty = AppConstants.difficultyEasy;
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final groq = await _groqFuture;
    final key = await groq.getApiKey();
    if (key != null && _apiKeyController.text.isEmpty) {
      setState(() => _apiKeyController.text = key);
    }
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
      const SnackBar(content: Text('API key saved securely')),
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

    final groq = await _groqFuture;
    final valid = await groq.hasValidApiKey();
    if (!mounted) return;
    if (!valid) {
      await DialogHelper.showError(
        context,
        'A valid Groq API key starting with "gsk_" is required. Add it in the field above or in Settings.',
        title: 'Invalid API key',
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
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
      if (message.contains('internet') || message.contains('network')) {
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
        appBar: AppBar(
          title: const Text('AI Question Generation'),
          elevation: 0,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(LucideIcons.brain),
              onPressed: () => Scaffold.of(context).openDrawer(),
              tooltip: 'Open menu',
            ),
          ),
        ),
        drawer: EnhancedDrawer(
          currentRoute: AppRoutes.aiGenerate,
          onLogout: _logout,
        ),
        body: FutureBuilder(
          future: _topicsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(_mediumSpacing),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildApiKeyCard(context),
                  const SizedBox(height: _mediumSpacing),
                  _buildGeneratorCard(context),
                  const SizedBox(height: _mediumSpacing),
                  _buildResultsSection(context),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildApiKeyCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(_mediumSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Groq API Key', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: _smallSpacing),
            TextField(
              controller: _apiKeyController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'API Key',
                hintText: 'Enter your Groq API key starting with gsk_',
                prefixIcon: const Icon(LucideIcons.key),
                suffixIcon: IconButton(
                  icon: const Icon(LucideIcons.save, color: AppColors.add),
                  onPressed: _saveApiKey,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
            ),
            const SizedBox(height: _smallSpacing),
            Text(
              'Stored securely using platform encryption. Only teachers can view or change this key.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneratorCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(_mediumSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Generate Questions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: _mediumSpacing),
            DropdownButtonFormField<Topic?>(
              initialValue: _selectedTopic,
              decoration: const InputDecoration(
                labelText: 'Topic',
                filled: true,
              ),
              items: _topics.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
              onChanged: (value) => setState(() => _selectedTopic = value),
            ),
            const SizedBox(height: _mediumSpacing),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: _selectedDifficulty,
                    decoration: const InputDecoration(
                      labelText: 'Difficulty',
                      filled: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: AppConstants.difficultyEasy, child: Text('Easy')),
                      DropdownMenuItem(value: AppConstants.difficultyMedium, child: Text('Medium')),
                      DropdownMenuItem(value: AppConstants.difficultyHard, child: Text('Hard')),
                    ],
                    onChanged: (value) => setState(() => _selectedDifficulty = value),
                  ),
                ),
                const SizedBox(width: _smallSpacing),
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      hintText: '1-20',
                      filled: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: _mediumSpacing),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Category',
                filled: true,
              ),
            ),
            const SizedBox(height: _mediumSpacing),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generate,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(LucideIcons.wand2),
                label: Text(_isGenerating ? 'Generating...' : 'Generate Questions'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.startQuiz,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection(BuildContext context) {
    if (_generated.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Generated Questions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () => setState(() {
                final allSelected = _selected.every((s) => s);
                _selected = List.generate(_selected.length, (_) => !allSelected);
              }),
              icon: const Icon(LucideIcons.checkSquare),
              label: const Text('Toggle all'),
            ),
          ],
        ),
        const SizedBox(height: _smallSpacing),
        ...List.generate(_generated.length, (index) {
          final q = _generated[index];
          return Card(
            child: CheckboxListTile(
              value: _selected[index],
              onChanged: (value) => setState(() => _selected[index] = value ?? false),
              title: Text(q.question, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text('Correct: ${q.correctAnswer}  |  Category: ${q.category}'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          );
        }),
        const SizedBox(height: _mediumSpacing),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveSelected,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(LucideIcons.save),
            label: Text(_isSaving ? 'Saving...' : 'Save Selected'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.add,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _logout() async {
    final auth = await ServiceLocator.auth;
    await auth.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _quantityController.dispose();
    _categoryController.dispose();
    super.dispose();
  }
}
