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

/// Difficulty selection screen for the selected topic.
class DifficultySelectionScreen extends StatefulWidget {
  final Topic topic;

  const DifficultySelectionScreen({super.key, required this.topic});

  @override
  State<DifficultySelectionScreen> createState() => _DifficultySelectionScreenState();
}

class _DifficultySelectionScreenState extends State<DifficultySelectionScreen> {
  final _db = ServiceLocator.db;

  Future<int> _count(String difficulty) async {
    final questions = await _db.getQuestions(
      topicId: widget.topic.id,
      difficulty: difficulty,
    );
    return questions.length;
  }

  Widget _buildMobileDifficultyCards() {
    return Column(
      children: [
        _DifficultyCard(
          topic: widget.topic,
          difficulty: AppConstants.difficultyEasy,
          color: AppColors.add,
          icon: LucideIcons.smile,
          questionCount: _count,
        ),
        SizedBox(height: context.responsiveSpacing),
        _DifficultyCard(
          topic: widget.topic,
          difficulty: AppConstants.difficultyMedium,
          color: AppColors.accent,
          icon: LucideIcons.meh,
          questionCount: _count,
        ),
        SizedBox(height: context.responsiveSpacing),
        _DifficultyCard(
          topic: widget.topic,
          difficulty: AppConstants.difficultyHard,
          color: AppColors.delete,
          icon: LucideIcons.frown,
          questionCount: _count,
        ),
      ],
    );
  }

  Widget _buildTabletDifficultyCards() {
    return ResponsiveGrid(
      mobileColumns: 1,
      tabletColumns: 3,
      desktopColumns: 3,
      childAspectRatio: 2.0,
      children: [
        _DifficultyCard(
          topic: widget.topic,
          difficulty: AppConstants.difficultyEasy,
          color: AppColors.add,
          icon: LucideIcons.smile,
          questionCount: _count,
        ),
        _DifficultyCard(
          topic: widget.topic,
          difficulty: AppConstants.difficultyMedium,
          color: AppColors.accent,
          icon: LucideIcons.meh,
          questionCount: _count,
        ),
        _DifficultyCard(
          topic: widget.topic,
          difficulty: AppConstants.difficultyHard,
          color: AppColors.delete,
          icon: LucideIcons.frown,
          questionCount: _count,
        ),
      ],
    );
  }

  Widget _buildDesktopDifficultyCards() {
    return _buildTabletDifficultyCards();
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRole: AppConstants.roleStudent,
      child: NavigationScaffold(
        title: '${widget.topic.name} — Difficulty',
        currentRoute: AppRoutes.difficultySelect,
        body: ResponsiveContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose difficulty',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: context.responsiveSpacing),
              const Text('Pick a level based on how many questions are available.'),
              SizedBox(height: context.responsiveSpacing * 2),
              ResponsiveBuilder(
                mobile: _buildMobileDifficultyCards(),
                tablet: _buildTabletDifficultyCards(),
                desktop: _buildDesktopDifficultyCards(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  final Topic topic;
  final String difficulty;
  final Color color;
  final IconData icon;
  final Future<int> Function(String) questionCount;

  const _DifficultyCard({
    required this.topic,
    required this.difficulty,
    required this.color,
    required this.icon,
    required this.questionCount,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: questionCount(difficulty),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return ResponsiveCard(
          isGridItem: context.isTablet || context.isDesktop,
          child: context.isMobile
              ? _buildMobileLayout(context, count)
              : _buildGridLayout(context, count),
        );
      },
    );
  }

  Widget _buildMobileLayout(BuildContext context, int count) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(icon, color: color),
      ),
      title: Text(difficulty, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      subtitle: Text('$count question${count == 1 ? '' : 's'}'),
      trailing: ElevatedButton(
        onPressed: count > 0
            ? () => Navigator.pushNamed(
                  context,
                  AppRoutes.quiz,
                  arguments: {'topic': topic, 'difficulty': difficulty},
                )
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.startQuiz,
          foregroundColor: Colors.white,
        ),
        child: const Text('Start'),
      ),
    );
  }

  Widget _buildGridLayout(BuildContext context, int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color, size: context.isTablet ? 28 : 32),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                difficulty,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: context.isTablet ? 16 : 18,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '$count question${count == 1 ? '' : 's'}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: count > 0
                ? () => Navigator.pushNamed(
                      context,
                      AppRoutes.quiz,
                      arguments: {'topic': topic, 'difficulty': difficulty},
                    )
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.startQuiz,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                vertical: context.isTablet ? 12 : 14,
              ),
            ),
            child: const Text('Start'),
          ),
        ),
      ],
    );
  }
}
