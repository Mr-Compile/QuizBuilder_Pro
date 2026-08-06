import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/theme/app_theme.dart';

/// Consistent centered loading indicator with optional message.
class LoadingIndicator extends StatefulWidget {
  final String? message;

  const LoadingIndicator({super.key, this.message});

  @override
  State<LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<LoadingIndicator>
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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
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
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
              );
            },
          ),
          const SizedBox(height: AppTheme.mediumSpacing),
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          if (widget.message != null) ...[
            const SizedBox(height: AppTheme.mediumSpacing),
            Text(widget.message!),
          ],
        ],
      ),
    );
  }
}
