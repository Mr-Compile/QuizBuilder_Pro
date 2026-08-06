import 'package:flutter/material.dart';
import '../core/permissions/permission_manager.dart';
import '../services/service_locator.dart';

/// Widget that conditionally renders based on user permissions
class PermissionGuard extends StatelessWidget {
  final Widget child;
  final String permission;
  final Widget? fallback;

  const PermissionGuard({
    super.key,
    required this.child,
    required this.permission,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final role = snapshot.data;
        if (role == null) {
          return fallback ?? const SizedBox.shrink();
        }

        final hasPermission = RolePermissions.hasPermission(role, permission);
        return hasPermission ? child : (fallback ?? const SizedBox.shrink());
      },
    );
  }

  Future<String?> _getUserRole() async {
    final auth = await ServiceLocator.auth;
    final user = await auth.getCurrentUser();
    return user?.role;
  }
}

/// Widget that shows/hides based on multiple permissions (AND logic)
class AllPermissionsGuard extends StatelessWidget {
  final Widget child;
  final List<String> permissions;
  final Widget? fallback;

  const AllPermissionsGuard({
    super.key,
    required this.child,
    required this.permissions,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final role = snapshot.data;
        if (role == null) {
          return fallback ?? const SizedBox.shrink();
        }

        final hasAllPermissions = permissions.every(
          (permission) => RolePermissions.hasPermission(role, permission),
        );
        return hasAllPermissions ? child : (fallback ?? const SizedBox.shrink());
      },
    );
  }

  Future<String?> _getUserRole() async {
    final auth = await ServiceLocator.auth;
    final user = await auth.getCurrentUser();
    return user?.role;
  }
}

/// Widget that shows/hides based on multiple permissions (OR logic)
class AnyPermissionGuard extends StatelessWidget {
  final Widget child;
  final List<String> permissions;
  final Widget? fallback;

  const AnyPermissionGuard({
    super.key,
    required this.child,
    required this.permissions,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final role = snapshot.data;
        if (role == null) {
          return fallback ?? const SizedBox.shrink();
        }

        final hasAnyPermission = permissions.any(
          (permission) => RolePermissions.hasPermission(role, permission),
        );
        return hasAnyPermission ? child : (fallback ?? const SizedBox.shrink());
      },
    );
  }

  Future<String?> _getUserRole() async {
    final auth = await ServiceLocator.auth;
    final user = await auth.getCurrentUser();
    return user?.role;
  }
}