import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/validation/validators.dart';
import '../../models/user.dart';
import '../../services/service_locator.dart';
import '../../widgets/role_guard.dart';
import '../../widgets/navigation_scaffold.dart';
import '../../core/routes/app_routes.dart';

/// Create or edit a student account.
class StudentFormScreen extends StatefulWidget {
  final User? user;

  const StudentFormScreen({super.key, this.user});

  @override
  State<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends State<StudentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _db = ServiceLocator.db;

  bool _isActive = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _fullNameController.text = widget.user!.fullName;
      _usernameController.text = widget.user!.username;
      _passwordController.text = widget.user!.password;
      _isActive = widget.user!.isActive;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final username = _usernameController.text.trim();
      final existing = await _db.getUserByUsername(username);

      if (existing != null && (widget.user == null || existing.id != widget.user!.id)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username is already taken.'), backgroundColor: Colors.red),
        );
        return;
      }

      final user = User(
        id: widget.user?.id,
        fullName: _fullNameController.text.trim(),
        username: username,
        password: _passwordController.text,
        role: AppConstants.roleStudent,
        isActive: _isActive,
      );

      if (widget.user == null) {
        await _db.insertUser(user);
      } else {
        await _db.updateUser(user);
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save student: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.user != null;

    return RoleGuard(
      allowedRole: AppConstants.roleTeacher,
      child: NavigationScaffold(
        title: isEdit ? 'Edit Student' : 'Add Student',
        currentRoute: AppRoutes.studentForm,
        showDrawer: false,
        body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: AppTheme.mediumSpacing,
          right: AppTheme.mediumSpacing,
          top: AppTheme.mediumSpacing,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.mediumSpacing,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(LucideIcons.user),
                ),
                validator: Validators.compose([
                  (value) => Validators.required(value),
                  (value) => Validators.lettersOnly(value),
                  (value) => Validators.minLength(value, 2, fieldName: 'Full name'),
                  (value) => Validators.maxLength(value, 50, fieldName: 'Full name'),
                ]),
              ),
              const SizedBox(height: AppTheme.mediumSpacing),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(LucideIcons.atSign),
                ),
                validator: Validators.username,
              ),
              const SizedBox(height: AppTheme.mediumSpacing),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(LucideIcons.lock),
                ),
                validator: Validators.compose([
                  (value) => Validators.required(value),
                  (value) => Validators.password(value),
                  (value) => Validators.maxLength(value, 50, fieldName: 'Password'),
                ]),
              ),
              const SizedBox(height: AppTheme.mediumSpacing),
              SwitchListTile(
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
                title: const Text('Active'),
                secondary: Icon(_isActive ? LucideIcons.userCheck : LucideIcons.userX),
              ),
              const SizedBox(height: AppTheme.largeSpacing),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(LucideIcons.x),
                      label: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppTheme.mediumSpacing),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _save,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(LucideIcons.save),
                      label: const Text('Save'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.add,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
