import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

/// About screen with app information.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.largeSpacing),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.brain,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: AppTheme.mediumSpacing),
              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppTheme.smallSpacing),
              Text(AppConstants.appTagline, textAlign: TextAlign.center),
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
