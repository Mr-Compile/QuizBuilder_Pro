import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../models/user.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../services/service_locator.dart';
import '../../widgets/role_guard.dart';

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
        content: Text('Delete "${student.fullName}" permanently?'),
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
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.userPlus, color: AppColors.add),
              onPressed: () async {
                await Navigator.pushNamed(context, AppRoutes.studentForm);
                _load();
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppTheme.mediumSpacing),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search students...',
                  prefixIcon: const Icon(LucideIcons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(LucideIcons.x),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            Expanded(
              child: FutureBuilder(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final students = _filter(snapshot.data ?? []);

                  if (students.isEmpty) {
                    return const Center(child: Text('No students found.'));
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      _load();
                    },
                    child: ListView.builder(
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final s = students[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: s.isActive ? AppColors.add : AppColors.cancel,
                              child: Icon(
                                s.isActive ? LucideIcons.userCheck : LucideIcons.userX,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(s.fullName),
                            subtitle: Text('@${s.username}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Switch(
                                  value: s.isActive,
                                  onChanged: (_) => _toggleActive(s),
                                  activeThumbColor: AppColors.add,
                                ),
                                IconButton(
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
                                IconButton(
                                  icon: const Icon(LucideIcons.trash2, color: AppColors.delete),
                                  onPressed: () => _delete(s),
                                ),
                              ],
                            ),
                          ),
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
