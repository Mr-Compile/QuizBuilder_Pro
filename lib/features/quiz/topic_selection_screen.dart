import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/topic.dart';
import '../../services/service_locator.dart';
import '../../widgets/role_guard.dart';

/// Student topic selection with available question count.
class TopicSelectionScreen extends StatefulWidget {
  const TopicSelectionScreen({super.key});

  @override
  State<TopicSelectionScreen> createState() => _TopicSelectionScreenState();
}

class _TopicSelectionScreenState extends State<TopicSelectionScreen> {
  final _db = ServiceLocator.db;
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

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRole: AppConstants.roleStudent,
      child: Scaffold(
        appBar: AppBar(title: const Text('Select a Topic')),
        body: FutureBuilder(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final topics = snapshot.data ?? [];
            if (topics.isEmpty) {
              return const Center(child: Text('No topics available.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(AppTheme.mediumSpacing),
              itemCount: topics.length,
              itemBuilder: (context, index) {
                final t = topics[index];
                return FutureBuilder<int>(
                  future: _db.getQuestionCountByTopic(t.id!),
                  builder: (context, countSnapshot) {
                    final count = countSnapshot.data ?? 0;
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(AppTheme.cardPadding),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.secondary.withValues(alpha: 0.15),
                          child: const Icon(LucideIcons.bookOpen, color: AppColors.secondary),
                        ),
                        title: Text(t.name, style: Theme.of(context).textTheme.titleMedium),
                        subtitle: Text('${t.description}\n$count question${count == 1 ? '' : 's'} available'),
                        isThreeLine: true,
                        trailing: const Icon(LucideIcons.chevronRight, color: AppColors.secondary),
                        onTap: count > 0
                            ? () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.difficultySelect,
                                  arguments: {'topic': t},
                                )
                            : null,
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
