import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/app_colors.dart';
import '../core/routes/app_routes.dart';
import '../core/theme/app_theme.dart';
import '../services/service_locator.dart';

// Spacing constants for better readability
const double _smallSpacing = AppTheme.spacing2;
const double _mediumSpacing = AppTheme.spacing4;

/// Enhanced app drawer with role-based navigation items
class EnhancedDrawer extends StatelessWidget {
  final String currentRoute;
  final VoidCallback? onLogout;

  const EnhancedDrawer({
    super.key,
    required this.currentRoute,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
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
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.brain,
            size: 64,
            color: Colors.white,
          ),
          SizedBox(height: _smallSpacing),
          Text(
            AppConstants.appName,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            AppConstants.appTagline,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(_mediumSpacing),
          child: Text(
            'Teacher Tools',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        _buildNavItem(
          context,
          icon: LucideIcons.layoutDashboard,
          label: 'Dashboard',
          route: AppRoutes.teacherDashboard,
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
        _buildNavItem(
          context,
          icon: LucideIcons.wand2,
          label: 'AI Generator',
          route: AppRoutes.aiGenerate,
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
      ],
    );
  }

  Widget _buildStudentSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(_mediumSpacing),
          child: Text(
            'Learning',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        _buildNavItem(
          context,
          icon: LucideIcons.layoutDashboard,
          label: 'Dashboard',
          route: AppRoutes.studentDashboard,
        ),
        _buildNavItem(
          context,
          icon: LucideIcons.bookOpen,
          label: 'Browse Topics',
          route: AppRoutes.topicSelect,
        ),
        _buildNavItem(
          context,
          icon: LucideIcons.history,
          label: 'History',
          route: AppRoutes.history,
        ),
        _buildNavItem(
          context,
          icon: LucideIcons.barChart2,
          label: 'Statistics',
          route: AppRoutes.studentStatistics,
        ),
      ],
    );
  }

  Widget _buildCommonSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(_mediumSpacing),
          child: Text(
            'General',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        _buildNavItem(
          context,
          icon: LucideIcons.settings,
          label: 'Settings',
          route: AppRoutes.settings,
        ),
        _buildNavItem(
          context,
          icon: LucideIcons.info,
          label: 'About',
          route: AppRoutes.about,
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
        onLogout?.call();
      },
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
  }) {
    final isSelected = currentRoute == route;
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
        if (currentRoute != route) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
    );
  }

  Future<String?> _getUserRole() async {
    final auth = await ServiceLocator.auth;
    final user = await auth.getCurrentUser();
    return user?.role;
  }
}

/// Enhanced bottom navigation bar for quick access
class EnhancedBottomNav extends StatelessWidget {
  final String currentRoute;
  final String userRole;

  const EnhancedBottomNav({
    super.key,
    required this.currentRoute,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    final destinations = userRole == AppConstants.roleTeacher
        ? _teacherDestinations()
        : _studentDestinations();

    return NavigationBar(
      destinations: destinations.map((d) => NavigationDestination(
        icon: Icon(d.icon),
        label: d.label,
      )).toList(),
      selectedIndex: _getSelectedIndex(destinations),
      onDestinationSelected: (index) {
        final destination = destinations[index];
        if (currentRoute != destination.route) {
          Navigator.pushReplacementNamed(context, destination.route);
        }
      },
    );
  }

  int _getSelectedIndex(List<_NavDestination> destinations) {
    return destinations.indexWhere((d) => d.route == currentRoute);
  }

  List<_NavDestination> _teacherDestinations() {
    return [
      _NavDestination(
        icon: LucideIcons.layoutDashboard,
        label: 'Dashboard',
        route: AppRoutes.teacherDashboard,
      ),
      _NavDestination(
        icon: LucideIcons.bookOpen,
        label: 'Topics',
        route: AppRoutes.topicManagement,
      ),
      _NavDestination(
        icon: LucideIcons.helpCircle,
        label: 'Questions',
        route: AppRoutes.questionManagement,
      ),
      _NavDestination(
        icon: LucideIcons.barChart2,
        label: 'Results',
        route: AppRoutes.results,
      ),
    ];
  }

  List<_NavDestination> _studentDestinations() {
    return [
      _NavDestination(
        icon: LucideIcons.layoutDashboard,
        label: 'Dashboard',
        route: AppRoutes.studentDashboard,
      ),
      _NavDestination(
        icon: LucideIcons.bookOpen,
        label: 'Topics',
        route: AppRoutes.topicSelect,
      ),
      _NavDestination(
        icon: LucideIcons.history,
        label: 'History',
        route: AppRoutes.history,
      ),
      _NavDestination(
        icon: LucideIcons.barChart2,
        label: 'Stats',
        route: AppRoutes.studentStatistics,
      ),
    ];
  }
}

class _NavDestination {
  final IconData icon;
  final String label;
  final String route;

  _NavDestination({
    required this.icon,
    required this.label,
    required this.route,
  });
}