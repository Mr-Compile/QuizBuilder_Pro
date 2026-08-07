import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/utils/dialog_helper.dart';
import '../../services/service_locator.dart';
import '../../widgets/responsive_widgets.dart';

// Spacing constants for better readability
const double _largeSpacing = AppTheme.spacing6;

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

  void _toggleTheme() {
    final appState = QuizBuilderProApp.globalKey.currentState;
    if (appState == null) return;
    
    final currentMode = appState.themeMode;
    final newMode = currentMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    appState.setTheme(newMode);
  }

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

      // Role-based routing is handled by the backend
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
    final iconSize = context.responsiveIconSize * 2;
    final appState = QuizBuilderProApp.globalKey.currentState;
    final isDark = (appState?.themeMode ?? ThemeMode.system) == ThemeMode.dark;
    
    return Scaffold(
      body: Stack(
        children: [
          Container(
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
            padding: EdgeInsets.only(
              left: context.responsiveSpacing,
              right: context.responsiveSpacing,
              top: context.responsiveSpacing,
              bottom: MediaQuery.of(context).viewInsets.bottom + context.responsiveSpacing,
            ),
            child: ResponsiveContainer(
              maxWidth: context.isMobile ? double.infinity : 500,
              child: Card(
                elevation: 8,
                shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                child: Padding(
                  padding: EdgeInsets.all(context.responsiveCardPadding),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.brain,
                        size: iconSize,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      SizedBox(height: context.responsiveSpacing),
                      Text(
                        AppConstants.appName,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: context.isMobile ? 24 : 28,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: context.responsiveSpacing / 2),
                      Text(
                        AppConstants.appTagline,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: context.responsiveSpacing * 2),
                      TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          prefixIcon: const Icon(LucideIcons.user),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: context.responsiveSpacing,
                            vertical: context.isMobile ? 16 : 20,
                          ),
                        ),
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                      ),
                      SizedBox(height: context.responsiveSpacing),
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
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: context.responsiveSpacing,
                            vertical: context.isMobile ? 16 : 20,
                          ),
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _login(),
                      ),
                      SizedBox(height: context.responsiveSpacing * 2),
                      SizedBox(
                        width: double.infinity,
                        height: context.isMobile ? 50 : 56,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _login,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(LucideIcons.logIn),
                          label: Text(
                            'Login',
                            style: TextStyle(fontSize: context.isMobile ? 16 : 18),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.login,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(context.responsiveBorderRadius),
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
          ),
          Positioned(
            top: _largeSpacing,
            right: _largeSpacing,
            child: IconButton(
              icon: Icon(
                isDark ? LucideIcons.sun : LucideIcons.moon,
              ),
              onPressed: _toggleTheme,
              tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            ),
          ),
        ],
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