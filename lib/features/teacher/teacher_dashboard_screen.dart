import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../services/service_locator.dart';
import '../../widgets/role_guard.dart';

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
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.logOut, color: AppColors.logout),
              onPressed: _logout,
              tooltip: 'Logout',
            ),
          ],
        ),
        drawer: _buildDrawer(context),
        body: FutureBuilder(
          future: _loadSummary(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data ?? Summary(0, 0, 0, 0, 0);
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.mediumSpacing),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overview',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppTheme.smallSpacing),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: AppTheme.smallSpacing,
                    crossAxisSpacing: AppTheme.smallSpacing,
                    children: [
                      _SummaryCard(
                        label: 'Total Students',
                        value: data.totalStudents.toString(),
                        icon: LucideIcons.users,
                        color: AppColors.primary,
                      ),
                      _SummaryCard(
                        label: 'Active Students',
                        value: data.activeStudents.toString(),
                        icon: LucideIcons.userCheck,
                        color: AppColors.add,
                      ),
                      _SummaryCard(
                        label: 'Topics',
                        value: data.topics.toString(),
                        icon: LucideIcons.bookOpen,
                        color: AppColors.secondary,
                      ),
                      _SummaryCard(
                        label: 'Questions',
                        value: data.questions.toString(),
                        icon: LucideIcons.helpCircle,
                        color: AppColors.accent,
                      ),
                      _SummaryCard(
                        label: 'Quiz Attempts',
                        value: data.attempts.toString(),
                        icon: LucideIcons.clipboardList,
                        color: AppColors.edit,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.largeSpacing),
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppTheme.smallSpacing),
                  _QuickAction(
                    icon: LucideIcons.users,
                    label: 'Manage Students',
                    color: AppColors.primary,
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.studentManagement),
                  ),
                  _QuickAction(
                    icon: LucideIcons.bookOpen,
                    label: 'Manage Topics',
                    color: AppColors.secondary,
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.topicManagement),
                  ),
                  _QuickAction(
                    icon: LucideIcons.helpCircle,
                    label: 'Manage Questions',
                    color: AppColors.accent,
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.questionManagement),
                  ),
                  _QuickAction(
                    icon: LucideIcons.wand2,
                    label: 'Generate AI Questions',
                    color: AppColors.startQuiz,
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.aiGenerate),
                  ),
                  _QuickAction(
                    icon: LucideIcons.clipboardList,
                    label: 'All Results',
                    color: AppColors.edit,
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.results),
                  ),
                  _QuickAction(
                    icon: LucideIcons.barChart2,
                    label: 'Global Statistics',
                    color: AppColors.add,
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.teacherStatistics),
                  ),
                ],
              ),
            );
          },
        ),
      ),
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

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.brain,
                  size: 64,
                  color: Colors.white,
                ),
                SizedBox(height: AppTheme.smallSpacing),
                Text(
                  AppConstants.appName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(LucideIcons.home),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(LucideIcons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed(AppRoutes.settings);
            },
          ),
          ListTile(
            leading: const Icon(LucideIcons.info),
            title: const Text('About'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed(AppRoutes.about);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(LucideIcons.logOut, color: AppColors.logout),
            title: const Text('Logout', style: TextStyle(color: AppColors.logout)),
            onTap: () {
              Navigator.pop(context);
              _logout();
            },
          ),
        ],
      ),
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

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.cardPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: AppTheme.smallSpacing),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(label),
        trailing: const Icon(LucideIcons.chevronRight),
        onTap: onTap,
      ),
    );
  }
}
