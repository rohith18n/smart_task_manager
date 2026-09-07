import 'package:flutter/material.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/theme/app_colors.dart';

class ErrorViewWidget extends StatelessWidget {
  final AppException? error;
  final String message;
  final VoidCallback onRetry;

  const ErrorViewWidget({
    super.key,
    this.error,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    IconData icon;
    Color iconColor;
    String title;
    String description;
    String buttonText;

    if (error is NetworkException) {
      icon = Icons.wifi_off_rounded;
      iconColor = const Color(0xFFD97706);
      title = 'No Internet Connection';
      description =
          'Please check your network settings. Your local cached tasks remain available offline.';
      buttonText = 'Retry Connection';
    } else if (error is ServerException) {
      icon = Icons.cloud_off_rounded;
      iconColor = AppColors.error;
      title = 'Server Error';
      description = message.isNotEmpty
          ? message
          : 'The server encountered an issue. Please try again shortly.';
      buttonText = 'Retry Request';
    } else if (error is CacheException) {
      icon = Icons.storage_rounded;
      iconColor = Colors.deepPurple;
      title = 'Local Database Error';
      description =
          'Failed to read or write to local storage cache on this device.';
      buttonText = 'Try Again';
    } else if (error is AuthException) {
      icon = Icons.lock_outline_rounded;
      iconColor = AppColors.error;
      title = 'Authentication Error';
      description = message.isNotEmpty
          ? message
          : 'Your session has expired. Please sign in again to continue.';
      buttonText = 'Sign In';
    } else {
      icon = Icons.error_outline_rounded;
      iconColor = AppColors.error;
      title = 'Oops! Something went wrong';
      description = message.isNotEmpty
          ? message
          : 'An unexpected error occurred while loading tasks.';
      buttonText = 'Try Again';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: iconColor),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(buttonText),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
