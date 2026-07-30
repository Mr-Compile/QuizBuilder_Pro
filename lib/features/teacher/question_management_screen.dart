import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../database/database_helper.dart';
import '../../models/question.dart';
import '../../models/topic.dart';
import '../../services/service_locator.dart';
import '../../widgets/role_guard.dart';

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
        content: const Text('Are you sure you want to delete this question?'),
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

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRole: AppConstants.roleTeacher,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Questions'),
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.plus, color: AppColors.add),
              onPressed: () async {
                await Navigator.pushNamed(context, AppRoutes.questionForm);
                _load();
              },
            ),
            IconButton(
              icon: const Icon(LucideIcons.wand, color: AppColors.startQuiz),
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.aiGenerate);
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppTheme.mediumSpacing),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search questions...',
                      prefixIcon: const Icon(LucideIcons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(LucideIcons.x),
                        onPressed: () {
                          _searchController.clear();
                          _load();
                        },
                      ),
                    ),
                    onChanged: (_) => _load(),
                  ),
                  const SizedBox(height: AppTheme.smallSpacing),
                  FutureBuilder(
                    future: _topicsFuture,
                    builder: (context, topicSnapshot) {
                      final topics = topicSnapshot.data ?? [];
                      return Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int?>(
                              value: _selectedTopicId,
                              decoration: const InputDecoration(labelText: 'Topic'),
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
                          const SizedBox(width: AppTheme.smallSpacing),
                          Expanded(
                            child: DropdownButtonFormField<String?>(
                              value: _selectedDifficulty,
                              decoration: const InputDecoration(labelText: 'Difficulty'),
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
            ),
            Expanded(
              child: FutureBuilder(
                future: _questionsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final questions = snapshot.data ?? [];

                  if (questions.isEmpty) {
                    return const Center(child: Text('No questions found.'));
                  }

                  return ListView.builder(
                    itemCount: questions.length,
                    itemBuilder: (context, index) {
                      final q = questions[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _difficultyColor(q.difficulty),
                            child: Text(q.difficulty[0]),
                          ),
                          title: Text(q.question, maxLines: 2, overflow: TextOverflow.ellipsis),
                          subtitle: Text('Correct: ${q.correctAnswer}  |  Source: ${q.source}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
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
                              IconButton(
                                icon: const Icon(LucideIcons.trash2, color: AppColors.delete),
                                onPressed: () => _delete(q),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
