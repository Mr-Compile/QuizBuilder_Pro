import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/permissions/permission_manager.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/question.dart';
import '../../models/topic.dart';
import '../../services/service_locator.dart';
import '../../widgets/role_guard.dart';
import '../../widgets/permission_guard.dart';
import '../../widgets/enhanced_cards.dart';
import '../../widgets/enhanced_navigation.dart';

// Spacing constants for better readability
const double _smallSpacing = AppTheme.spacing2;
const double _mediumSpacing = AppTheme.spacing4;

/// Screen for the teacher to manage, search and filter questions.
class QuestionManagementScreen extends StatefulWidget {
  const QuestionManagementScreen({super.key});

  @override
  State<QuestionManagementScreen> createState() => _QuestionManagementScreenState();
}

class _QuestionManagementScreenState extends State<QuestionManagementScreen> {
  final _db = ServiceLocator.db;
  final _searchController = TextEditingController();
  late Future<List<Question>> _questionsFuture;
  late Future<List<Topic>> _topicsFuture;

  int? _selectedTopicId;
  String? _selectedDifficulty;

  @override
  void initState() {
    super.initState();
    _load();
    _topicsFuture = _db.getAllTopics();
  }

  void _load() {
    _questionsFuture = _db.getQuestions(
      topicId: _selectedTopicId,
      difficulty: _selectedDifficulty,
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
    );
    setState(() {});
  }

  Future<void> _delete(Question question) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Question'),
        content: const Text('Are you sure you want to delete this question? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.delete, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _db.deleteQuestion(question.id!);
      _load();
    }
  }

  Color _difficultyColor(String difficulty) {
    switch (difficulty) {
      case AppConstants.difficultyEasy:
        return AppColors.add;
      case AppConstants.difficultyMedium:
        return AppColors.accent;
      case AppConstants.difficultyHard:
        return AppColors.delete;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRole: AppConstants.roleTeacher,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Questions'),
          elevation: 0,
          actions: [
            PermissionGuard(
              permission: AppPermissions.createQuestions,
              child: IconButton(
                icon: const Icon(LucideIcons.plus, color: AppColors.add),
                onPressed: () async {
                  await Navigator.pushNamed(context, AppRoutes.questionForm);
                  _load();
                },
                tooltip: 'Add Question',
              ),
            ),
            PermissionGuard(
              permission: AppPermissions.generateAIQuestions,
              child: IconButton(
                icon: const Icon(LucideIcons.wand, color: AppColors.startQuiz),
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.aiGenerate);
                },
                tooltip: 'Generate AI Questions',
              ),
            ),
          ],
        ),
        drawer: EnhancedDrawer(
          currentRoute: AppRoutes.questionManagement,
          onLogout: _logout,
        ),
        body: Column(
          children: [
            _buildFilters(),
            Expanded(
              child: FutureBuilder(
                future: _questionsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final questions = snapshot.data ?? [];

                  if (questions.isEmpty) {
                    return _buildEmptyState();
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      _load();
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: _smallSpacing),
                      itemCount: questions.length,
                      itemBuilder: (context, index) {
                        final q = questions[index];
                        return EnhancedListItem(
                          title: q.question,
                          subtitle: 'Correct: ${q.correctAnswer}  |  Source: ${q.source}  |  Difficulty: ${q.difficulty}',
                          leading: CircleAvatar(
                            backgroundColor: _difficultyColor(q.difficulty).withValues(alpha: 0.15),
                            child: Text(
                              q.difficulty[0],
                              style: TextStyle(
                                color: _difficultyColor(q.difficulty),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          trailing: [
                            PermissionGuard(
                              permission: AppPermissions.editQuestions,
                              child: IconButton(
                                icon: const Icon(LucideIcons.edit, color: AppColors.edit),
                                onPressed: () async {
                                  await Navigator.pushNamed(
                                    context,
                                    AppRoutes.questionForm,
                                    arguments: {'question': q},
                                  );
                                  _load();
                                },
                              ),
                            ),
                            PermissionGuard(
                              permission: AppPermissions.deleteQuestions,
                              child: IconButton(
                                icon: const Icon(LucideIcons.trash2, color: AppColors.delete),
                                onPressed: () => _delete(q),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(_mediumSpacing),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search questions...',
              prefixIcon: const Icon(LucideIcons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(LucideIcons.x),
                      onPressed: () {
                        _searchController.clear();
                        _load();
                      },
                    )
                  : null,
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
            onChanged: (_) => _load(),
          ),
          const SizedBox(height: _smallSpacing),
          FutureBuilder(
            future: _topicsFuture,
            builder: (context, topicSnapshot) {
              final topics = topicSnapshot.data ?? [];
              return Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      initialValue: _selectedTopicId,
                      decoration: const InputDecoration(
                        labelText: 'Topic',
                        filled: true,
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Topics')),
                        for (final t in topics)
                          DropdownMenuItem(value: t.id, child: Text(t.name)),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedTopicId = value);
                        _load();
                      },
                    ),
                  ),
                  const SizedBox(width: _smallSpacing),
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      initialValue: _selectedDifficulty,
                      decoration: const InputDecoration(
                        labelText: 'Difficulty',
                        filled: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('All')),
                        DropdownMenuItem(value: AppConstants.difficultyEasy, child: Text('Easy')),
                        DropdownMenuItem(value: AppConstants.difficultyMedium, child: Text('Medium')),
                        DropdownMenuItem(value: AppConstants.difficultyHard, child: Text('Hard')),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedDifficulty = value);
                        _load();
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.helpCircle,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: _mediumSpacing),
          Text(
            'No questions found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: _smallSpacing),
          Text(
            'Try adjusting your filters or add a new question',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                ),
          ),
        ],
      ),
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
    _searchController.dispose();
    super.dispose();
  }
}