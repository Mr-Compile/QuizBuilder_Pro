import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../services/service_locator.dart';
import '../../widgets/role_guard.dart';
import '../../widgets/enhanced_cards.dart';
import '../../widgets/enhanced_navigation.dart';

// Spacing constants for better readability
const double _smallSpacing = AppTheme.spacing2;
const double _mediumSpacing = AppTheme.spacing4;
const double _largeSpacing = AppTheme.spacing6;

/// Teacher dashboard with summary cards and quick actions.
class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  final _db = ServiceLocator.db;

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRole: AppConstants.roleTeacher,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Teacher Dashboard'),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.logOut, color: AppColors.logout),
              onPressed: _logout,
              tooltip: 'Logout',
            ),
          ],
        ),
        drawer: EnhancedDrawer(
          currentRoute: AppRoutes.teacherDashboard,
          onLogout: _logout,
        ),
        body: FutureBuilder(
          future: _loadSummary(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data ?? Summary(0, 0, 0, 0, 0);
            return SingleChildScrollView(
              padding: const EdgeInsets.all(_mediumSpacing),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: _largeSpacing),
                  _buildSummaryCards(context, data),
                  const SizedBox(height: _largeSpacing),
                  _buildQuickActions(context),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome Back!',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Here\'s what\'s happening with your classes today.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(BuildContext context, Summary data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: _mediumSpacing),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: _mediumSpacing,
          crossAxisSpacing: _mediumSpacing,
          childAspectRatio: 1.2,
          children: [
            EnhancedSummaryCard(
              label: 'Total Students',
              value: data.totalStudents.toString(),
              icon: LucideIcons.users,
              color: AppColors.primary,
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.studentManagement),
            ),
            EnhancedSummaryCard(
              label: 'Active Students',
              value: data.activeStudents.toString(),
              icon: LucideIcons.userCheck,
              color: AppColors.add,
            ),
            EnhancedSummaryCard(
              label: 'Topics',
              value: data.topics.toString(),
              icon: LucideIcons.bookOpen,
              color: AppColors.secondary,
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.topicManagement),
            ),
            EnhancedSummaryCard(
              label: 'Questions',
              value: data.questions.toString(),
              icon: LucideIcons.helpCircle,
              color: AppColors.accent,
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.questionManagement),
            ),
            EnhancedSummaryCard(
              label: 'Quiz Attempts',
              value: data.attempts.toString(),
              icon: LucideIcons.clipboardList,
              color: AppColors.edit,
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.results),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: _mediumSpacing),
        EnhancedActionCard(
          icon: LucideIcons.users,
          label: 'Manage Students',
          subtitle: 'Add, edit, or deactivate student accounts',
          color: AppColors.primary,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.studentManagement),
        ),
        const SizedBox(height: _smallSpacing),
        EnhancedActionCard(
          icon: LucideIcons.bookOpen,
          label: 'Manage Topics',
          subtitle: 'Create and organize quiz topics',
          color: AppColors.secondary,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.topicManagement),
        ),
        const SizedBox(height: _smallSpacing),
        EnhancedActionCard(
          icon: LucideIcons.helpCircle,
          label: 'Manage Questions',
          subtitle: 'Add, edit, or remove quiz questions',
          color: AppColors.accent,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.questionManagement),
        ),
        const SizedBox(height: _smallSpacing),
        EnhancedActionCard(
          icon: LucideIcons.wand2,
          label: 'Generate AI Questions',
          subtitle: 'Create questions using AI assistance',
          color: AppColors.startQuiz,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.aiGenerate),
        ),
        const SizedBox(height: _smallSpacing),
        EnhancedActionCard(
          icon: LucideIcons.barChart2,
          label: 'View Statistics',
          subtitle: 'Analyze performance and trends',
          color: AppColors.add,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.teacherStatistics),
        ),
      ],
    );
  }

  Future<void> _logout() async {
    final auth = await ServiceLocator.auth;
    await auth.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  Future<Summary> _loadSummary() async {
    return Summary(
      await _db.countStudents(),
      await _db.countStudents(activeOnly: true),
      (await _db.getAllTopics()).length,
      await _db.countQuestions(),
      await _db.countResults(),
    );
  }
}

class Summary {
  final int totalStudents;
  final int activeStudents;
  final int topics;
  final int questions;
  final int attempts;

  Summary(this.totalStudents, this.activeStudents, this.topics, this.questions, this.attempts);
}