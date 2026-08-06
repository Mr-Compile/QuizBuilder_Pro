import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/theme/app_theme.dart';

/// Reusable modal bottom sheet with consistent styling
class ModalBottomSheet extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final List<Widget>? actions;
  final double? maxHeight;
  final bool isScrollControlled;

  const ModalBottomSheet({
    super.key,
    required this.title,
    required this.children,
    this.actions,
    this.maxHeight,
    this.isScrollControlled = true,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required List<Widget> children,
    List<Widget>? actions,
    double? maxHeight,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      builder: (context) => ModalBottomSheet(
        title: title,
        actions: actions,
        maxHeight: maxHeight,
        isScrollControlled: isScrollControlled,
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: maxHeight ?? (MediaQuery.of(context).size.height * 0.8),
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: AppTheme.spacing2),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacing4),
            child: Row(
              children: [
                const Icon(LucideIcons.slidersHorizontal),
                const SizedBox(width: AppTheme.spacing2),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacing4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ),
          // Actions
          if (actions != null && actions!.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppTheme.spacing4,
                AppTheme.spacing4,
                AppTheme.spacing4,
                AppTheme.spacing4 + bottomPadding,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions!,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Quick action modal for simple forms
class QuickActionModal extends StatelessWidget {
  final String title;
  final List<Widget> formFields;
  final String primaryActionLabel;
  final VoidCallback onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final bool isLoading;

  const QuickActionModal({
    super.key,
    required this.title,
    required this.formFields,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.isLoading = false,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required List<Widget> formFields,
    required String primaryActionLabel,
    required VoidCallback onPrimaryAction,
    String? secondaryActionLabel,
    VoidCallback? onSecondaryAction,
    bool isLoading = false,
  }) {
    return ModalBottomSheet.show<bool>(
      context: context,
      title: title,
      children: formFields,
      actions: [
        if (secondaryActionLabel != null)
          TextButton(
            onPressed: onSecondaryAction ?? () => Navigator.pop(context, false),
            child: Text(secondaryActionLabel),
          ),
        ElevatedButton(
          onPressed: isLoading ? null : () {
            onPrimaryAction();
            Navigator.pop(context, true);
          },
          child: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(primaryActionLabel),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      title: title,
      actions: [
        if (secondaryActionLabel != null)
          TextButton(
            onPressed: onSecondaryAction ?? () => Navigator.pop(context, false),
            child: Text(secondaryActionLabel!),
          ),
        ElevatedButton(
          onPressed: isLoading ? null : () {
            onPrimaryAction();
            Navigator.pop(context, true);
          },
          child: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(primaryActionLabel),
        ),
      ],
      children: formFields,
    );
  }
}
