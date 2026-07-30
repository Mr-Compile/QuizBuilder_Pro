import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Consistent centered loading indicator with optional message.
class LoadingIndicator extends StatelessWidget {
  final String? message;

  const LoadingIndicator({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: AppTheme.mediumSpacing),
            Text(message!),
          ],
        ],
      ),
    );
  }
}
