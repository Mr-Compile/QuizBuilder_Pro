import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/permissions/permission_manager.dart';
import '../core/routes/app_routes.dart';
import '../services/service_locator.dart';

/// Wraps a screen and redirects the user if their role is not allowed.
/// Enhanced version that supports both role-based and permission-based access control.
class RoleGuard extends StatefulWidget {
  final Widget child;
  final String? allowedRole;
  final String? requiredPermission;

  const RoleGuard({
    super.key,
    required this.child,
    this.allowedRole,
    this.requiredPermission,
  }) : assert(allowedRole != null || requiredPermission != null,
            'Either allowedRole or requiredPermission must be provided');

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

    if (user == null) {
      _redirectToLogin();
      return;
    }

    bool hasAccess = false;

    // Check role-based access
    if (widget.allowedRole != null) {
      hasAccess = user.role == widget.allowedRole;
    }

    // Check permission-based access
    if (widget.requiredPermission != null) {
      hasAccess = RolePermissions.hasPermission(user.role, widget.requiredPermission!);
    }

    if (!hasAccess && mounted) {
      final route = user.role == AppConstants.roleTeacher
          ? AppRoutes.teacherDashboard
          : AppRoutes.studentDashboard;
      // Wait one frame so the build is not in progress.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(route);
      });
    }
  }

  void _redirectToLogin() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
