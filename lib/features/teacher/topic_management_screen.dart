import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/permissions/permission_manager.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/confirmation/confirmation.dart';
import '../../models/topic.dart';
import '../../services/service_locator.dart';
import '../../widgets/role_guard.dart';
import '../../widgets/permission_guard.dart';
import '../../widgets/enhanced_cards.dart';
import '../../widgets/navigation_scaffold.dart';
import '../../widgets/modal_bottom_sheet.dart';
import '../../widgets/smart_topic_dropdown.dart';

// Spacing constants for better readability
const double _smallSpacing = AppTheme.spacing2;
const double _mediumSpacing = AppTheme.spacing4;

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
    final confirmed = await ConfirmationDialogs.confirmDestructive(
      context,
      itemName: '"${topic.name}" and all its questions',
      action: 'delete',
    );

    if (confirmed) {
      await _db.deleteTopic(topic.id!);
      _load();
    }
  }

  List<Topic> _filter(List<Topic> topics) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return topics;
    return topics.where((t) => t.name.toLowerCase().contains(query) || t.description.toLowerCase().contains(query)).toList();
  }

  void _showAddTopicModal(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ModalBottomSheet(
        title: 'Add New Topic',
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a topic name')),
                );
                return;
              }

              final topic = Topic(
                name: nameController.text.trim(),
                description: descriptionController.text.trim().isEmpty 
                    ? 'No description' 
                    : descriptionController.text.trim(),
              );

              await _db.insertTopic(topic);
              if (!mounted) return;
              if (!context.mounted) return;
              Navigator.pop(context);
              _load();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Topic added successfully')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.add,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add Topic'),
          ),
        ],
        children: [
          SmartTopicDropdown(
            selectedTopic: null,
            existingTopics: const [],
            onTopicSelected: (topic) => nameController.text = topic ?? '',
            labelText: 'Topic Name',
            hintText: 'Search or enter topic name',
          ),
          const SizedBox(height: _mediumSpacing),
          TextField(
            controller: descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Enter topic description',
              filled: true,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditTopicModal(BuildContext context, Topic topic) {
    final nameController = TextEditingController(text: topic.name);
    final descriptionController = TextEditingController(text: topic.description);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ModalBottomSheet(
        title: 'Edit Topic',
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a topic name')),
                );
                return;
              }

              final updatedTopic = topic.copyWith(
                name: nameController.text.trim(),
                description: descriptionController.text.trim().isEmpty 
                    ? 'No description' 
                    : descriptionController.text.trim(),
              );

              await _db.updateTopic(updatedTopic);
              if (!mounted) return;
              if (!context.mounted) return;
              Navigator.pop(context);
              _load();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Topic updated successfully')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.edit,
              foregroundColor: Colors.white,
            ),
            child: const Text('Update Topic'),
          ),
        ],
        children: [
          SmartTopicDropdown(
            selectedTopic: topic.name,
            existingTopics: const [],
            onTopicSelected: (newTopic) => nameController.text = newTopic ?? topic.name,
            labelText: 'Topic Name',
            hintText: 'Search or enter topic name',
          ),
          const SizedBox(height: _mediumSpacing),
          TextField(
            controller: descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Enter topic description',
              filled: true,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRole: AppConstants.roleTeacher,
      child: NavigationScaffold(
        title: 'Manage Topics',
        currentRoute: AppRoutes.topicManagement,
        actions: [
          PermissionGuard(
            permission: AppPermissions.createTopics,
            child: IconButton(
              icon: const Icon(LucideIcons.plus, color: AppColors.add),
              onPressed: () => _showAddTopicModal(context),
              tooltip: 'Add Topic',
            ),
          ),
        ],
        body: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: FutureBuilder(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final topics = _filter(snapshot.data ?? []);

                  if (topics.isEmpty) {
                    return _buildEmptyState();
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      _load();
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: _smallSpacing),
                      itemCount: topics.length,
                      itemBuilder: (context, index) {
                        final t = topics[index];
                        return FutureBuilder<int>(
                          future: _db.getQuestionCountByTopic(t.id!),
                          builder: (context, countSnapshot) {
                            final count = countSnapshot.data ?? 0;
                            return EnhancedListItem(
                              title: t.name,
                              subtitle: '${t.description}\n$count question${count == 1 ? '' : 's'}',
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                                child: Icon(t.icon ?? LucideIcons.bookOpen, color: Theme.of(context).colorScheme.primary),
                              ),
                              trailing: [
                                PermissionGuard(
                                  permission: AppPermissions.editTopics,
                                  child: IconButton(
                                    icon: const Icon(LucideIcons.edit, color: AppColors.edit),
                                    onPressed: () => _showEditTopicModal(context, t),
                                  ),
                                ),
                                PermissionGuard(
                                  permission: AppPermissions.deleteTopics,
                                  child: IconButton(
                                    icon: const Icon(LucideIcons.trash2, color: AppColors.delete),
                                    onPressed: () => _delete(t),
                                  ),
                                ),
                              ],
                            );
                          },
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(_mediumSpacing),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search topics by name or description...',
          prefixIcon: const Icon(LucideIcons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(LucideIcons.x),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.bookOpen,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: _mediumSpacing),
          Text(
            'No topics found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: _smallSpacing),
          Text(
            'Try adjusting your search or create a new topic',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}