import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../constants/app_colors.dart';
import '../confirmation/confirmation.dart';
import '../confirmation/confirmation_dialogs.dart';

/// Reusable, accessible dialogs used throughout QuizBuilder Pro.
/// Now uses the centralized confirmation system for consistency.
class DialogHelper {
  DialogHelper._();

  /// Shows a styled error dialog with an optional retry action.
  static Future<void> showError(
    BuildContext context,
    String message, {
    String title = 'Something went wrong',
    FutureOr<void> Function()? onRetry,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(LucideIcons.alertCircle, color: AppColors.delete),
            SizedBox(width: 12),
            Text('Something went wrong'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (onRetry != null)
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                await onRetry();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  /// Shows a "no internet" dialog for features that require connectivity.
  static Future<void> showNoInternet(BuildContext context, {FutureOr<void> Function()? onRetry}) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.wifi_off, color: AppColors.delete),
            SizedBox(width: 12),
            Text('No internet connection'),
          ],
        ),
        content: const Text(
          'This feature needs an active internet connection. Please connect to Wi-Fi or mobile data and try again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (onRetry != null)
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                await onRetry();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  /// Shows a confirmation dialog and returns `true` if the user confirms.
  /// Delegates to the centralized ConfirmationDialogs for consistency.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Yes',
    String cancelText = 'Cancel',
    Color confirmColor = AppColors.primary,
  }) async {
    return ConfirmationDialogs.confirm(
      context,
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      style: ConfirmationStyle.dialog,
      severity: Severity.info,
    );
  }
}
