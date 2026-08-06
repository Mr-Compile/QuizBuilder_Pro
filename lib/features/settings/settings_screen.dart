import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user.dart';
import '../../services/groq_ai_service.dart';
import '../../services/service_locator.dart';
import '../../widgets/navigation_scaffold.dart';
import '../../widgets/modal_bottom_sheet.dart';

/// Settings screen with theme toggle, password change and API key management.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyController = TextEditingController();

  User? _user;
  late Future<GroqAiService> _groqFuture;

  static const double _smallSpacing = AppTheme.spacing2;
  static const double _mediumSpacing = AppTheme.spacing4;
  static const double _largeSpacing = AppTheme.spacing6;

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
    });
  }

  Future<void> _loadApiKey() async {
    final groq = await _groqFuture;
    final key = await groq.getApiKey();
    if (key != null && _apiKeyController.text.isEmpty) {
      setState(() => _apiKeyController.text = key);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildThemeTile(String label, ThemeMode mode, QuizBuilderProAppState? app) {
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

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing2),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: AppTheme.spacing2),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _testConnection(BuildContext context) async {
    final groq = await _groqFuture;
    final valid = await groq.hasValidApiKey();
    
    if (!mounted) return;
    
    if (valid) {
      _showMessage('Connection successful! API key is valid.');
    } else {
      _showMessage('Connection failed. Please check your API key.');
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final auth = await ServiceLocator.auth;
              await auth.logout();
              if (!mounted) return;
              if (!context.mounted) return;
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.delete, foregroundColor: Colors.white),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordModal(BuildContext context) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ModalBottomSheet(
        title: 'Change Password',
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text != confirmPasswordController.text) {
                _showMessage('Passwords do not match');
                return;
              }
              if (newPasswordController.text.isEmpty) {
                _showMessage('Password cannot be empty');
                return;
              }
              if (_user == null) return;
              if (_user!.password != oldPasswordController.text) {
                _showMessage('Old password is incorrect');
                return;
              }

              final updated = _user!.copyWith(password: newPasswordController.text);
              await ServiceLocator.db.updateUser(updated);
              if (!mounted) return;
              if (!context.mounted) return;
              Navigator.pop(context);
              _showMessage('Password updated successfully');
              _loadUser();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.edit,
              foregroundColor: Colors.white,
            ),
            child: const Text('Update Password'),
          ),
        ],
        children: [
          TextField(
            controller: oldPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Old Password',
              hintText: 'Enter current password',
              filled: true,
              prefixIcon: Icon(LucideIcons.lock),
            ),
          ),
          const SizedBox(height: _mediumSpacing),
          TextField(
            controller: newPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'New Password',
              hintText: 'Enter new password',
              filled: true,
              prefixIcon: Icon(LucideIcons.key),
            ),
          ),
          const SizedBox(height: _mediumSpacing),
          TextField(
            controller: confirmPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Confirm Password',
              hintText: 'Confirm new password',
              filled: true,
              prefixIcon: Icon(LucideIcons.shieldCheck),
            ),
          ),
        ],
      ),
    );
  }

  void _showApiKeyModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ModalBottomSheet(
        title: 'Groq API Key',
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
        children: [
          TextField(
            controller: _apiKeyController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'API Key',
              hintText: 'gsk_...',
              prefixIcon: Icon(LucideIcons.key),
              filled: true,
            ),
          ),
          const SizedBox(height: _smallSpacing),
          Text(
            'Stored securely in the platform keychain/encrypted storage.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: _mediumSpacing),
          ElevatedButton.icon(
            onPressed: () async {
              final groq = await _groqFuture;
              await groq.saveApiKey(_apiKeyController.text);
              if (!mounted) return;
              if (!context.mounted) return;
              Navigator.pop(context);
              _showMessage('API key saved successfully');
            },
            icon: const Icon(LucideIcons.save),
            label: const Text('Save API Key'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: _smallSpacing),
          OutlinedButton.icon(
            onPressed: () => _testConnection(context),
            icon: const Icon(LucideIcons.link),
            label: const Text('Test Connection'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NavigationScaffold(
      title: 'Settings',
      currentRoute: AppRoutes.settings,
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacing4),
        children: [
          // Theme Section
          _buildSectionHeader(context, 'Appearance', LucideIcons.palette),
          const SizedBox(height: _smallSpacing),
          Card(
            child: Builder(
              builder: (context) {
                final app = context.findAncestorStateOfType<QuizBuilderProAppState>();
                return Column(
                  children: [
                    _buildThemeTile('System', ThemeMode.system, app),
                    const Divider(height: 1),
                    _buildThemeTile('Light', ThemeMode.light, app),
                    const Divider(height: 1),
                    _buildThemeTile('Dark', ThemeMode.dark, app),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: _largeSpacing),

          // Account Section
          _buildSectionHeader(context, 'Account', LucideIcons.user),
          const SizedBox(height: _smallSpacing),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(LucideIcons.key),
                  title: const Text('Change Password'),
                  trailing: const Icon(LucideIcons.chevronRight),
                  onTap: () => _showChangePasswordModal(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(LucideIcons.logOut, color: AppColors.delete),
                  title: const Text('Logout', style: TextStyle(color: AppColors.delete)),
                  trailing: const Icon(LucideIcons.chevronRight),
                  onTap: () => _showLogoutDialog(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: _largeSpacing),

          // API Section
          _buildSectionHeader(context, 'API Configuration', LucideIcons.settings),
          const SizedBox(height: _smallSpacing),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(LucideIcons.key),
                  title: const Text('Groq API Key'),
                  subtitle: const Text('Configure AI service'),
                  trailing: const Icon(LucideIcons.chevronRight),
                  onTap: () => _showApiKeyModal(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: _largeSpacing),

          // About Section
          _buildSectionHeader(context, 'About', LucideIcons.info),
          const SizedBox(height: _smallSpacing),
          const Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(LucideIcons.tag),
                  title: Text('App Version'),
                  subtitle: Text('1.0.0+1'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(LucideIcons.code),
                  title: Text('Developer'),
                  subtitle: Text('Quiz Builder Pro Team'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(LucideIcons.code),
                  title: Text('GitHub'),
                  subtitle: Text('View source code'),
                  trailing: Icon(LucideIcons.chevronRight),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }
}
