import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../models/user.dart';
import '../services/service_locator.dart';

/// Widget that displays the current AI generation quota status.
/// Shows remaining generations out of the daily limit with a visual progress bar.
class QuotaIndicator extends StatefulWidget {
  final User user;
  final bool showLabel;
  final bool compact;

  const QuotaIndicator({
    super.key,
    required this.user,
    this.showLabel = true,
    this.compact = false,
  });

  @override
  State<QuotaIndicator> createState() => _QuotaIndicatorState();
}

class _QuotaIndicatorState extends State<QuotaIndicator> {
  Map<String, int>? _quotaInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuotaInfo();
  }

  Future<void> _loadQuotaInfo() async {
    final quota = await ServiceLocator.quota;
    final info = await quota.getQuotaInfo(widget.user);
    if (mounted) {
      setState(() {
        _quotaInfo = info;
        _isLoading = false;
      });
    }
  }

  @override
  void didUpdateWidget(QuotaIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.id != widget.user.id) {
      _loadQuotaInfo();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoading();
    }

    if (_quotaInfo == null) {
      return const SizedBox.shrink();
    }

    final used = _quotaInfo!['used'] ?? 0;
    final limit = _quotaInfo!['limit'] ?? 0;
    final remaining = _quotaInfo!['remaining'] ?? 0;

    // If limit is 0 (students), show disabled state
    if (limit == 0) {
      return _buildDisabled();
    }

    return widget.compact ? _buildCompact(used, limit, remaining) : _buildFull(used, limit, remaining);
  }

  Widget _buildLoading() {
    return widget.compact
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Padding(
            padding: EdgeInsets.all(AppTheme.spacing2),
            child: CircularProgressIndicator(),
          );
  }

  Widget _buildDisabled() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          LucideIcons.ban,
          size: widget.compact ? 16 : 20,
          color: AppColors.delete,
        ),
        if (widget.showLabel) ...[
          const SizedBox(width: AppTheme.spacing2),
          Text(
            'AI generation unavailable',
            style: TextStyle(
              fontSize: widget.compact ? 12 : 14,
              color: AppColors.delete,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFull(int used, int limit, int remaining) {
    final progress = limit > 0 ? used / limit : 0.0;
    final isLow = remaining <= 2;
    final isExhausted = remaining == 0;

    return Card(
      elevation: 0,
      color: isExhausted
          ? AppColors.delete.withValues(alpha: 0.1)
          : isLow
              ? AppColors.warning.withValues(alpha: 0.1)
              : AppColors.edit.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  isExhausted
                      ? LucideIcons.xCircle
                      : isLow
                          ? LucideIcons.alertTriangle
                          : LucideIcons.zap,
                  size: 20,
                  color: isExhausted
                      ? AppColors.delete
                      : isLow
                          ? AppColors.warning
                          : AppColors.edit,
                ),
                const SizedBox(width: AppTheme.spacing2),
                Text(
                  'AI Generation Quota',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                Text(
                  '$remaining of $limit remaining',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isExhausted
                            ? AppColors.delete
                            : isLow
                                ? AppColors.warning
                                : AppColors.edit,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing2),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: isExhausted
                    ? AppColors.delete.withValues(alpha: 0.2)
                    : isLow
                        ? AppColors.warning.withValues(alpha: 0.2)
                        : AppColors.edit.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isExhausted
                      ? AppColors.delete
                      : isLow
                          ? AppColors.warning
                          : AppColors.edit,
                ),
                minHeight: 8,
              ),
            ),
            if (widget.showLabel) ...[
              const SizedBox(height: AppTheme.spacing2),
              Text(
                isExhausted
                    ? 'Daily limit reached. Quota resets at midnight.'
                    : isLow
                        ? 'Low quota remaining. Use generations wisely.'
                        : 'Quota resets at midnight.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompact(int used, int limit, int remaining) {
    final isLow = remaining <= 2;
    final isExhausted = remaining == 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isExhausted
              ? LucideIcons.xCircle
              : isLow
                  ? LucideIcons.alertTriangle
                  : LucideIcons.zap,
          size: 16,
          color: isExhausted
              ? AppColors.delete
              : isLow
                  ? AppColors.warning
                  : AppColors.edit,
        ),
        if (widget.showLabel) ...[
          const SizedBox(width: 4),
          Text(
            '$remaining/$limit',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isExhausted
                  ? AppColors.delete
                  : isLow
                      ? AppColors.warning
                      : AppColors.edit,
            ),
          ),
        ],
      ],
    );
  }
}
