import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/dialog_helper.dart';
import '../../models/question.dart';
import '../../models/topic.dart';
import '../../models/user.dart';
import '../../services/groq_ai_service.dart';
import '../../services/service_locator.dart';
import '../../widgets/quota_indicator.dart';
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
  final _customTopicController = TextEditingController();
  late Future<GroqAiService> _groqFuture;
  late Future<List<Topic>> _topicsFuture;

  List<Topic> _topics = [];
  Topic? _selectedTopic;
  String? _selectedDifficulty;
  List<Question> _generated = [];
  List<bool> _selected = [];
  bool _isGenerating = false;
  bool _showAdvancedOptions = false;
  bool _useCustomTopic = false;
  bool _useFileUpload = false;
  String _loadingMessage = '';
  String? _uploadedFileName;
  String? _uploadedFileContent;
  User? _currentUser;

  static const double _smallSpacing = AppTheme.spacing2;
  static const double _mediumSpacing = AppTheme.spacing4;

  @override
  void initState() {
    super.initState();
    _groqFuture = ServiceLocator.groq;
    _topicsFuture = _loadTopics();
    _loadCurrentUser();
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

  Future<User?> _loadCurrentUser() async {
    final auth = await ServiceLocator.auth;
    final user = await auth.getCurrentUser();
    if (user != null && mounted) {
      setState(() => _currentUser = user);
    }
    return user;
  }

  Future<void> _loadQuotaInfo() async {
    // Trigger a rebuild to refresh the quota indicator
    setState(() {});
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
    if (_selectedTopic == null && !_useCustomTopic && !_useFileUpload) {
      await DialogHelper.showError(
        context,
        'Please select a topic, enter a custom topic, or upload a file before generating questions.',
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

    // SECURITY: Get current user for quota enforcement
    if (_currentUser == null) {
      final auth = await ServiceLocator.auth;
      _currentUser = await auth.getCurrentUser();
      if (_currentUser == null) {
        if (!mounted) return;
        await DialogHelper.showError(
          context,
          'You must be logged in to generate questions.',
          title: 'Authentication required',
        );
        return;
      }
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
      List<Question> questions;
      Topic? topicToUse = _selectedTopic;

      if (_useFileUpload && _uploadedFileContent != null) {
        setState(() => _loadingMessage = 'Generating from file content...');
        questions = await groq.generateFromFileContent(
          fileContent: _uploadedFileContent!,
          topicId: _selectedTopic?.id ?? 1,
          difficulty: _selectedDifficulty!,
          quantity: quantity,
          category: _categoryController.text.trim(),
          user: _currentUser!,
        );
      } else if (_useCustomTopic && _customTopicController.text.trim().isNotEmpty) {
        setState(() => _loadingMessage = 'Generating from custom topic...');
        questions = await groq.generateFromCustomTopic(
          customTopic: _customTopicController.text.trim(),
          topicId: _selectedTopic?.id ?? 1,
          difficulty: _selectedDifficulty!,
          quantity: quantity,
          category: _categoryController.text.trim(),
          user: _currentUser!,
        );
      } else {
        setState(() => _loadingMessage = 'Generating questions...');
        questions = await groq.generateQuestions(
          topicId: _selectedTopic!.id!,
          difficulty: _selectedDifficulty!,
          quantity: quantity,
          category: _categoryController.text.trim(),
          user: _currentUser!,
        );
      }

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
            topic: topicToUse ?? Topic(name: _customTopicController.text.trim(), description: 'Custom topic'),
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
          _uploadedFileContent = null;
          _uploadedFileName = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      
      // Handle quota exceeded exceptions specifically
      if (message.contains('quota') || message.contains('limit reached') || message.contains('not available for')) {
        await DialogHelper.showError(
          context,
          message,
          title: 'Quota Limit',
        );
        // Reload quota info to update the UI
        if (_currentUser != null) {
          _loadQuotaInfo();
        }
      } else if (message.contains('internet') || message.contains('network')) {
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

  Future<void> _pickFile() async {
    try {
      final filePicker = ServiceLocator.fileProcessing;
      final result = await filePicker.pickFile();
      
      if (result != null) {
        setState(() => _loadingMessage = 'Processing file...');
        
        final content = await filePicker.extractTextFromFile(result);
        final fileName = result.files.first.name;
        
        setState(() {
          _uploadedFileContent = content;
          _uploadedFileName = fileName;
          _useFileUpload = true;
          _useCustomTopic = false;
          _loadingMessage = '';
        });
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File "$fileName" loaded successfully')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMessage = '');
      await DialogHelper.showError(
        context,
        e.toString().replaceFirst('Exception: ', ''),
        title: 'File processing error',
      );
    }
  }

  Future<void> _identifyTopic() async {
    if (_uploadedFileContent == null && _customTopicController.text.trim().isEmpty) {
      await DialogHelper.showError(
        context,
        'Please upload a file or enter custom text to identify the topic.',
        title: 'No content',
      );
      return;
    }

    final groq = await _groqFuture;
    final valid = await groq.hasValidApiKey();
    if (!mounted) return;
    if (!valid) {
      await DialogHelper.showError(
        context,
        'A valid Groq API key is required for topic identification.',
        title: 'Invalid API key',
      );
      return;
    }

    setState(() => _loadingMessage = 'Identifying topic...');

    try {
      final content = _uploadedFileContent ?? _customTopicController.text.trim();
      final identifiedTopic = await groq.identifyTopic(content);
      
      if (!mounted) return;
      
      // Try to find matching topic
      final matchingTopic = _topics.firstWhere(
        (t) => t.name.toLowerCase().contains(identifiedTopic.toLowerCase()),
        orElse: () => _topics.isNotEmpty ? _topics.first : Topic(name: identifiedTopic, description: 'AI-identified topic'),
      );
      
      setState(() {
        _selectedTopic = matchingTopic;
        _loadingMessage = '';
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Topic identified: ${matchingTopic.name}')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMessage = '');
      await DialogHelper.showError(
        context,
        e.toString().replaceFirst('Exception: ', ''),
        title: 'Topic identification error',
      );
    }
  }

  Future<void> _searchTopicInfo() async {
    if (_selectedTopic == null && !_useCustomTopic) {
      await DialogHelper.showError(
        context,
        'Please select a topic or enter a custom topic first.',
        title: 'No topic selected',
      );
      return;
    }

    final groq = await _groqFuture;
    final valid = await groq.hasValidApiKey();
    if (!mounted) return;
    if (!valid) {
      await DialogHelper.showError(
        context,
        'A valid Groq API key is required for topic search.',
        title: 'Invalid API key',
      );
      return;
    }

    setState(() => _loadingMessage = 'Searching topic information...');

    try {
      final topicName = _useCustomTopic 
          ? _customTopicController.text.trim() 
          : _selectedTopic!.name;
      
      final topicInfo = await groq.searchTopicInfo(topicName);
      
      if (!mounted) return;
      setState(() => _loadingMessage = '');
      
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Topic: $topicName'),
          content: SingleChildScrollView(
            child: Text(topicInfo),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMessage = '');
      await DialogHelper.showError(
        context,
        e.toString().replaceFirst('Exception: ', ''),
        title: 'Topic search error',
      );
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
                  if (_currentUser != null)
                    QuotaIndicator(user: _currentUser!),
                  if (_currentUser != null)
                    const SizedBox(height: _mediumSpacing),
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
            
            // Generation mode selector
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'topic',
                  label: Text('Topic'),
                  icon: Icon(LucideIcons.book, size: 16),
                ),
                ButtonSegment(
                  value: 'custom',
                  label: Text('Custom'),
                  icon: Icon(LucideIcons.edit3, size: 16),
                ),
                ButtonSegment(
                  value: 'file',
                  label: Text('File'),
                  icon: Icon(LucideIcons.fileText, size: 16),
                ),
              ],
              selected: {_useCustomTopic ? 'custom' : _useFileUpload ? 'file' : 'topic'},
              onSelectionChanged: (Set<String> selection) {
                final mode = selection.first;
                setState(() {
                  _useCustomTopic = mode == 'custom';
                  _useFileUpload = mode == 'file';
                  if (mode == 'topic') {
                    _uploadedFileContent = null;
                    _uploadedFileName = null;
                  }
                });
              },
            ),
            const SizedBox(height: _mediumSpacing),
            
            // Topic selection (shown when not using custom/file mode)
            if (!_useCustomTopic && !_useFileUpload) ...[
              SmartTopicDropdown(
                selectedTopic: _selectedTopic?.name,
                existingTopics: _topics.map((t) => t.name).toList(),
                onTopicSelected: (topicName) {
                  Topic? topic;
                  try {
                    topic = _topics.firstWhere((t) => t.name == topicName);
                  } catch (e) {
                    topic = _topics.isNotEmpty 
                        ? _topics.first 
                        : Topic(name: topicName ?? 'Custom', description: '');
                  }
                  setState(() => _selectedTopic = topic);
                },
                labelText: 'Topic',
                hintText: 'Select a topic',
              ),
              const SizedBox(height: _mediumSpacing),
            ],
            
            // Custom topic input (shown when using custom mode)
            if (_useCustomTopic) ...[
              TextField(
                controller: _customTopicController,
                decoration: InputDecoration(
                  labelText: 'Custom Topic',
                  hintText: 'Enter a custom topic or description',
                  filled: true,
                  prefixIcon: const Icon(LucideIcons.edit3),
                  suffixIcon: IconButton(
                    icon: const Icon(LucideIcons.sparkles),
                    onPressed: _identifyTopic,
                    tooltip: 'Auto-identify topic',
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: _smallSpacing),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _identifyTopic,
                      icon: const Icon(LucideIcons.sparkles, size: 16),
                      label: const Text('Identify Topic'),
                    ),
                  ),
                  const SizedBox(width: _smallSpacing),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _searchTopicInfo,
                      icon: const Icon(LucideIcons.search, size: 16),
                      label: const Text('Search Info'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: _mediumSpacing),
            ],
            
            // File upload (shown when using file mode)
            if (_useFileUpload) ...[
              if (_uploadedFileName != null) ...[
                Container(
                  padding: const EdgeInsets.all(_smallSpacing),
                  decoration: BoxDecoration(
                    color: AppColors.add.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.add),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.fileCheck, color: AppColors.add, size: 20),
                      const SizedBox(width: _smallSpacing),
                      Expanded(
                        child: Text(
                          _uploadedFileName!,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 16),
                        onPressed: () => setState(() {
                          _uploadedFileContent = null;
                          _uploadedFileName = null;
                        }),
                        tooltip: 'Remove file',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: _smallSpacing),
              ] else ...[
                OutlinedButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(LucideIcons.upload),
                  label: const Text('Upload File (TXT, Images)'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
                const SizedBox(height: _smallSpacing),
                Text(
                  'Supported formats: TXT, JPG, PNG (OCR enabled)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: _mediumSpacing),
              ],
              if (_uploadedFileContent != null) ...[
                OutlinedButton.icon(
                  onPressed: _identifyTopic,
                  icon: const Icon(LucideIcons.sparkles, size: 16),
                  label: const Text('Identify Topic from File'),
                ),
                const SizedBox(height: _mediumSpacing),
              ],
            ],
            
            // Common settings
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
    _customTopicController.dispose();
    super.dispose();
  }
}
