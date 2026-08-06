import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../models/user.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/permissions/permission_manager.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/confirmation/confirmation.dart';
import '../../services/service_locator.dart';
import '../../widgets/role_guard.dart';
import '../../widgets/permission_guard.dart';
import '../../widgets/enhanced_cards.dart';
import '../../widgets/navigation_scaffold.dart';
import '../../widgets/modal_bottom_sheet.dart';

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
    final action = student.isActive ? 'deactivate' : 'activate';
    final confirmed = await ConfirmationDialogs.confirmSensitive(
      context,
      action: action,
      message: 'Are you sure you want to $action "${student.fullName}"?',
    );

    if (confirmed) {
      final updated = student.copyWith(isActive: !student.isActive);
      await _db.updateUser(updated);
      _load();
    }
  }

  Future<void> _delete(User student) async {
    final confirmed = await ConfirmationDialogs.confirmDestructive(
      context,
      itemName: student.fullName,
      action: 'delete',
    );

    if (confirmed) {
      await _db.deleteUser(student.id!);
      _load();
    }
  }

  List<User> _filter(List<User> students) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return students;
    return students.where((s) => s.fullName.toLowerCase().contains(query) || s.username.toLowerCase().contains(query)).toList();
  }

  void _showAddStudentModal(BuildContext context) {
    final nameController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ModalBottomSheet(
        title: 'Add New Student',
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty ||
                  usernameController.text.trim().isEmpty ||
                  passwordController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill in all fields')),
                );
                return;
              }

              final student = User(
                fullName: nameController.text.trim(),
                username: usernameController.text.trim(),
                password: passwordController.text.trim(),
                role: AppConstants.roleStudent,
                isActive: true,
              );

              await _db.insertUser(student);
              if (!mounted) return;
              if (!context.mounted) return;
              Navigator.pop(context);
              _load();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Student added successfully')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.add,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add Student'),
          ),
        ],
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              hintText: 'Enter student name',
              filled: true,
              prefixIcon: Icon(LucideIcons.user),
            ),
          ),
          const SizedBox(height: _mediumSpacing),
          TextField(
            controller: usernameController,
            decoration: const InputDecoration(
              labelText: 'Username',
              hintText: 'Enter username',
              filled: true,
              prefixIcon: Icon(LucideIcons.atSign),
            ),
          ),
          const SizedBox(height: _mediumSpacing),
          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              hintText: 'Enter password',
              filled: true,
              prefixIcon: Icon(LucideIcons.lock),
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickEditModal(BuildContext context, User student) {
    final nameController = TextEditingController(text: student.fullName);
    final usernameController = TextEditingController(text: student.username);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ModalBottomSheet(
        title: 'Quick Edit',
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final updated = student.copyWith(
                fullName: nameController.text.trim(),
                username: usernameController.text.trim(),
              );

              await _db.updateUser(updated);
              if (!mounted) return;
              if (!context.mounted) return;
              Navigator.pop(context);
              _load();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Student updated successfully')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.edit,
              foregroundColor: Colors.white,
            ),
            child: const Text('Update'),
          ),
        ],
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              filled: true,
              prefixIcon: Icon(LucideIcons.user),
            ),
          ),
          const SizedBox(height: _mediumSpacing),
          TextField(
            controller: usernameController,
            decoration: const InputDecoration(
              labelText: 'Username',
              filled: true,
              prefixIcon: Icon(LucideIcons.atSign),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRole: AppConstants.roleTeacher,
      child: NavigationScaffold(
        title: 'Manage Students',
        currentRoute: AppRoutes.studentManagement,
        actions: [
          PermissionGuard(
            permission: AppPermissions.createUsers,
            child: IconButton(
              icon: const Icon(LucideIcons.userPlus, color: AppColors.add),
              onPressed: () => _showAddStudentModal(context),
              tooltip: 'Add Student',
            ),
          ),
        ],
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
                                size: 18,
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
                                icon: const Icon(LucideIcons.edit, color: AppColors.edit, size: 18),
                                onPressed: () => _showQuickEditModal(context, s),
                                tooltip: 'Quick Edit',
                              ),
                            ),
                            PermissionGuard(
                              permission: AppPermissions.deleteUsers,
                              child: IconButton(
                                icon: const Icon(LucideIcons.trash2, color: AppColors.delete, size: 18),
                                onPressed: () => _delete(s),
                                tooltip: 'Delete',
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}