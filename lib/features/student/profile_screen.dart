import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user.dart';
import '../../services/service_locator.dart';
import '../../widgets/role_guard.dart';
import '../../widgets/enhanced_navigation.dart';

/// Student profile screen for editing own details and password.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  User? _user;
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  static const double _smallSpacing = AppTheme.spacing2;
  static const double _mediumSpacing = AppTheme.spacing4;
  static const double _largeSpacing = AppTheme.spacing6;
  static const double _cardPadding = AppTheme.spacing6;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final auth = await ServiceLocator.auth;
    final user = await auth.getCurrentUser();
    if (user == null) return;
    setState(() {
      _user = user;
      _fullNameController.text = user.fullName;
      _usernameController.text = user.username;
    });
  }

  Future<void> _updateProfile() async {
    if (_user == null) return;

    final fullName = _fullNameController.text.trim();
    final username = _usernameController.text.trim();

    if (fullName.isEmpty || username.isEmpty) {
      _showMessage('Full name and username are required.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final existing = await ServiceLocator.db.getUserByUsername(username);
      if (existing != null && existing.id != _user!.id) {
        if (!mounted) return;
        _showMessage('Username is already taken.');
        return;
      }

      final updated = _user!.copyWith(fullName: fullName, username: username);
      await ServiceLocator.db.updateUser(updated);
      _user = updated;
      if (!mounted) return;
      _showMessage('Profile updated successfully.');
    } catch (e) {
      _showMessage('Failed to update profile.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePassword() async {
    if (_user == null) return;

    final oldPassword = _oldPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword.isEmpty) {
      _showMessage('New password cannot be empty.');
      return;
    }
    if (newPassword != confirmPassword) {
      _showMessage('New passwords do not match.');
      return;
    }
    if (_user!.password != oldPassword) {
      _showMessage('Old password is incorrect.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final updated = _user!.copyWith(password: newPassword);
      await ServiceLocator.db.updateUser(updated);
      _user = updated;
      _oldPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      if (!mounted) return;
      _showMessage('Password updated successfully.');
    } catch (e) {
      _showMessage('Failed to update password.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRole: AppConstants.roleStudent,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Profile'),
          elevation: 0,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(LucideIcons.brain),
              onPressed: () => Scaffold.of(context).openDrawer(),
              tooltip: 'Open menu',
            ),
          ),
        ),
        drawer: EnhancedDrawer(
          currentRoute: AppRoutes.profile,
          onLogout: _logout,
        ),
        body: _user == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(_mediumSpacing),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileHeader(context),
                    const SizedBox(height: _largeSpacing),
                    _buildProfileCard(context),
                    const SizedBox(height: _largeSpacing),
                    _buildPasswordCard(context),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: const Icon(LucideIcons.user, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: _smallSpacing),
          Text(
            _user!.fullName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            '@${_user!.username}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(_cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Profile Details', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: _mediumSpacing),
            TextField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(LucideIcons.user),
              ),
            ),
            const SizedBox(height: _mediumSpacing),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(LucideIcons.atSign),
              ),
            ),
            const SizedBox(height: _mediumSpacing),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _updateProfile,
                icon: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(LucideIcons.save),
                label: const Text('Update Profile'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.edit, foregroundColor: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(_cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Change Password', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: _mediumSpacing),
            TextField(
              controller: _oldPasswordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Old Password',
                prefixIcon: const Icon(LucideIcons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_isPasswordVisible ? LucideIcons.eyeOff : LucideIcons.eye),
                  onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
              ),
            ),
            const SizedBox(height: _mediumSpacing),
            TextField(
              controller: _newPasswordController,
              obscureText: !_isPasswordVisible,
              decoration: const InputDecoration(
                labelText: 'New Password',
                prefixIcon: Icon(LucideIcons.key),
              ),
            ),
            const SizedBox(height: _mediumSpacing),
            TextField(
              controller: _confirmPasswordController,
              obscureText: !_isPasswordVisible,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                prefixIcon: Icon(LucideIcons.key),
              ),
            ),
            const SizedBox(height: _mediumSpacing),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _updatePassword,
                icon: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(LucideIcons.save),
                label: const Text('Update Password'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.add, foregroundColor: Colors.white),
              ),
            ),
          ],
        ),
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
    _fullNameController.dispose();
    _usernameController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
