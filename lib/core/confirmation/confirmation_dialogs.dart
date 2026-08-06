import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/constants/app_colors.dart';

/// Confirmation style for different UI patterns.
enum ConfirmationStyle {
  dialog,
  bottomSheet,
  snackbar,
}

/// Severity level for confirmation dialogs.
enum Severity {
  info,
  warning,
  danger,
}

/// Multi-modal confirmation system for sensitive actions.
/// Provides dialogs, bottom sheets, snackbars, and inline warnings.
class ConfirmationDialogs {
  ConfirmationDialogs._();

  /// Shows a confirmation dialog and returns the user's choice.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    ConfirmationStyle style = ConfirmationStyle.dialog,
    Severity severity = Severity.warning,
    IconData? icon,
  }) async {
    switch (style) {
      case ConfirmationStyle.dialog:
        return _showDialog(
          context,
          title: title,
          message: message,
          confirmText: confirmText,
          cancelText: cancelText,
          severity: severity,
          icon: icon,
        );
      case ConfirmationStyle.bottomSheet:
        return _showBottomSheet(
          context,
          title: title,
          message: message,
          confirmText: confirmText,
          cancelText: cancelText,
          severity: severity,
          icon: icon,
        );
      case ConfirmationStyle.snackbar:
        return _showSnackbar(
          context,
          title: title,
          message: message,
          confirmText: confirmText,
          cancelText: cancelText,
          severity: severity,
        );
    }
  }

  /// Shows a dialog confirmation.
  static Future<bool> _showDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmText,
    required String cancelText,
    required Severity severity,
    IconData? icon,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              icon ?? _getSeverityIcon(severity),
              color: _getSeverityColor(severity),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _getSeverityColor(severity),
              foregroundColor: Colors.white,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result == true;
  }

  /// Shows a bottom sheet confirmation.
  static Future<bool> _showBottomSheet(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmText,
    required String cancelText,
    required Severity severity,
    IconData? icon,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  icon ?? _getSeverityIcon(severity),
                  color: _getSeverityColor(severity),
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(message),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(cancelText),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getSeverityColor(severity),
                      foregroundColor: Colors.white,
                    ),
                    child: Text(confirmText),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    return result == true;
  }

  /// Shows a snackbar confirmation.
  static Future<bool> _showSnackbar(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmText,
    required String cancelText,
    required Severity severity,
  }) async {
    bool? result;
    
    final snackBar = SnackBar(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(message),
        ],
      ),
      backgroundColor: _getSeverityColor(severity),
      action: SnackBarAction(
        label: cancelText,
        textColor: Colors.white,
        onPressed: () {
          result = false;
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
      duration: const Duration(seconds: 10),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    
    // Wait for either the action or timeout
    await Future.delayed(const Duration(seconds: 10));
    
    return result ?? false;
  }

  /// Shows a destructive action confirmation (delete, remove, etc.).
  static Future<bool> confirmDestructive(
    BuildContext context, {
    required String itemName,
    String action = 'delete',
    ConfirmationStyle style = ConfirmationStyle.dialog,
  }) {
    return confirm(
      context,
      title: 'Confirm $action',
      message: 'Are you sure you want to $action "$itemName"? This action cannot be undone.',
      confirmText: action.capitalize(),
      cancelText: 'Cancel',
      style: style,
      severity: Severity.danger,
      icon: LucideIcons.alertTriangle,
    );
  }

  /// Shows a sensitive action confirmation (activate, deactivate, etc.).
  static Future<bool> confirmSensitive(
    BuildContext context, {
    required String action,
    required String message,
    ConfirmationStyle style = ConfirmationStyle.dialog,
  }) {
    return confirm(
      context,
      title: 'Confirm $action',
      message: message,
      confirmText: action.capitalize(),
      cancelText: 'Cancel',
      style: style,
      severity: Severity.warning,
      icon: LucideIcons.shieldAlert,
    );
  }

  /// Shows an info confirmation.
  static Future<bool> confirmInfo(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Continue',
    ConfirmationStyle style = ConfirmationStyle.dialog,
  }) {
    return confirm(
      context,
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: 'Cancel',
      style: style,
      severity: Severity.info,
      icon: LucideIcons.info,
    );
  }

  /// Gets the appropriate icon for a severity level.
  static IconData _getSeverityIcon(Severity severity) {
    switch (severity) {
      case Severity.info:
        return LucideIcons.info;
      case Severity.warning:
        return LucideIcons.alertTriangle;
      case Severity.danger:
        return LucideIcons.alertCircle;
    }
  }

  /// Gets the appropriate color for a severity level.
  static Color _getSeverityColor(Severity severity) {
    switch (severity) {
      case Severity.info:
        return AppColors.primary;
      case Severity.warning:
        return AppColors.accent;
      case Severity.danger:
        return AppColors.delete;
    }
  }
}

/// Extension method to capitalize strings.
extension StringExtension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
