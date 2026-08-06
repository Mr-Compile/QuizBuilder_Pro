import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/constants/app_colors.dart';

/// Inline warning widget for displaying validation errors and warnings.
/// Can be used within forms to show field-specific errors.
class InlineWarning extends StatelessWidget {
  final String message;
  final WarningType type;
  final bool showIcon;
  final EdgeInsets? padding;

  const InlineWarning({
    super.key,
    required this.message,
    this.type = WarningType.error,
    this.showIcon = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _getBackgroundColor(type).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getBackgroundColor(type),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          if (showIcon) ...[
            Icon(
              _getIcon(type),
              size: 16,
              color: _getBackgroundColor(type),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: _getBackgroundColor(type),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getBackgroundColor(WarningType type) {
    switch (type) {
      case WarningType.error:
        return AppColors.delete;
      case WarningType.warning:
        return AppColors.accent;
      case WarningType.info:
        return AppColors.primary;
      case WarningType.success:
        return AppColors.add;
    }
  }

  IconData _getIcon(WarningType type) {
    switch (type) {
      case WarningType.error:
        return LucideIcons.alertCircle;
      case WarningType.warning:
        return LucideIcons.alertTriangle;
      case WarningType.info:
        return LucideIcons.info;
      case WarningType.success:
        return LucideIcons.checkCircle;
    }
  }
}

/// Types of warnings for different severity levels.
enum WarningType {
  error,
  warning,
  info,
  success,
}

/// Form field wrapper that shows inline validation errors.
class ValidatedFormField extends StatelessWidget {
  final String label;
  final Widget child;
  final String? errorText;
  final bool showError;
  final WarningType errorType;

  const ValidatedFormField({
    super.key,
    required this.label,
    required this.child,
    this.errorText,
    this.showError = true,
    this.errorType = WarningType.error,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        child,
        if (showError && errorText != null && errorText!.isNotEmpty) ...[
          const SizedBox(height: 8),
          InlineWarning(
            message: errorText!,
            type: errorType,
          ),
        ],
      ],
    );
  }
}
