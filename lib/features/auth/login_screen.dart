import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/dialog_helper.dart';
import '../../services/service_locator.dart';

// Spacing constants for better readability
const double _smallSpacing = AppTheme.spacing2;
const double _mediumSpacing = AppTheme.spacing4;
const double _largeSpacing = AppTheme.spacing6;
const double _cardPadding = AppTheme.spacing6;

/// Local login screen with enhanced UI.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isTeacherMode = true;

  Future<void> _login() async {
    setState(() => _isLoading = true);

    try {
      final auth = await ServiceLocator.auth;
      final user = await auth.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (user == null) {
        throw Exception('Login failed');
      }

      // Validate role matches selected mode
      if (_isTeacherMode && user.role != AppConstants.roleTeacher) {
        throw Exception('This account is not a teacher account');
      }
      if (!_isTeacherMode && user.role != AppConstants.roleStudent) {
        throw Exception('This account is not a student account');
      }

      if (user.role == AppConstants.roleTeacher) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.teacherDashboard);
      } else {
        Navigator.of(context).pushReplacementNamed(AppRoutes.studentDashboard);
      }
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      await DialogHelper.showError(context, message, title: 'Login failed');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(_largeSpacing),
            child: Card(
              elevation: 8,
              shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              child: Padding(
                padding: const EdgeInsets.all(_cardPadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.brain,
                      size: 72,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: _mediumSpacing),
                    Text(
                      AppConstants.appName,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: _smallSpacing),
                    Text(
                      AppConstants.appTagline,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: _largeSpacing),
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        prefixIcon: const Icon(LucideIcons.user),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                    ),
                    const SizedBox(height: _mediumSpacing),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isTeacherMode = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _isTeacherMode
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(AppTheme.roundedLg),
                              ),
                              child: Text(
                                'Teacher',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _isTeacherMode ? Colors.white : Colors.grey.shade700,
                                  fontWeight: _isTeacherMode ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: _smallSpacing),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isTeacherMode = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !_isTeacherMode
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(AppTheme.roundedLg),
                              ),
                              child: Text(
                                'Student',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: !_isTeacherMode ? Colors.white : Colors.grey.shade700,
                                  fontWeight: !_isTeacherMode ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: _mediumSpacing),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(LucideIcons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _login(),
                    ),
                    const SizedBox(height: _largeSpacing),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _login,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(LucideIcons.logIn),
                        label: const Text('Login', style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.login,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.roundedLg),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}