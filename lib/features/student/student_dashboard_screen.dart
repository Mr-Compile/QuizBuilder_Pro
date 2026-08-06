import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user.dart';
import '../../services/service_locator.dart';
import '../../widgets/role_guard.dart';
import '../../widgets/enhanced_cards.dart';
import '../../widgets/enhanced_navigation.dart';

// Spacing constants for better readability
const double _smallSpacing = AppTheme.spacing2;
const double _mediumSpacing = AppTheme.spacing4;
const double _largeSpacing = AppTheme.spacing6;

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

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRole: AppConstants.roleStudent,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Student Dashboard'),
          elevation: 0,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(LucideIcons.brain),
              onPressed: () => Scaffold.of(context).openDrawer(),
              tooltip: 'Open menu',
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.logOut, color: AppColors.logout),
              onPressed: _logout,
              tooltip: 'Logout',
            ),
          ],
        ),
        drawer: EnhancedDrawer(
          currentRoute: AppRoutes.studentDashboard,
          onLogout: _logout,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(_mediumSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: _largeSpacing),
              _buildStatsCard(context),
              const SizedBox(height: _largeSpacing),
              _buildQuickActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome, ${_user?.fullName ?? 'Student'}!',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Ready to learn? Choose a topic and start practicing.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
      ],
    );
  }

  Widget _buildStatsCard(BuildContext context) {
    return FutureBuilder(
      future: _attemptsFuture,
      builder: (context, snapshot) {
        final attempts = snapshot.data ?? 0;
        return EnhancedSummaryCard(
          label: 'Quizzes Completed',
          value: attempts.toString(),
          icon: LucideIcons.clipboardList,
          color: AppColors.primary,
          onTap: () => Navigator.pushNamed(context, AppRoutes.history),
        );
      },
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
          icon: LucideIcons.bookOpen,
          label: 'Browse Topics',
          subtitle: 'Explore available quiz topics',
          color: AppColors.secondary,
          onTap: () => Navigator.pushNamed(context, AppRoutes.topicSelect),
        ),
        const SizedBox(height: _smallSpacing),
        EnhancedActionCard(
          icon: LucideIcons.history,
          label: 'My History',
          subtitle: 'View past quiz results',
          color: AppColors.edit,
          onTap: () => Navigator.pushNamed(context, AppRoutes.history),
        ),
        const SizedBox(height: _smallSpacing),
        EnhancedActionCard(
          icon: LucideIcons.barChart2,
          label: 'My Statistics',
          subtitle: 'Track your learning progress',
          color: AppColors.add,
          onTap: () => Navigator.pushNamed(context, AppRoutes.studentStatistics),
        ),
        const SizedBox(height: _smallSpacing),
        EnhancedActionCard(
          icon: LucideIcons.bookX,
          label: 'Review Mistakes',
          subtitle: 'Practice questions you got wrong',
          color: AppColors.delete,
          onTap: () => Navigator.pushNamed(context, AppRoutes.reviewWrongAnswers),
        ),
        const SizedBox(height: _smallSpacing),
        EnhancedActionCard(
          icon: LucideIcons.user,
          label: 'My Profile',
          subtitle: 'Update your name or password',
          color: AppColors.accent,
          onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
        ),
        const SizedBox(height: _smallSpacing),
        EnhancedActionCard(
          icon: LucideIcons.settings,
          label: 'Settings',
          subtitle: 'Customize your experience',
          color: AppColors.cancel,
          onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
        ),
      ],
    );
  }
}