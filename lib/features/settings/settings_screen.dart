import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user.dart';
import '../../services/groq_ai_service.dart';
import '../../services/service_locator.dart';
import '../../widgets/enhanced_navigation.dart';

/// Settings screen with theme toggle, password change and API key management.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _apiKeyController = TextEditingController();

  User? _user;
  late Future<GroqAiService> _groqFuture;
  bool _isTeacher = false;

  static const double _smallSpacing = AppTheme.spacing2;
  static const double _mediumSpacing = AppTheme.spacing4;
  static const double _largeSpacing = AppTheme.spacing6;
  static const double _cardPadding = AppTheme.spacing6;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _groqFuture = ServiceLocator.groq;
    _loadApiKey();
  }

  Future<void> _loadUser() async {
    final auth = await ServiceLocator.auth;
    final user = await auth.getCurrentUser();
    if (!mounted) return;
    setState(() {
      _user = user;
      _isTeacher = user?.role == AppConstants.roleTeacher;
    });
  }

  Future<void> _loadApiKey() async {
    final groq = await _groqFuture;
    final key = await groq.getApiKey();
    if (key != null && _apiKeyController.text.isEmpty) {
      setState(() => _apiKeyController.text = key);
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showMessage('New passwords do not match.');
      return;
    }
    if (_newPasswordController.text.isEmpty) {
      _showMessage('Password cannot be empty.');
      return;
    }
    if (_user == null) return;

    if (_user!.password != _oldPasswordController.text) {
      _showMessage('Old password is incorrect.');
      return;
    }

    final updated = _user!.copyWith(password: _newPasswordController.text);
    await ServiceLocator.db.updateUser(updated);

    _showMessage('Password updated successfully.');

    _oldPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    _loadUser();
  }

  Future<void> _saveApiKey() async {
    final groq = await _groqFuture;
    final key = _apiKeyController.text.trim();
    if (key.isNotEmpty && !key.startsWith('gsk_')) {
      _showMessage('Groq API key should start with "gsk_".');
      return;
    }
    await groq.saveApiKey(key);
    if (!mounted) return;
    _showMessage('Groq API key saved securely.');
  }

  Future<void> _clearApiKey() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear API Key'),
        content: const Text('Remove the stored Groq API key?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.delete, foregroundColor: Colors.white),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final groq = await _groqFuture;
      await groq.clearApiKey();
      _apiKeyController.clear();
      if (!mounted) return;
      _showMessage('API key cleared.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildThemeTile(String label, ThemeMode mode, QuizForgeAppState? app) {
    final selected = (app?.themeMode ?? ThemeMode.system) == mode;
    return ListTile(
      leading: Icon(
        selected ? LucideIcons.checkCircle2 : LucideIcons.circle,
        color: selected ? AppColors.add : null,
      ),
      title: Text(label),
      trailing: selected ? const Icon(LucideIcons.check, color: AppColors.add) : null,
      onTap: () => app?.setTheme(mode),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final app = QuizForgeApp.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
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
        currentRoute: AppRoutes.settings,
        onLogout: _logout,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(_mediumSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Theme', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: _smallSpacing),
            Card(
              child: Column(
                children: [
                  _buildThemeTile('System', ThemeMode.system, app),
                  _buildThemeTile('Light', ThemeMode.light, app),
                  _buildThemeTile('Dark', ThemeMode.dark, app),
                ],
              ),
            ),
            const SizedBox(height: _largeSpacing),
            Text('Change Password', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: _smallSpacing),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(_cardPadding),
                child: Column(
                  children: [
                    TextField(
                      controller: _oldPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Old Password',
                        prefixIcon: Icon(LucideIcons.lock),
                      ),
                    ),
                    const SizedBox(height: _smallSpacing),
                    TextField(
                      controller: _newPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'New Password',
                        prefixIcon: Icon(LucideIcons.key),
                      ),
                    ),
                    const SizedBox(height: _smallSpacing),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: true,
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
                        onPressed: _changePassword,
                        icon: const Icon(LucideIcons.save),
                        label: const Text('Update Password'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.add,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isTeacher) ...[
              const SizedBox(height: _largeSpacing),
              Text('Groq API Key', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: _smallSpacing),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(_cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _apiKeyController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'API Key',
                          hintText: 'gsk_...',
                          prefixIcon: const Icon(LucideIcons.key),
                          suffixIcon: IconButton(
                            icon: const Icon(LucideIcons.save, color: AppColors.add),
                            onPressed: _saveApiKey,
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                        ),
                      ),
                      const SizedBox(height: _smallSpacing),
                      Text(
                        'Stored securely in the platform keychain/encrypted storage.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: _mediumSpacing),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _saveApiKey,
                              icon: const Icon(LucideIcons.save),
                              label: const Text('Save Key'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.edit,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: _smallSpacing),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _clearApiKey,
                              icon: const Icon(LucideIcons.trash2, color: AppColors.delete),
                              label: const Text('Clear Key', style: TextStyle(color: AppColors.delete)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: _largeSpacing),
            Text('Account', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: _smallSpacing),
            Card(
              child: ListTile(
                leading: const Icon(LucideIcons.logOut, color: AppColors.logout),
                title: const Text('Logout'),
                subtitle: const Text('Sign out of the current session'),
                onTap: _logout,
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
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }
}
