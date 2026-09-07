import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/task_entity.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';
import '../bloc/task_state.dart';
import '../widgets/priority_badge_widget.dart';
import '../widgets/task_detail_description_card.dart';
import '../widgets/task_detail_dialogs.dart';
import '../widgets/task_detail_metadata_section.dart';
import '../widgets/task_detail_status_banner.dart';

class TaskDetailScreen extends StatelessWidget {
  final dynamic taskId;
  final TaskEntity? initialTask;

  const TaskDetailScreen({
    super.key,
    required this.taskId,
    this.initialTask,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        TaskEntity? task;
        try {
          task = state.allTasks.firstWhere(
            (t) => t.id.toString() == taskId.toString(),
          );
        } catch (_) {
          task = initialTask;
        }

        if (task == null) {
          return Scaffold(
            backgroundColor:
                isDark ? AppColors.darkBackground : AppColors.lightBackground,
            appBar: AppBar(title: const Text('Task Details')),
            body: const Center(
              child: Text('Task not found.'),
            ),
          );
        }

        final isOverdue =
            DateFormatter.isOverdue(task.dueDate, task.isCompleted);

        return Scaffold(
          backgroundColor:
              isDark ? AppColors.darkBackground : AppColors.lightBackground,
          appBar: AppBar(
            backgroundColor:
                isDark ? AppColors.darkBackground : AppColors.lightBackground,
            title: Text(
              'Task Details',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit Task',
                onPressed: () => context.push('/edit/${task!.id}', extra: task),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.error),
                tooltip: 'Delete Task',
                onPressed: () => TaskDetailDialogs.confirmDelete(context, task!),
              ),
              BlocBuilder<ThemeCubit, ThemeMode>(
                builder: (context, _) => IconButton(
                  tooltip:
                      isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                  icon: Icon(
                    isDark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  onPressed: () => context.read<ThemeCubit>().toggleTheme(),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TaskDetailStatusBanner(task: task, isOverdue: isOverdue),
                const SizedBox(height: 24),
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isDark
                            ? task.category.color.withValues(alpha: 0.2)
                            : task.category.backgroundColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(task.category.icon,
                              size: 14, color: task.category.color),
                          const SizedBox(width: 6),
                          Text(
                            task.category.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: task.category.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    PriorityBadgeWidget(priority: task.priority),
                  ],
                ),
                const SizedBox(height: 20),
                TaskDetailDescriptionCard(description: task.description),
                const SizedBox(height: 24),
                TaskDetailMetadataSection(task: task, isOverdue: isOverdue),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: task.isCompleted
                          ? (isDark
                              ? AppColors.darkInputFill
                              : AppColors.lightInputFill)
                          : AppColors.primary,
                      foregroundColor: task.isCompleted
                          ? (isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary)
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    icon: Icon(
                      task.isCompleted
                          ? Icons.replay_rounded
                          : Icons.check_circle_outline_rounded,
                    ),
                    label: Text(
                      task.isCompleted
                          ? 'Mark as Pending'
                          : 'Mark as Completed',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed: () {
                      context
                          .read<TaskBloc>()
                          .add(ToggleTaskCompletionEvent(task!.id));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            task.isCompleted
                                ? 'Task marked as pending'
                                : 'Task marked as completed!',
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}
