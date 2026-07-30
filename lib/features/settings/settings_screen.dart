import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../database/database_helper.dart';
import '../../models/user.dart';
import '../../services/groq_ai_service.dart';
import '../../services/service_locator.dart';

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

  @override
  void initState() {
    super.initState();
    _loadUser();
    _groqFuture = ServiceLocator.groq;
  }

  Future<void> _loadUser() async {
    final auth = await ServiceLocator.auth;
    final user = await auth.getCurrentUser();
    setState(() {
      _user = user;
      _isTeacher = user?.role == AppConstants.roleTeacher;
    });
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match.')),
      );
      return;
    }
    if (_newPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password cannot be empty.')),
      );
      return;
    }
    if (_user == null) return;

    if (_user!.password != _oldPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Old password is incorrect.')),
      );
      return;
    }

    final updated = _user!.copyWith(password: _newPasswordController.text);
    await ServiceLocator.db.updateUser(updated);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password updated successfully.')),
    );

    _oldPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    _loadUser();
  }

  Future<void> _saveApiKey() async {
    final groq = await _groqFuture;
    await groq.saveApiKey(_apiKeyController.text.trim());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Groq API key saved.')),
    );
  }

  void _setTheme(ThemeMode mode) {
    QuizForgeApp.of(context)?.setTheme(mode);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.mediumSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Theme', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppTheme.smallSpacing),
            Card(
              child: Column(
                children: [
                  RadioListTile<ThemeMode>(
                    title: const Text('System'),
                    value: ThemeMode.system,
                    groupValue: theme.brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
                    onChanged: (v) => _setTheme(v ?? ThemeMode.system),
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('Light'),
                    value: ThemeMode.light,
                    groupValue: theme.brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
                    onChanged: (v) => _setTheme(v ?? ThemeMode.light),
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('Dark'),
                    value: ThemeMode.dark,
                    groupValue: theme.brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
                    onChanged: (v) => _setTheme(v ?? ThemeMode.dark),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.largeSpacing),
            Text('Change Password', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppTheme.smallSpacing),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.cardPadding),
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
                    const SizedBox(height: AppTheme.smallSpacing),
                    TextField(
                      controller: _newPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'New Password',
                        prefixIcon: Icon(LucideIcons.key),
                      ),
                    ),
                    const SizedBox(height: AppTheme.smallSpacing),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirm New Password',
                        prefixIcon: Icon(LucideIcons.key),
                      ),
                    ),
                    const SizedBox(height: AppTheme.mediumSpacing),
                    SizedBox(
                      width: double.infinity,
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
              const SizedBox(height: AppTheme.largeSpacing),
              Text('Groq API Key', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppTheme.smallSpacing),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.cardPadding),
                  child: Column(
                    children: [
                      FutureBuilder(
                        future: _groqFuture,
                        builder: (context, snapshot) {
                          final key = snapshot.hasData ? snapshot.data!.getApiKey() : null;
                          if (key != null && _apiKeyController.text.isEmpty) {
                            _apiKeyController.text = key;
                          }
                          return TextField(
                            controller: _apiKeyController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'API Key',
                              prefixIcon: Icon(LucideIcons.key),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: AppTheme.mediumSpacing),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _saveApiKey,
                          icon: const Icon(LucideIcons.save),
                          label: const Text('Save API Key'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.edit,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppTheme.largeSpacing),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.about),
                icon: const Icon(LucideIcons.info),
                label: const Text('About'),
              ),
            ),
          ],
        ),
      ),
    );
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
