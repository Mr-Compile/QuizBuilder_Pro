import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/navigation_scaffold.dart';
import '../../core/routes/app_routes.dart';

/// About screen with app information.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = screenWidth < 360 ? 56.0 : 80.0;
    
    return NavigationScaffold(
      title: 'About',
      currentRoute: AppRoutes.about,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(screenWidth < 360 ? AppTheme.mediumSpacing : AppTheme.largeSpacing),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.brain,
                size: iconSize,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: AppTheme.mediumSpacing),
              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.smallSpacing),
              const Text(AppConstants.appTagline, textAlign: TextAlign.center),
              const SizedBox(height: AppTheme.mediumSpacing),
              const Text('Version 1.0.0+1'),
              const SizedBox(height: AppTheme.largeSpacing),
              const Text(
                'Built with Flutter, SQLite and the Groq AI API.\n'
                'Students can practice offline; teachers can generate questions online.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
