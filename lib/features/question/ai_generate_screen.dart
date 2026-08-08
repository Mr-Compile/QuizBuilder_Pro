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
import '../../widgets/navigation_scaffold.dart';
import '../../widgets/smart_topic_dropdown.dart';
import 'ai_question_review_screen.dart';

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
  bool _showAdvancedOptions = false;
  String _loadingMessage = '';

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
    final maskedKey = await groq.getMaskedApiKey();
    if (maskedKey != null && _apiKeyController.text.isEmpty) {
      setState(() => _apiKeyController.text = maskedKey);
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

  void _showApiKeyDialog(BuildContext context) {
    final controller = TextEditingController(text: _apiKeyController.text);
    bool obscureText = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Groq API Key'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                obscureText: obscureText,
                decoration: InputDecoration(
                  labelText: 'API Key',
                  hintText: 'Enter your Groq API key starting with gsk_',
                  prefixIcon: const Icon(LucideIcons.key),
                  suffixIcon: IconButton(
                    icon: Icon(obscureText ? LucideIcons.eye : LucideIcons.eyeOff),
                    onPressed: () => setDialogState(() => obscureText = !obscureText),
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
          actions: [
            TextButton(
              onPressed: () async {
                final groq = await _groqFuture;
                await groq.clearApiKey();
                if (!mounted) return;
                setState(() => _apiKeyController.clear());
                if (!context.mounted) return;
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.delete,
              ),
              child: const Text('Clear'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.edit,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
              onPressed: () async {
                _apiKeyController.text = controller.text.trim();
                await _saveApiKey();
                if (!mounted) return;
                // Clear the controller to avoid displaying the key
                _apiKeyController.clear();
                _loadApiKey(); // Reload masked version
                if (!context.mounted) return;
                if (!context.mounted) return;
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
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
        'A valid Groq API key starting with "gsk_" is required. Add it using the key icon in the toolbar.',
        title: 'Invalid API key',
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _loadingMessage = 'Connecting to Groq AI...';
    });

    try {
      setState(() => _loadingMessage = 'Generating questions...');
      
      final questions = await groq.generateQuestions(
        topicId: _selectedTopic!.id!,
        difficulty: _selectedDifficulty!,
        quantity: quantity,
        category: _categoryController.text.trim(),
      );

      setState(() {
        _loadingMessage = 'Parsing response...';
        _generated = questions;
        _selected = List.generate(questions.length, (_) => true);
      });

      // Navigate to review screen
      if (!mounted) return;
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AiQuestionReviewScreen(
            generatedQuestions: questions,
            topic: _selectedTopic!,
            difficulty: _selectedDifficulty!,
            quantity: quantity,
          ),
        ),
      );

      // Clear generated questions if save was successful
      if (result == true && mounted) {
        setState(() {
          _generated.clear();
          _selected.clear();
        });
      }
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      if (message.contains('internet') || message.contains('network')) {
        await DialogHelper.showNoInternet(context, onRetry: _generate);
      } else {
        await DialogHelper.showError(context, message, onRetry: _generate);
      }
    } finally {
      setState(() {
        _isGenerating = false;
        _loadingMessage = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRole: AppConstants.roleTeacher,
      child: NavigationScaffold(
        title: 'AI Question Generation',
        currentRoute: AppRoutes.aiGenerate,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.key),
            onPressed: () => _showApiKeyDialog(context),
            tooltip: 'Manage API Key',
          ),
        ],
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
                  _buildGeneratorCard(context),
                  const SizedBox(height: _mediumSpacing),
                  _buildAdvancedOptions(context),
                ],
              ),
            );
          },
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
            Text(
              'Generate Questions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: _mediumSpacing),
            SmartTopicDropdown(
              selectedTopic: _selectedTopic?.name,
              existingTopics: _topics.map((t) => t.name).toList(),
              onTopicSelected: (topicName) {
                final topic = _topics.firstWhere(
                  (t) => t.name == topicName,
                  orElse: () => _topics.first,
                );
                setState(() => _selectedTopic = topic);
              },
              labelText: 'Topic',
              hintText: 'Select a topic',
            ),
            const SizedBox(height: _mediumSpacing),
            DropdownButtonFormField<String>(
              initialValue: _selectedDifficulty,
              decoration: const InputDecoration(
                labelText: 'Difficulty',
                filled: true,
                prefixIcon: Icon(LucideIcons.layers),
              ),
              items: const [
                DropdownMenuItem(value: AppConstants.difficultyEasy, child: Text('Easy')),
                DropdownMenuItem(value: AppConstants.difficultyMedium, child: Text('Medium')),
                DropdownMenuItem(value: AppConstants.difficultyHard, child: Text('Hard')),
              ],
              onChanged: (value) => setState(() => _selectedDifficulty = value),
            ),
            const SizedBox(height: _mediumSpacing),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantity (1-20)',
                      filled: true,
                      prefixIcon: Icon(LucideIcons.hash),
                    ),
                  ),
                ),
                const SizedBox(width: _mediumSpacing),
                Expanded(
                  child: TextField(
                    controller: _categoryController,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      filled: true,
                      prefixIcon: Icon(LucideIcons.tag),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: _mediumSpacing),
            if (_isGenerating)
              Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: _smallSpacing),
                  Text(_loadingMessage),
                ],
              )
            else
              ElevatedButton.icon(
                onPressed: _generate,
                icon: const Icon(LucideIcons.wand2),
                label: const Text('Generate Questions'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.startQuiz,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedOptions(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(_mediumSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => _showAdvancedOptions = !_showAdvancedOptions),
              child: Row(
                children: [
                  Icon(
                    _showAdvancedOptions ? LucideIcons.chevronDown : LucideIcons.chevronRight,
                  ),
                  const SizedBox(width: _smallSpacing),
                  Text(
                    'Advanced Options',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (_showAdvancedOptions) ...[
              const SizedBox(height: _mediumSpacing),
              Text(
                'Additional AI generation options will be added here.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
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
