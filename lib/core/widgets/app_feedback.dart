import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Types of feedback supported by [AppFeedback]
enum AppFeedbackType {
  success,
  error,
  warning,
  info,
  sync,
}

/// A production-grade, highly polished feedback system for displaying
/// rich error, success, warning, info, and sync notifications across the app.
class AppFeedback {
  AppFeedback._();

  /// Show a success toast with rich emerald gradients and smooth animations
  static void showSuccess(
    BuildContext context, {
    required String message,
    String title = 'Success',
    Duration duration = const Duration(milliseconds: 3200),
    String? actionLabel,
    VoidCallback? onAction,
    IconData? icon,
  }) {
    _show(
      context,
      type: AppFeedbackType.success,
      message: message,
      title: title,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
      customIcon: icon,
    );
  }

  /// Show an error toast with rich crimson glow and optional retry action
  static void showError(
    BuildContext context, {
    required String message,
    String title = 'Action Failed',
    Duration duration = const Duration(milliseconds: 4500),
    String? actionLabel,
    VoidCallback? onAction,
    IconData? icon,
  }) {
    _show(
      context,
      type: AppFeedbackType.error,
      message: message,
      title: title,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
      customIcon: icon,
    );
  }

  /// Show a warning toast with warm amber glow
  static void showWarning(
    BuildContext context, {
    required String message,
    String title = 'Attention',
    Duration duration = const Duration(milliseconds: 3500),
    String? actionLabel,
    VoidCallback? onAction,
    IconData? icon,
  }) {
    _show(
      context,
      type: AppFeedbackType.warning,
      message: message,
      title: title,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
      customIcon: icon,
    );
  }

  /// Show an info toast with modern WhatsApp blue accents
  static void showInfo(
    BuildContext context, {
    required String message,
    String title = 'Information',
    Duration duration = const Duration(milliseconds: 3000),
    String? actionLabel,
    VoidCallback? onAction,
    IconData? icon,
  }) {
    _show(
      context,
      type: AppFeedbackType.info,
      message: message,
      title: title,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
      customIcon: icon,
    );
  }

  /// Show a sync toast with cloud status
  static void showSync(
    BuildContext context, {
    required String message,
    String title = 'Cloud Sync',
    Duration duration = const Duration(milliseconds: 2800),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(
      context,
      type: AppFeedbackType.sync,
      message: message,
      title: title,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Dismiss active feedback
  static void hide(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  static void _show(
    BuildContext context, {
    required AppFeedbackType type,
    required String message,
    required String title,
    required Duration duration,
    String? actionLabel,
    VoidCallback? onAction,
    IconData? customIcon,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        padding: EdgeInsets.zero,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: duration,
        content: _AppFeedbackCard(
          type: type,
          title: title,
          message: message,
          duration: duration,
          actionLabel: actionLabel,
          onAction: onAction,
          customIcon: customIcon,
          onDismiss: () {
            messenger.hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}

class _AppFeedbackCard extends StatefulWidget {
  final AppFeedbackType type;
  final String title;
  final String message;
  final Duration duration;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? customIcon;
  final VoidCallback onDismiss;

  const _AppFeedbackCard({
    required this.type,
    required this.title,
    required this.message,
    required this.duration,
    this.actionLabel,
    this.onAction,
    this.customIcon,
    required this.onDismiss,
  });

  @override
  State<_AppFeedbackCard> createState() => _AppFeedbackCardState();
}

class _AppFeedbackCardState extends State<_AppFeedbackCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final config = _FeedbackVisualConfig.fromType(widget.type);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141C22) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? config.primaryColor.withValues(alpha: 0.35)
              : config.primaryColor.withValues(alpha: 0.22),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: config.primaryColor.withValues(alpha: isDark ? 0.25 : 0.12),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Gradient Icon Badge
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          config.primaryColor,
                          config.accentColor,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [
                        BoxShadow(
                          color: config.primaryColor.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        widget.customIcon ?? config.icon,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Title and Message
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.message,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            height: 1.25,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Action Button
                  if (widget.actionLabel != null && widget.onAction != null) ...[
                    const SizedBox(width: 8),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          widget.onDismiss();
                          widget.onAction!();
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: config.primaryColor.withValues(
                              alpha: isDark ? 0.2 : 0.12,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: config.primaryColor.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            widget.actionLabel!,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? config.accentColor
                                  : config.primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Dismiss Button
                  const SizedBox(width: 4),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.onDismiss,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Animated Linear Progress Indicator Bar
            AnimatedBuilder(
              animation: _progressController,
              builder: (context, child) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final progress = 1.0 - _progressController.value;
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        height: 2.5,
                        width: constraints.maxWidth * progress,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              config.primaryColor,
                              config.accentColor,
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackVisualConfig {
  final Color primaryColor;
  final Color accentColor;
  final IconData icon;

  const _FeedbackVisualConfig({
    required this.primaryColor,
    required this.accentColor,
    required this.icon,
  });

  factory _FeedbackVisualConfig.fromType(AppFeedbackType type) {
    switch (type) {
      case AppFeedbackType.success:
        return const _FeedbackVisualConfig(
          primaryColor: AppColors.primary,
          accentColor: AppColors.primaryLight,
          icon: Icons.check_circle_rounded,
        );
      case AppFeedbackType.error:
        return const _FeedbackVisualConfig(
          primaryColor: AppColors.error,
          accentColor: Color(0xFFFF7E8B),
          icon: Icons.error_outline_rounded,
        );
      case AppFeedbackType.warning:
        return const _FeedbackVisualConfig(
          primaryColor: AppColors.warning,
          accentColor: Color(0xFFFFCF56),
          icon: Icons.warning_amber_rounded,
        );
      case AppFeedbackType.info:
        return const _FeedbackVisualConfig(
          primaryColor: AppColors.accent,
          accentColor: Color(0xFF67D2FD),
          icon: Icons.info_outline_rounded,
        );
      case AppFeedbackType.sync:
        return const _FeedbackVisualConfig(
          primaryColor: AppColors.primaryDark,
          accentColor: AppColors.accent,
          icon: Icons.sync_rounded,
        );
    }
  }
}
