import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../database/database_helper.dart';
import '../../models/quiz_result.dart';
import '../../models/topic.dart';
import '../../models/user.dart';
import '../../services/service_locator.dart';
import '../../widgets/role_guard.dart';

/// Teacher view of all quiz results.
class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final _db = ServiceLocator.db;
  late Future<List<QuizResult>> _future;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = _db.getAllResults();
    setState(() {});
  }

  Future<void> _exportToCSV() async {
    setState(() => _isExporting = true);

    try {
      final results = await _db.getAllResults();
      if (results.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No results to export')),
        );
        setState(() => _isExporting = false);
        return;
      }

      final csvBuffer = StringBuffer();
      csvBuffer.writeln('Student,Topic,Difficulty,Score,Total,Percentage,Status,Date');

      for (final result in results) {
        final user = await _db.getUserById(result.userId);
        final topic = await _db.getTopicById(result.topicId);
        
        final studentName = user?.fullName ?? 'Unknown';
        final topicName = topic?.name ?? 'Unknown';
        final status = result.passed ? 'PASS' : 'FAIL';
        final date = result.createdAt.substring(0, 16).replaceFirst('T', ' ');

        csvBuffer.writeln('$studentName,$topicName,${result.difficulty},${result.score},${result.totalQuestions},${result.percentage.toStringAsFixed(1)},$status,$date');
      }

      if (!mounted) return;
      await Share.share(csvBuffer.toString(), subject: 'Quiz Results Export');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Results exported successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRole: AppConstants.roleTeacher,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('All Results'),
          actions: [
            IconButton(
              icon: _isExporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(LucideIcons.download, color: AppColors.edit),
              onPressed: _isExporting ? null : _exportToCSV,
              tooltip: 'Export to CSV',
            ),
          ],
        ),
        body: FutureBuilder(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final results = snapshot.data ?? [];
            if (results.isEmpty) {
              return const Center(child: Text('No quiz attempts yet.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(AppTheme.mediumSpacing),
              itemCount: results.length,
              itemBuilder: (context, index) {
                final r = results[index];
                return _ResultCard(result: r, db: _db);
              },
            );
          },
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final QuizResult result;
  final DatabaseHelper db;

  const _ResultCard({required this.result, required this.db});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadDetails(),
      builder: (context, snapshot) {
        final user = snapshot.data?['user'] as User?;
        final topic = snapshot.data?['topic'] as Topic?;

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: result.passed ? AppColors.add : AppColors.delete,
              child: Icon(
                result.passed ? LucideIcons.check : LucideIcons.x,
                color: Colors.white,
              ),
            ),
            title: Text('${user?.fullName ?? 'Student'} — ${topic?.name ?? 'Topic'}'),
            subtitle: Text(
              'Score: ${result.score}/${result.totalQuestions}  |  ${result.percentage.toStringAsFixed(1)}%\n'
              'Difficulty: ${result.difficulty}',
            ),
            isThreeLine: true,
            trailing: Text(
              result.passed ? 'PASS' : 'FAIL',
              style: TextStyle(
                color: result.passed ? AppColors.add : AppColors.delete,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _loadDetails() async {
    final user = await db.getUserById(result.userId);
    final topic = await db.getTopicById(result.topicId);
    return {'user': user, 'topic': topic};
  }
}
