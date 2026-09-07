import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/task_entity.dart';

class TaskDetailStatusBanner extends StatelessWidget {
  final TaskEntity task;
  final bool isOverdue;

  const TaskDetailStatusBanner({
    super.key,
    required this.task,
    required this.isOverdue,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: task.isCompleted
            ? (isDark
                ? AppColors.chipSelectedBg
                : AppColors.lightChipSelectedBg)
            : (isOverdue
                ? (isDark
                    ? AppColors.priorityUrgentBg
                    : AppColors.priorityUrgentLightBg)
                : (isDark
                    ? AppColors.darkInputFill
                    : AppColors.lightInputFill)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: task.isCompleted
              ? (isDark ? Colors.transparent : AppColors.lightChipSelectedBorder)
              : (isOverdue
                  ? AppColors.error.withAlpha(80)
                  : Colors.transparent),
        ),
      ),
      child: Row(
        children: [
          Icon(
            task.isCompleted
                ? Icons.check_circle_rounded
                : (isOverdue
                    ? Icons.warning_amber_rounded
                    : Icons.schedule_rounded),
            color: task.isCompleted
                ? (isDark
                    ? AppColors.chipSelectedText
                    : AppColors.lightChipSelectedText)
                : (isOverdue ? AppColors.error : AppColors.primary),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              task.isCompleted
                  ? 'This task has been completed'
                  : (isOverdue
                      ? 'This task is overdue!'
                      : 'This task is pending completion'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: task.isCompleted
                    ? (isDark
                        ? AppColors.chipSelectedText
                        : AppColors.lightChipSelectedText)
                    : (isOverdue
                        ? AppColors.error
                        : (isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
