import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class TaskCompletedToggle extends StatelessWidget {
  final bool isCompleted;
  final ValueChanged<bool> onChanged;

  const TaskCompletedToggle({
    super.key,
    required this.isCompleted,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkInputFill : AppColors.lightInputFill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Mark as Completed',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          Switch(
            value: isCompleted,
            activeThumbColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
