import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../core/routes/app_routes.dart';
import '../core/theme/app_theme.dart';
import '../services/service_locator.dart';

/// Navigation scaffold that provides consistent navigation behavior across the app.
/// 
/// Features:
/// - Automatic back button for secondary screens
/// - Menu icon for dashboard screens
/// - Sidebar/drawer with role-based navigation
/// - Active menu highlighting
/// - Prevention of duplicate screens in navigation stack
/// - Consistent AppBar behavior
class NavigationScaffold extends StatefulWidget {
  final String title;
  final Widget body;
  final String currentRoute;
  final List<Widget>? actions;
  final bool showDrawer;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool isDashboard;

  const NavigationScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.currentRoute,
    this.actions,
    this.showDrawer = true,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.isDashboard = false,
  });

  @override
  State<NavigationScaffold> createState() => _NavigationScaffoldState();
}

class _NavigationScaffoldState extends State<NavigationScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: _buildAppBar(context),
      drawer: widget.showDrawer ? _buildDrawer(context) : null,
      body: widget.body,
      floatingActionButton: widget.floatingActionButton,
      bottomNavigationBar: widget.bottomNavigationBar,
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(widget.title),
      elevation: 0,
      leading: widget.isDashboard
          ? Builder(
              builder: (context) => IconButton(
                icon: const Icon(LucideIcons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
                tooltip: 'Open menu',
              ),
            )
          : null,
      actions: widget.actions,
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getUserRole(),
      builder: (context, snapshot) {
        final role = snapshot.data;
        return Drawer(
          child: Column(
            children: [
              _buildDrawerHeader(context),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    if (role == AppConstants.roleTeacher) ...[
                      _buildTeacherSection(context),
                      const Divider(),
                    ],
                    if (role == AppConstants.roleStudent) ...[
                      _buildStudentSection(context),
                      const Divider(),
                    ],
                    _buildCommonSection(context),
                    const Divider(),
                    _buildSettingsSection(context),
                    const Divider(),
                    _buildLogoutSection(context),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return DrawerHeader(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final iconSize = constraints.maxWidth < 280 ? 48.0 : 64.0;
          final titleSize = constraints.maxWidth < 280 ? 20.0 : 24.0;
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.brain,
                size: iconSize,
                color: Colors.white,
              ),
              const SizedBox(height: AppTheme.spacing2),
              Text(
                AppConstants.appName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              const Text(
                AppConstants.appTagline,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTeacherSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppTheme.spacing4),
          child: Text(
            'Overview',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
          ),
        ),
        _buildNavItem(
          context,
          icon: LucideIcons.layoutDashboard,
          label: 'Dashboard',
          route: AppRoutes.teacherDashboard,
          isDashboard: true,
        ),
        _buildNavItem(
          context,
          icon: LucideIcons.user,
          label: 'Profile',
          route: AppRoutes.teacherProfile,
        ),
        Padding(
          padding: const EdgeInsets.all(AppTheme.spacing4),
          child: Text(
            'Management',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
          ),
        ),
        _buildNavItem(
          context,
          icon: LucideIcons.users,
          label: 'Students',
          route: AppRoutes.studentManagement,
        ),
        _buildNavItem(
          context,
          icon: LucideIcons.bookOpen,
          label: 'Topics',
          route: AppRoutes.topicManagement,
        ),
        _buildNavItem(
          context,
          icon: LucideIcons.helpCircle,
          label: 'Questions',
          route: AppRoutes.questionManagement,
        ),
        Padding(
          padding: const EdgeInsets.all(AppTheme.spacing4),
          child: Text(
            'Analytics',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
          ),
        ),
        _buildNavItem(
          context,
          icon: LucideIcons.clipboardList,
          label: 'Results',
          route: AppRoutes.results,
        ),
        _buildNavItem(
          context,
          icon: LucideIcons.barChart2,
          label: 'Statistics',
          route: AppRoutes.teacherStatistics,
        ),
        Padding(
          padding: const EdgeInsets.all(AppTheme.spacing4),
          child: Text(
            'AI Tools',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
          ),
        ),
        _buildNavItem(
          context,
          icon: LucideIcons.wand2,
          label: 'AI Generate',
          route: AppRoutes.aiGenerate,
        ),
      ],
    );
  }

  Widget _buildStudentSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppTheme.spacing4),
          child: Text(
            'Learning',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
          ),
        ),
        _buildNavItem(
          context,
          icon: LucideIcons.layoutDashboard,
          label: 'Dashboard',
          route: AppRoutes.studentDashboard,
          isDashboard: true,
        ),
        _buildNavItem(
          context,
          icon: LucideIcons.playCircle,
          label: 'Start Quiz',
          route: AppRoutes.topicSelect,
        ),
        _buildNavItem(
          context,
          icon: LucideIcons.history,
          label: 'Quiz History',
          route: AppRoutes.history,
        ),
        _buildNavItem(
          context,
          icon: LucideIcons.barChart2,
          label: 'My Statistics',
          route: AppRoutes.studentStatistics,
        ),
        _buildNavItem(
          context,
          icon: LucideIcons.bookX,
          label: 'Review Mistakes',
          route: AppRoutes.reviewWrongAnswers,
        ),
      ],
    );
  }

  Widget _buildCommonSection(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getUserRole(),
      builder: (context, snapshot) {
        final role = snapshot.data;
        final profileRoute = role == AppConstants.roleTeacher 
            ? AppRoutes.teacherProfile 
            : AppRoutes.profile;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacing4),
              child: Text(
                'General',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
              ),
            ),
            _buildNavItem(
              context,
              icon: LucideIcons.user,
              label: 'Profile',
              route: profileRoute,
            ),
            _buildNavItem(
              context,
              icon: LucideIcons.info,
              label: 'About',
              route: AppRoutes.about,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppTheme.spacing4),
          child: Text(
            'System',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
          ),
        ),
        _buildNavItem(
          context,
          icon: LucideIcons.settings,
          label: 'Settings',
          route: AppRoutes.settings,
        ),
      ],
    );
  }

  Widget _buildLogoutSection(BuildContext context) {
    return ListTile(
      leading: const Icon(LucideIcons.logOut, color: AppColors.logout),
      title: const Text('Logout', style: TextStyle(color: AppColors.logout)),
      onTap: () {
        Navigator.pop(context);
        _logout();
      },
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    bool isDashboard = false,
  }) {
    final isSelected = widget.currentRoute == route;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? Theme.of(context).colorScheme.primary : null,
          fontWeight: isSelected ? FontWeight.bold : null,
        ),
      ),
      selected: isSelected,
      onTap: () {
        Navigator.pop(context);
        _navigateToRoute(context, route, isDashboard);
      },
    );
  }

  void _navigateToRoute(BuildContext context, String route, bool isDashboard) {
    // If already on the target route, do nothing
    if (widget.currentRoute == route) {
      return;
    }

    // Navigate without pushing duplicates
    Navigator.pushNamedAndRemoveUntil(
      context,
      route,
      (route) => false,
    );
  }

  Future<void> _logout() async {
    final auth = await ServiceLocator.auth;
    final user = await auth.getCurrentUser();
    final quizSession = await ServiceLocator.quizSession;

    // Block logout for students during active quiz
    if (user?.role == AppConstants.roleStudent && quizSession.quizInProgress) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cannot Logout'),
          content: const Text('Finish the quiz before logging out.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Show logout confirmation for non-blocked cases
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.delete, foregroundColor: Colors.white),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await auth.logout();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => false,
      );
    }
  }

  Future<String?> _getUserRole() async {
    final auth = await ServiceLocator.auth;
    final user = await auth.getCurrentUser();
    return user?.role;
  }
}
