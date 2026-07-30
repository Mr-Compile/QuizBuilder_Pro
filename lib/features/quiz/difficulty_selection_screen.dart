import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/topic.dart';
import '../../services/service_locator.dart';
import '../../widgets/role_guard.dart';

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

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRole: AppConstants.roleStudent,
      child: Scaffold(
        appBar: AppBar(title: Text('${widget.topic.name} — Difficulty')),
        body: Padding(
          padding: const EdgeInsets.all(AppTheme.mediumSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose difficulty',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppTheme.smallSpacing),
              Text('Pick a level based on how many questions are available.'),
              const SizedBox(height: AppTheme.largeSpacing),
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
        return Card(
          child: ListTile(
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
          ),
        );
      },
    );
  }
}
