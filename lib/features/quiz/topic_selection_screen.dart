import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/responsive_utils.dart';
import '../../models/topic.dart';
import '../../services/service_locator.dart';
import '../../widgets/role_guard.dart';
import '../../widgets/navigation_scaffold.dart';
import '../../widgets/responsive_widgets.dart';

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

  Widget _buildMobileTopicList(List<Topic> topics) {
    return ListView.builder(
      padding: EdgeInsets.all(context.responsiveSpacing),
      itemCount: topics.length,
      itemBuilder: (context, index) {
        final t = topics[index];
        return FutureBuilder<int>(
          future: _db.getQuestionCountByTopic(t.id!),
          builder: (context, countSnapshot) {
            final count = countSnapshot.data ?? 0;
            return Card(
              child: ListTile(
                contentPadding: EdgeInsets.all(context.responsiveCardPadding),
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
  }

  Widget _buildTabletTopicGrid(List<Topic> topics) {
    return ResponsiveGrid(
      mobileColumns: 1,
      tabletColumns: 2,
      desktopColumns: 3,
      childAspectRatio: context.isLandscape ? 2.5 : 1.8,
      children: topics.map((t) {
        return FutureBuilder<int>(
          future: _db.getQuestionCountByTopic(t.id!),
          builder: (context, countSnapshot) {
            final count = countSnapshot.data ?? 0;
            return ResponsiveCard(
              isGridItem: true,
              onTap: count > 0
                  ? () => Navigator.pushNamed(
                        context,
                        AppRoutes.difficultySelect,
                        arguments: {'topic': t},
                      )
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.secondary.withValues(alpha: 0.15),
                        child: const Icon(LucideIcons.bookOpen, color: AppColors.secondary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          t.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.description,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.helpCircle,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$count question${count == 1 ? '' : 's'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                      const Spacer(),
                      if (count > 0)
                        const Icon(
                          LucideIcons.chevronRight,
                          color: AppColors.secondary,
                          size: 20,
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildDesktopTopicGrid(List<Topic> topics) {
    return _buildTabletTopicGrid(topics);
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRole: AppConstants.roleStudent,
      child: NavigationScaffold(
        title: 'Select a Topic',
        currentRoute: AppRoutes.topicSelect,
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

            return ResponsiveBuilder(
              mobile: _buildMobileTopicList(topics),
              tablet: _buildTabletTopicGrid(topics),
              desktop: _buildDesktopTopicGrid(topics),
            );
          },
        ),
      ),
    );
  }
}
