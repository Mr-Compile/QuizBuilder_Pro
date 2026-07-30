import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user.dart';
import '../../services/service_locator.dart';
import '../../widgets/role_guard.dart';

/// Student dashboard with quick access to topics, history and statistics.
class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final _db = ServiceLocator.db;
  User? _user;
  late Future<int> _attemptsFuture;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _attemptsFuture = _db.countResults();
  }

  Future<void> _loadUser() async {
    final auth = await ServiceLocator.auth;
    final user = await auth.getCurrentUser();
    setState(() => _user = user);
  }

  Future<void> _logout() async {
    final auth = await ServiceLocator.auth;
    await auth.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
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

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRole: AppConstants.roleStudent,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Student Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.logOut, color: AppColors.logout),
              onPressed: _logout,
              tooltip: 'Logout',
            ),
          ],
        ),
        drawer: _buildDrawer(context),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.mediumSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, ${_user?.fullName ?? 'Student'}!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppTheme.smallSpacing),
              Text(
                'Choose a topic and difficulty to start practicing.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppTheme.largeSpacing),
              FutureBuilder(
                future: _attemptsFuture,
                builder: (context, snapshot) {
                  final attempts = snapshot.data ?? 0;
                  return _QuickAction(
                    icon: LucideIcons.clipboardList,
                    label: 'Quizzes Taken',
                    value: attempts.toString(),
                    color: AppColors.primary,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.history),
                  );
                },
              ),
              const SizedBox(height: AppTheme.largeSpacing),
              Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppTheme.smallSpacing),
              _QuickAction(
                icon: LucideIcons.bookOpen,
                label: 'Browse Topics',
                color: AppColors.secondary,
                onTap: () => Navigator.pushNamed(context, AppRoutes.topicSelect),
              ),
              _QuickAction(
                icon: LucideIcons.history,
                label: 'My History',
                color: AppColors.edit,
                onTap: () => Navigator.pushNamed(context, AppRoutes.history),
              ),
              _QuickAction(
                icon: LucideIcons.barChart2,
                label: 'My Statistics',
                color: AppColors.add,
                onTap: () => Navigator.pushNamed(context, AppRoutes.studentStatistics),
              ),
              _QuickAction(
                icon: LucideIcons.settings,
                label: 'Settings',
                color: AppColors.cancel,
                onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
              ),
            ],
          ),
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
  final String? value;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.value,
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
        trailing: value != null
            ? Text(
                value!,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color),
              )
            : const Icon(LucideIcons.chevronRight),
        onTap: onTap,
      ),
    );
  }
}
