import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/task_entity.dart';

class TaskCardAvatar extends StatelessWidget {
  final TaskEntity task;
  final VoidCallback onTap;

  const TaskCardAvatar({
    super.key,
    required this.task,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: task.isCompleted
              ? (isDark
                  ? AppColors.chipSelectedBg
                  : AppColors.lightChipSelectedBg)
              : (isDark
                  ? AppColors.darkInputFill
                  : AppColors.lightInputFill),
          border: Border.all(
            color:
                task.isCompleted ? AppColors.primary : task.priority.color,
            width: 2,
          ),
        ),
        child: Center(
          child: Icon(
            task.isCompleted
                ? Icons.check_rounded
                : Icons.assignment_outlined,
            size: 22,
            color: task.isCompleted
                ? AppColors.primary
                : (isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary),
          ),
        ),
      ),
    );
  }
}
