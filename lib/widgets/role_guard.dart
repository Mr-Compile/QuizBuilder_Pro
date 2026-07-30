import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/routes/app_routes.dart';
import '../services/service_locator.dart';

/// Wraps a screen and redirects the user if their role is not allowed.
class RoleGuard extends StatefulWidget {
  final Widget child;
  final String allowedRole;

  const RoleGuard({super.key, required this.child, required this.allowedRole});

  @override
  State<RoleGuard> createState() => _RoleGuardState();
}

class _RoleGuardState extends State<RoleGuard> {
  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    final auth = await ServiceLocator.auth;
    final user = await auth.getCurrentUser();

    if (user == null || user.role != widget.allowedRole) {
      if (!mounted) return;
      final route = user?.role == AppConstants.roleTeacher
          ? AppRoutes.teacherDashboard
          : AppRoutes.studentDashboard;
      // Wait one frame so the build is not in progress.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(route);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
