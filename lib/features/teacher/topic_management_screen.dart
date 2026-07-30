import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../database/database_helper.dart';
import '../../models/topic.dart';
import '../../services/service_locator.dart';
import '../../widgets/role_guard.dart';

/// Screen to create, edit and delete topics.
class TopicManagementScreen extends StatefulWidget {
  const TopicManagementScreen({super.key});

  @override
  State<TopicManagementScreen> createState() => _TopicManagementScreenState();
}

class _TopicManagementScreenState extends State<TopicManagementScreen> {
  final _db = ServiceLocator.db;
  final _searchController = TextEditingController();
  late Future<List<Topic>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = _db.getAllTopics();
    setState(() {});
  }

  Future<void> _delete(Topic topic) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Topic'),
        content: Text('Delete "${topic.name}" and all its questions?'),
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

    if (confirm == true) {
      await _db.deleteTopic(topic.id!);
      _load();
    }
  }

  List<Topic> _filter(List<Topic> topics) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return topics;
    return topics.where((t) => t.name.toLowerCase().contains(query) || t.description.toLowerCase().contains(query)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRole: AppConstants.roleTeacher,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Topics'),
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.plus, color: AppColors.add),
              onPressed: () async {
                await Navigator.pushNamed(context, AppRoutes.topicForm);
                _load();
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppTheme.mediumSpacing),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search topics...',
                  prefixIcon: const Icon(LucideIcons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(LucideIcons.x),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            Expanded(
              child: FutureBuilder(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final topics = _filter(snapshot.data ?? []);

                  if (topics.isEmpty) {
                    return const Center(child: Text('No topics found.'));
                  }

                  return ListView.builder(
                    itemCount: topics.length,
                    itemBuilder: (context, index) {
                      final t = topics[index];
                      return FutureBuilder<int>(
                        future: _db.getQuestionCountByTopic(t.id!),
                        builder: (context, countSnapshot) {
                          final count = countSnapshot.data ?? 0;
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                                child: Icon(LucideIcons.bookOpen, color: Theme.of(context).colorScheme.primary),
                              ),
                              title: Text(t.name),
                              subtitle: Text('${t.description}\n$count question${count == 1 ? '' : 's'}'),
                              isThreeLine: true,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(LucideIcons.edit, color: AppColors.edit),
                                    onPressed: () async {
                                      await Navigator.pushNamed(
                                        context,
                                        AppRoutes.topicForm,
                                        arguments: {'topic': t},
                                      );
                                      _load();
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(LucideIcons.trash2, color: AppColors.delete),
                                    onPressed: () => _delete(t),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
