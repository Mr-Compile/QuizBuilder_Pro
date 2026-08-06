import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../models/user.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/permissions/permission_manager.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../services/service_locator.dart';
import '../../widgets/role_guard.dart';
import '../../widgets/permission_guard.dart';
import '../../widgets/enhanced_cards.dart';
import '../../widgets/enhanced_navigation.dart';

// Spacing constants for better readability
const double _smallSpacing = AppTheme.spacing2;
const double _mediumSpacing = AppTheme.spacing4;

/// Screen for the teacher to create, edit, activate and delete students.
class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final _db = ServiceLocator.db;
  final _searchController = TextEditingController();
  late Future<List<User>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = _db.getAllStudents();
    setState(() {});
  }

  Future<void> _toggleActive(User student) async {
    final updated = student.copyWith(isActive: !student.isActive);
    await _db.updateUser(updated);
    _load();
  }

  Future<void> _delete(User student) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text('Delete "${student.fullName}" permanently? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.delete, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _db.deleteUser(student.id!);
      _load();
    }
  }

  List<User> _filter(List<User> students) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return students;
    return students.where((s) => s.fullName.toLowerCase().contains(query) || s.username.toLowerCase().contains(query)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRole: AppConstants.roleTeacher,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Students'),
          elevation: 0,
          actions: [
            PermissionGuard(
              permission: AppPermissions.createUsers,
              child: IconButton(
                icon: const Icon(LucideIcons.userPlus, color: AppColors.add),
                onPressed: () async {
                  await Navigator.pushNamed(context, AppRoutes.studentForm);
                  _load();
                },
                tooltip: 'Add Student',
              ),
            ),
          ],
        ),
        drawer: EnhancedDrawer(
          currentRoute: AppRoutes.studentManagement,
          onLogout: _logout,
        ),
        body: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: FutureBuilder(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final students = _filter(snapshot.data ?? []);

                  if (students.isEmpty) {
                    return _buildEmptyState();
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      _load();
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: _smallSpacing),
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final s = students[index];
                        return EnhancedListItem(
                          title: s.fullName,
                          subtitle: '@${s.username}',
                          leading: InkWell(
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.studentDetail,
                              arguments: {'student': s},
                            ),
                            child: CircleAvatar(
                              backgroundColor: s.isActive ? AppColors.add : AppColors.cancel,
                              child: Icon(
                                s.isActive ? LucideIcons.userCheck : LucideIcons.userX,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          trailing: [
                            PermissionGuard(
                              permission: AppPermissions.activateUsers,
                              child: Switch(
                                value: s.isActive,
                                onChanged: (_) => _toggleActive(s),
                                activeThumbColor: AppColors.add,
                              ),
                            ),
                            PermissionGuard(
                              permission: AppPermissions.editUsers,
                              child: IconButton(
                                icon: const Icon(LucideIcons.edit, color: AppColors.edit),
                                onPressed: () async {
                                  await Navigator.pushNamed(
                                    context,
                                    AppRoutes.studentForm,
                                    arguments: {'user': s},
                                  );
                                  _load();
                                },
                              ),
                            ),
                            PermissionGuard(
                              permission: AppPermissions.deleteUsers,
                              child: IconButton(
                                icon: const Icon(LucideIcons.trash2, color: AppColors.delete),
                                onPressed: () => _delete(s),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(_mediumSpacing),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search students by name or username...',
          prefixIcon: const Icon(LucideIcons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(LucideIcons.x),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.users,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: _mediumSpacing),
          Text(
            'No students found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: _smallSpacing),
          Text(
            'Try adjusting your search or add a new student',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final auth = await ServiceLocator.auth;
    await auth.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}