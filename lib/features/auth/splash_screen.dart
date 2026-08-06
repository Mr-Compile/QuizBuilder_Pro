import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../services/service_locator.dart';

/// Splash screen that loads the current session and redirects to the right dashboard.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    await Future.delayed(const Duration(seconds: 2));
    final auth = await ServiceLocator.auth;
    final user = await auth.getCurrentUser();

    if (!mounted) return;

    if (user == null) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      return;
    }

    if (user.role == AppConstants.roleTeacher) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.teacherDashboard);
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.studentDashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _animation.value,
                  child: Icon(
                    LucideIcons.brain,
                    size: 72,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(AppConstants.appTagline),
            const SizedBox(height: 32),
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
