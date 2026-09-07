import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

enum TaskPriority {
  low('Low', AppColors.priorityLow, AppColors.priorityLowBg, 1),
  medium('Medium', AppColors.priorityMedium, AppColors.priorityMediumBg, 2),
  high('High', AppColors.priorityHigh, AppColors.priorityHighBg, 3);

  final String displayName;
  final Color color;
  final Color backgroundColor;
  final int rank;

  const TaskPriority(this.displayName, this.color, this.backgroundColor, this.rank);

  static TaskPriority fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'low':
        return TaskPriority.low;
      case 'medium':
        return TaskPriority.medium;
      case 'high':
      case 'urgent':
        return TaskPriority.high;
      default:
        return TaskPriority.medium;
    }
  }
}
