import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../database/database_helper.dart';
import '../../models/quiz_result.dart';
import '../../models/topic.dart';
import '../../services/service_locator.dart';
import '../../widgets/role_guard.dart';

/// Student history of quiz attempts.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _db = ServiceLocator.db;
  late Future<List<QuizResult>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = _loadResults();
    setState(() {});
  }

  Future<List<QuizResult>> _loadResults() async {
    final auth = await ServiceLocator.auth;
    final user = await auth.getCurrentUser();
    if (user == null) return [];
    return _db.getResultsForUser(user.id!);
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRole: AppConstants.roleStudent,
      child: Scaffold(
        appBar: AppBar(title: const Text('My History')),
        body: FutureBuilder(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final results = snapshot.data ?? [];
            if (results.isEmpty) {
              return const Center(child: Text('No quizzes taken yet.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(AppTheme.mediumSpacing),
              itemCount: results.length,
              itemBuilder: (context, index) {
                final r = results[index];
                return _HistoryCard(result: r, db: _db);
              },
            );
          },
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final QuizResult result;
  final DatabaseHelper db;

  const _HistoryCard({required this.result, required this.db});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: db.getTopicById(result.topicId),
      builder: (context, topicSnapshot) {
        final topic = topicSnapshot.data as Topic?;
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: result.passed ? AppColors.add : AppColors.delete,
              child: Icon(
                result.passed ? LucideIcons.check : LucideIcons.x,
                color: Colors.white,
              ),
            ),
            title: Text('${topic?.name ?? 'Topic'} — ${result.difficulty}'),
            subtitle: Text(
              '${result.score}/${result.totalQuestions} correct  |  ${result.percentage.toStringAsFixed(1)}%',
            ),
            trailing: const Icon(LucideIcons.chevronRight),
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.quizReview,
              arguments: {'resultId': result.id},
            ),
          ),
        );
      },
    );
  }
}
